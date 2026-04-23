# feat: 재사용 가능한 미디어 상세 뷰어 구현

**GitHub Issue**: #6  
**Last Updated**: 2026-04-23

---

## Executive Summary

현재 앱에는 그리드 셀 탭 후 진입하는 상세 미디어 뷰어가 없습니다. 이번 작업의 목표는 갤러리 전용 사진 상세 화면이 아니라, 앱 어디서든 재사용할 수 있는 전체화면 미디어 뷰어를 구현하는 것입니다.

1차 범위는 `PhotoAsset` 기반 입력으로 사진과 동영상을 모두 표시할 수 있는 `MediaDetailFeature` / `MediaDetailView`를 만드는 것입니다. 사진은 pinch-to-zoom을 우선 지원하고, 동영상은 재생 중심으로 구현하되 추후 줌 확장이 가능하도록 상태/레이아웃 구조를 설계합니다. 첫 적용 화면은 `Gallery`와 `AlbumPhotoGrid`입니다.

---

## Current State Analysis

### 이미 존재하는 기반

| 파일 | 상태 | 비고 |
|------|------|------|
| `PHOU/Domain/Entity/PhotoAsset.swift` | ✅ 완성 | `mediaType`이 `.image`, `.video`, `.unknown` 을 이미 표현 |
| `PHOU/Data/Client/PhotoLibraryClient.swift` | ⚠️ 부분 준비 | `fetchAssetsInAlbum`은 mixed media 유지, `fetchPhotos`는 현재 `.image`만 fetch |
| `PHOU/Presentation/Components/PhotoThumbnailView.swift` | ✅ 완성 | asset id 기준 썸네일 로딩 가능 |
| `PHOU/Presentation/Gallery/GalleryFeature.swift` | ✅ 완성 | 권한 요청 및 전체 사진 목록 fetch |
| `PHOU/Presentation/Album/AlbumPhotoGridFeature.swift` | ✅ 완성 | 앨범 단위 mixed media 목록 fetch |

### 현재 한계

| 영역 | 현재 상태 | 영향 |
|------|-----------|------|
| 상세 미디어 화면 | ❌ 미구현 | 탭 후 확대 보기/재생 경험 없음 |
| 셀 탭 액션 | ❌ 미구현 | `GalleryView`, `AlbumPhotoGridView` 그리드 셀이 터치 반응 없음 |
| 갤러리 fetch 범위 | ⚠️ 이미지 전용 | 범용 미디어 뷰어 첫 진입점으로 쓰기엔 비디오 누락 |
| 고해상도 원본 로딩 | ❌ 미구현 | 썸네일만 있으므로 뷰어 품질/줌 품질 부족 |
| 동영상 재생 | ❌ 미구현 | `AVPlayer` 기반 재생/정지/라이프사이클 처리 필요 |

### 현재 구현 반영 상태

- `MediaDetailFeature` / `MediaDetailView` 초안 구현 완료
- `GalleryFeature`는 `fetchMedia()` 기반 mixed media fetch로 전환 완료
- `GalleryView`, `AlbumPhotoGridView`에서 동일한 full-screen 미디어 뷰어 연결 완료
- 사진 pinch-to-zoom 1차 구현 완료
- 동영상 `AVPlayer` 재생 1차 구현 완료
- 빌드 검증 완료
- 테스트 타깃은 아직 없어 reducer/unit test는 미구현

---

## Proposed Future State

### 화면 및 책임 구조

```text
GalleryView / AlbumPhotoGridView / 이후 다른 화면
└── 셀 탭
    └── MediaDetailFeature.State
        ├── items: [PhotoAsset]
        ├── currentIndex
        ├── zoom/photo loading state
        └── playback state (video only)
            └── MediaDetailView
                ├── 좌우 paging
                ├── 사진: 고해상도 표시 + pinch-to-zoom
                └── 동영상: 플레이어 표시 + 재생 제어
```

### 설계 방향

- Feature 이름은 `PhotoDetail`보다 범용적인 `MediaDetail`로 잡습니다.
- 입력은 특정 화면 전용 타입이 아니라 `[PhotoAsset] + selectedAssetID or selectedIndex` 형태로 받아, 갤러리/앨범/정리 플로우 어디서든 재사용 가능하게 만듭니다.
- 사진/동영상 분기는 `PhotoAsset.mediaType` 기준으로 처리합니다.
- 그리드 화면은 데이터 fetch 책임을 유지하고, 뷰어는 표시/탐색 책임만 갖도록 분리합니다.
- 1차 구현은 `GalleryFeature`와 `AlbumPhotoGridFeature`에 연결하되, 특정 Feature 전용 API는 피합니다.

---

## Implementation Phases

### Phase 1: 도메인/데이터 준비

- `GalleryFeature`가 비디오도 포함한 전체 미디어를 가져올지 결정하고, 필요하면 `PhotoLibraryClient`에 범용 fetch API를 추가합니다.
- 뷰어에서 필요한 메타데이터(예: 비디오 여부, 즐겨찾기 여부, 생성일)는 기존 `PhotoAsset`로 충분한지 확인합니다.
- 고해상도 이미지 로딩과 동영상 player item 생성 책임을 어디에 둘지 정합니다.

### Phase 2: MediaDetailFeature 상태 설계

- `items`, `currentIndex`, loading/error, dismiss/paging 액션을 정의합니다.
- 사진 줌 상태와 동영상 재생 상태를 한 Feature 내부에서 다루되, 뷰 단에서 분기 가능한 구조로 유지합니다.
- `@Presents` 또는 `sheet/fullScreenCover` 진입 방식을 결정합니다.

### Phase 3: MediaDetailView UI 구현

- 전체화면 레이아웃, dismiss affordance, 현재 index 기준 media 표시를 구현합니다.
- 사진은 고해상도 이미지와 pinch-to-zoom을 지원합니다.
- 동영상은 `AVPlayer` / `VideoPlayer` 기반 재생을 지원합니다.
- 좌우 스와이프 paging UX를 구현합니다.

### Phase 4: 첫 소비처 연결

- `GalleryView` 셀 탭 시 뷰어 진입을 연결합니다.
- `AlbumPhotoGridView` 셀 탭 시 동일 뷰어를 재사용하도록 연결합니다.
- 두 화면이 같은 입력 계약을 사용하도록 정리합니다.

### Phase 5: 검증 및 후속 정리

- 빌드/시뮬레이터 기준으로 사진 확대, 동영상 재생, paging, dismiss를 확인합니다.
- mixed media UX에서 남는 후속 항목(비디오 배지, 자동 재생 정책, iPad 레이아웃)을 별도 이슈로 분리할지 결정합니다.

### 현재 남은 후속 작업

- 시뮬레이터에서 실제 진입/스와이프/동영상 재생 수동 확인
- 필요 시 현재 페이지 표시와 제스처 충돌 UX 미세 조정
- 테스트 타깃 도입 여부 판단

---

## Architecture Decisions

### 1. 범용 입력 모델 유지

- 뷰어는 `GalleryFeature.State`나 `AlbumPhotoGridFeature.State`를 직접 참조하지 않습니다.
- `PhotoAsset` 배열과 선택 정보만 받아 재사용성을 높입니다.

### 2. 진입 방식은 full-screen 성격 우선

- 이 기능은 "상세 화면"보다 "미디어 몰입 뷰어"에 가깝습니다.
- `sheet`보다 `fullScreenCover` 또는 full-screen push가 더 자연스러울 가능성이 큽니다.
- 다만 현재 앱 네비게이션 구조와 TCA presentation 패턴에 맞춰 최종 결정합니다.

### 3. 사진/동영상 공통 pager + 타입별 콘텐츠 분리

- 상위 컨테이너는 paging, dismiss, chrome만 담당합니다.
- 실제 콘텐츠는 `ImageDetailContent` / `VideoDetailContent` 성격의 분리된 View로 나누는 편이 유지보수에 유리합니다.

### 4. Gallery fetch 범위 확장 가능성

- 현재 `fetchPhotos()`는 `.image` 전용입니다.
- 이 이슈의 범위를 엄밀히 지키려면 Gallery 첫 적용 시점에 전체 media fetch로 확장하거나, 별도 `fetchMedia()` API를 도입해야 합니다.
- 이 부분은 구현 초기에 결정해야 뷰어가 "전역 mixed media"라는 목표와 어긋나지 않습니다.

---

## Risks And Mitigations

| 리스크 | 가능성 | 대응 |
|--------|--------|------|
| `GalleryFeature`가 여전히 사진만 보여 mixed media 목표와 불일치 | 높음 | `PhotoLibraryClient` fetch API를 초기에 재정의 |
| 사진 줌 제스처와 paging 제스처 충돌 | 높음 | 기본 pager와 zoom 상태 전환 조건을 분리 |
| 동영상 player lifecycle 누수/중복 재생 | 중간 | 현재 페이지 변화 시 재생 정지 규칙 정의 |
| PhotoKit 원본 로딩 콜백 다중 호출 | 중간 | 기존 `PhotoThumbnailView`처럼 resume guard 유지 |
| iPad에서 full-screen UX가 과도하게 iPhone 중심 | 중간 | 초기 문서 단계부터 iPad 레이아웃 확인 항목 포함 |

---

## Success Criteria

- [ ] `MediaDetailFeature` / `MediaDetailView`가 사진과 동영상을 모두 처리함
- [ ] `GalleryView`와 `AlbumPhotoGridView`에서 같은 뷰어를 재사용함
- [ ] 사진 pinch-to-zoom이 동작함
- [ ] 동영상 재생이 정상 동작함
- [ ] 좌우 스와이프로 이전/다음 미디어 이동이 가능함
- [ ] Swift 6 strict concurrency 경고 없이 빌드됨
- [ ] 진입/종료 및 mixed media 전환이 시뮬레이터에서 확인됨

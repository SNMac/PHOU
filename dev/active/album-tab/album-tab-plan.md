# feat: 앨범 탭 구현 — 시스템/사용자 앨범 목록 및 그리드 뷰

**GitHub Issue**: #5  
**Last Updated**: 2026-04-22

---

## Executive Summary

현재 앨범 탭은 `ContentUnavailableView` stub 상태입니다. PhotoKit을 활용하여 시스템 앨범(스마트 앨범)과 사용자 앨범을 섹션별로 나열하고, 앨범 선택 시 해당 앨범의 사진 그리드로 진입하는 기능을 구현합니다.

---

## Current State Analysis

### 이미 완성된 부분

| 파일 | 상태 | 비고 |
|------|------|------|
| `Domain/Entity/AlbumGroup.swift` | ✅ 완성 | `id`, `title`, `assetCount`, `albumType` 정의됨 |
| `Data/Client/PhotoLibraryClient.swift` | ✅ 완성 | `fetchAlbums` liveValue 및 previewValue 구현됨 |

### 미구현 부분

| 파일 | 상태 | 비고 |
|------|------|------|
| `Presentation/Album/AlbumFeature.swift` | ❌ Stub | `onAppear` 액션만 있고 fetch 로직 없음 |
| `Presentation/Album/AlbumView.swift` | ❌ Stub | `ContentUnavailableView`만 표시 |
| `Presentation/Album/AlbumPhotoGridFeature.swift` | ❌ 미존재 | 앨범 내 사진 그리드 Feature |
| `Presentation/Album/AlbumPhotoGridView.swift` | ❌ 미존재 | 앨범 내 사진 그리드 View |

---

## Proposed Future State

### 화면 구조

```
AlbumView (TabView의 앨범 탭)
├── NavigationStack
│   ├── List (섹션 구분)
│   │   ├── Section("시스템 앨범")
│   │   │   └── AlbumRowView × N  ← 커버 이미지 + 앨범명 + 사진 수
│   │   └── Section("나의 앨범")
│   │       └── AlbumRowView × N
│   └── NavigationLink → AlbumPhotoGridView
│       └── 선택된 앨범의 사진 LazyVGrid
```

### TCA 상태 흐름

```
AlbumFeature
├── State: albums([AlbumGroup]), isLoading, errorMessage
└── Action
    ├── view.onAppear → fetchAlbums()
    ├── internal.albumsResponse(.success) → albums 갱신
    ├── internal.albumsResponse(.failure) → errorMessage 갱신
    └── view.albumTapped(AlbumGroup) → AlbumPhotoGridFeature 진입
```

---

## Implementation Phases

### Phase 1: AlbumFeature — 앨범 목록 fetch 로직
`AlbumFeature.swift`에 앨범 목록 fetch 로직을 구현합니다. GalleryFeature 패턴을 참고합니다.

### Phase 2: AlbumView — 앨범 목록 UI
`AlbumView.swift`에 섹션별 List UI를 구현합니다. 커버 이미지는 `PhotoThumbnailView`를 재사용합니다.

### Phase 3: AlbumPhotoGrid — 앨범 내 사진 그리드
선택된 앨범의 사진 그리드를 표시하는 새 Feature와 View를 구현합니다.

### Phase 4: 네비게이션 연결
`AlbumFeature`에 `AlbumPhotoGridFeature`를 Path/StackState로 연결합니다.

---

## Detailed Tasks

작업 목록은 `album-tab-tasks.md` 참고.

---

## Architecture Decisions

### AlbumPhotoGrid 구현 방식: 별도 Feature 신규 작성
- GalleryFeature는 `PHAsset.fetchAssets(with: .image)` 로 전체 사진을 가져오는 구조
- AlbumPhotoGrid는 `PHAsset.fetchAssets(in: collection)` 으로 특정 앨범 기준 fetch 필요
- 재사용보다 명확한 책임 분리가 유지보수에 유리하므로 별도 Feature를 작성합니다

### 네비게이션 방식: NavigationStack + .navigationDestination
- TCA 1.0+ 권장 패턴인 `StackState`/`StackAction` 또는 `PresentationState` 활용
- 앨범 탭은 단일 depth 네비게이션이므로 `PresentationState<AlbumPhotoGridFeature.State>` 사용

### 커버 이미지 로딩
- `PhotoThumbnailView(id:)` 컴포넌트를 그대로 재사용
- 앨범의 첫 번째 에셋 ID를 `AlbumGroup`에 `coverAssetId: String?`로 추가 필요

---

## Risk Assessment

| 리스크 | 가능성 | 대응 |
|--------|--------|------|
| 앨범이 빈 경우 커버 이미지 없음 | 높음 | `coverAssetId == nil`이면 placeholder 아이콘 표시 |
| PHAuthorizationStatus 미확인 상태로 fetch | 중간 | GalleryFeature와 동일하게 권한 체크 후 fetch |
| 스마트 앨범 수가 많아 리스트 길어짐 | 낮음 | 빈 앨범(assetCount == 0) 필터링 옵션 고려 |

---

## Success Metrics

- [ ] 앨범 탭 진입 시 시스템 앨범 / 나의 앨범 섹션이 표시됨
- [ ] 각 앨범 셀에 커버 이미지, 앨범명, 사진 수 표시됨
- [ ] 앨범 탭 시 해당 앨범의 사진 그리드로 이동됨
- [ ] 권한 없는 상태에서 적절한 에러 처리 (GalleryView와 동일 패턴)
- [ ] 빈 앨범 커버 이미지 graceful 처리
- [ ] Swift 6 strict concurrency 경고 없음

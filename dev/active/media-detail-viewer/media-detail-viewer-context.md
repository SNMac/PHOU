# Media Detail Viewer — 컨텍스트 및 핵심 파일

**GitHub Issue**: #6  
**Last Updated**: 2026-04-23

---

## 관련 파일 경로

| 영역 | 파일 |
|------|------|
| 미디어 모델 | `PHOU/Domain/Entity/PhotoAsset.swift` |
| PhotoKit 의존성 | `PHOU/Data/Client/PhotoLibraryClient.swift` |
| 갤러리 Feature | `PHOU/Presentation/Gallery/GalleryFeature.swift` |
| 갤러리 View | `PHOU/Presentation/Gallery/GalleryView.swift` |
| 앨범 상세 Feature | `PHOU/Presentation/Album/AlbumPhotoGridFeature.swift` |
| 앨범 상세 View | `PHOU/Presentation/Album/AlbumPhotoGridView.swift` |
| 썸네일 컴포넌트 | `PHOU/Presentation/Components/PhotoThumbnailView.swift` |
| 신규 후보 | `PHOU/Presentation/MediaDetail/MediaDetailFeature.swift` |
| 신규 후보 | `PHOU/Presentation/MediaDetail/MediaDetailView.swift` |

---

## 현재 코드에서 확인된 사실

### 1. `PhotoAsset`은 이미 mixed media를 표현할 수 있음

`PhotoAsset.MediaType`은 아래 3가지를 가집니다.

- `.image`
- `.video`
- `.unknown`

즉, 도메인 모델 자체는 사진/동영상 통합 뷰어를 받을 준비가 되어 있습니다.

### 2. `AlbumPhotoGridFeature`는 이미 mixed media fetch를 유지함

`PhotoLibraryClient.fetchAssetsInAlbum(_:)` 는 `PHAsset.fetchAssets(in:collection, ...)` 결과를 순회하면서 `asset.mediaType`을 `PhotoAsset.MediaType`으로 변환합니다.

즉, 앨범 상세는 이미 비디오를 포함할 수 있고, 뷰어의 첫 재사용 대상로 적합합니다.

### 3. `GalleryFeature`는 현재 이미지 전용

`PhotoLibraryClient.fetchPhotos()` 는 현재:

```swift
let result = PHAsset.fetchAssets(with: .image, options: options)
```

형태라서 비디오를 가져오지 않습니다.

이 이슈의 목표가 "앱 전역 재사용 가능한 사진/동영상 뷰어"라면, `Gallery` 쪽 진입 데이터도 mixed media 목표와 맞추는지 초기에 정해야 합니다.

### 4. 그리드 셀은 아직 탭 액션이 없음

`GalleryView`, `AlbumPhotoGridView` 모두 `LazyVGrid` 내부에서 `PhotoThumbnailView`를 직접 `overlay`하고 있으며, `Button` 또는 탭 gesture가 없습니다.

즉, 뷰어 연결 작업은 상태 추가뿐 아니라 셀 hit target 설계도 포함합니다.

### 5. 썸네일 로딩에는 이미 PhotoKit async 래핑 패턴이 있음

`PhotoThumbnailView`는 `PHImageManager.default().requestImage(...)` + `withCheckedContinuation` + `resumed` 플래그 패턴을 사용합니다.

고해상도 원본 이미지 로딩 구현 시 같은 패턴을 재사용해야 Swift 6 / PhotoKit 콜백 다중 호출 문제를 안전하게 피할 수 있습니다.

---

## 아키텍처 메모

### TCA 패턴

- Reducer는 `view` / `internal` 액션 분리를 유지하는 편입니다.
- Presentation 상태는 `@Presents`를 사용하는 것이 이 프로젝트 기준 안전합니다.
- `$store.scope(...)`를 쓰는 View는 `@Bindable var store` 선언이 필요합니다.

### SwiftUI / PhotoKit 제약

- 정사각형 그리드 셀은 `Color.clear.aspectRatio(1, contentMode: .fill).overlay { ... }.clipped()` 패턴을 유지합니다.
- `@preconcurrency import Photos` 패턴은 의도적이며, 새 PhotoKit 접근 코드에도 유지하는 편이 좋습니다.
- `PHImageRequestOptions.isSynchronous = false` 사용 시 continuation 이중 resume 방지가 필요합니다.
- `.cornerRadius(_:)` 대신 `.clipShape(RoundedRectangle(cornerRadius:))` 사용 규칙을 유지합니다.

---

## 구현 결정 초안

### 1. 신규 폴더 후보

`PHOU/Presentation/MediaDetail/`

이유:

- `Gallery`, `Album` 어디에도 종속되지 않음
- 이후 정리 플로우나 검색 결과에서도 재사용 가능
- 범용 Feature라는 의도가 폴더 이름에서 바로 드러남

### 2. 상태 입력 계약 후보

후보 A:

```swift
State(items: [PhotoAsset], currentIndex: Int)
```

후보 B:

```swift
State(items: IdentifiedArrayOf<PhotoAsset>, selectedID: PhotoAsset.ID)
```

현재 코드베이스 복잡도를 고려하면 1차는 후보 A가 단순합니다. 다만 선택 ID 기반 복원성이 필요하면 B가 더 안정적입니다.

### 3. 소비처 연결 방식

- `GalleryFeature.State`에 `@Presents var mediaDetail: MediaDetailFeature.State?`
- `AlbumPhotoGridFeature.State`에도 같은 presentation 상태 추가

이렇게 하면 동일한 뷰어를 서로 다른 화면에서 독립적으로 띄울 수 있습니다.

### 4. 동영상 UX 범위

1차 범위:

- 동영상 재생 가능
- 좌우 paging 내에서 정상 표시
- 현재 페이지 이탈 시 정지

후속 범위:

- pinch-to-zoom on video
- 재생 속도, 음소거, 스크러빙 고급 UX
- 비디오 길이 오버레이/배지

---

## 오픈 질문

- `GalleryFeature`를 mixed media로 확장할지, 아니면 이 이슈에서는 뷰어 자체 구현과 앨범 쪽 연결을 우선할지
- 전체화면 진입을 `fullScreenCover`로 할지, push 내비게이션으로 할지
- 뷰어 내부 크롬을 최소화할지, 상단 dismiss + 하단 메타데이터까지 포함할지

---

## 다음 즉시 작업

1. `GalleryFeature`의 fetch API를 mixed media 목표에 맞게 바꿀지 결정
2. `MediaDetailFeature.State` 입력 계약 확정
3. presentation 방식(`@Presents` + full-screen / push) 결정
4. 신규 `Presentation/MediaDetail` 파일 생성 후 최소 동작 뷰어부터 연결

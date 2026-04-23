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

### 3. `GalleryFeature`는 이제 mixed media fetch로 전환됨

초기 문서 시점에는 `fetchPhotos()`가 이미지 전용이라 갤러리 쪽이 mixed media 목표와 어긋나는 상태였음.

현재는 `PhotoLibraryClient.fetchMedia()`가 추가되었고, `GalleryFeature`가 이를 사용하도록 전환되어 갤러리도 사진/동영상 혼합 자산을 기준으로 뷰어를 열 수 있음.

### 4. 그리드 셀은 현재 탭 액션 및 비디오 배지를 가짐

- `GalleryView`, `AlbumPhotoGridView` 모두 셀 전체를 `Button`으로 감싸고 `mediaTapped` 액션을 보냄
- 비디오 셀에는 우하단 `video.fill` 배지를 표시
- presentation은 두 화면 모두 동일하게 `fullScreenCover(item: $store.scope(...))` 기반

### 5. 썸네일 로딩에는 이미 PhotoKit async 래핑 패턴이 있음

`PhotoThumbnailView`는 `PHImageManager.default().requestImage(...)` + `withCheckedContinuation` + `resumed` 플래그 패턴을 사용합니다.

고해상도 원본 이미지 로딩 구현 시 같은 패턴을 재사용해야 Swift 6 / PhotoKit 콜백 다중 호출 문제를 안전하게 피할 수 있습니다.

### 6. 구현 반영 후 현재 상태

- `PHOU/Presentation/MediaDetail/MediaDetailFeature.swift` 신규 생성
- `PHOU/Presentation/MediaDetail/MediaDetailView.swift` 신규 생성
- `GalleryFeature`에 `@Presents var mediaDetail` 및 `mediaTapped` 액션 추가
- `AlbumPhotoGridFeature`에 같은 presentation 연결 추가
- `GalleryView`, `AlbumPhotoGridView`는 셀 탭 시 동일 뷰어를 띄움
- 그리드 셀의 비디오에는 우하단 `video.fill` 배지 표시
- `PhotoLibraryClient.fetchMedia()` 추가로 갤러리 전체가 mixed media fetch를 사용
- `MediaDetailView`는 최근 수정으로 사진 정렬/zoom/pan, inactive video pause, 썸네일 품질을 추가 보정
- iOS 18 기준으로 `matchedTransitionSource` + zoom transition 기반 상세 진입을 적용하는 방향으로 전환
- `GalleryView`, `AlbumPhotoGridView`는 핀치 제스처로 2~6열 범위에서 동적으로 열 수를 변경 가능
- `PhotoThumbnailView`는 실제 셀 크기를 받아 그 크기에 맞는 썸네일을 요청하고, `PHAsset` 재조회 비용을 줄이기 위해 간단한 asset cache를 둠
- 동영상은 현재 브랜치에서 시스템 playback controls를 숨겨 상세 뷰 chrome과 겹치지 않게만 정리함

즉, 현재 구현은 "재사용 가능한 사진/동영상 통합 뷰어"의 첫 버전까지는 도달해 있습니다.

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
- iOS 18 타깃에서는 `matchedTransitionSource`와 zoom transition을 `fullScreenCover` 진입에도 활용할 수 있습니다. 근거: WWDC24 “Enhance your UI animations and transitions”에서 zoom transition이 navigation과 presentation 모두에 동작한다고 설명.

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

현재 구현 메모:

- `MediaDetailView`는 `TabView` paging 기반
- 사진은 pure SwiftUI `MagnificationGesture`를 버리고 `UIScrollView` 기반 `ZoomableImageView`로 전환
- 이 변경으로 pinch 지점 기준 확대와 확대 상태의 내부 pan을 시스템 scroll/zoom 동작에 맡김
- 동영상은 `requestAVAsset` + `VideoPlayer` 조합에서 `requestPlayerItem(forVideo:)` + `AVPlayerViewController` 래퍼로 변경
- inactive page가 되면 `onChange(of: isActive)`에서 pause 하도록 보정
- 현재 세션에서 사진 initial fit 계산을 width 기준 고정에서 container aspect-fit 계산으로 바꿔 세로 중앙 정렬을 보정
- 현재 세션에서 `AVPlayerViewController.showsPlaybackControls = false`로 바꿔 상세 뷰 상단 chrome과 겹치지 않게 정리
- 썸네일은 `PHCachingImageManager` 사용, `onDisappear` cancel 유지
- 한때 성능 보정을 위해 `fastFormat`으로 낮췄다가 화질 저하가 커서 현재는 `highQualityFormat` + `exact`로 복구
- 현재 세션에서 썸네일 요청 크기를 `UIScreen.main.bounds.width / 3` 고정값 대신 실제 셀 크기 기반으로 변경
- 현재 세션에서 local identifier 기준 `PHAsset.fetchAssets(...)` 반복 비용을 줄이기 위해 `NSCache<NSString, PHAsset>` 기반의 간단한 asset cache를 추가
- 갤러리/앨범 그리드는 핀치 제스처로 열 수를 2~6 범위에서 동적으로 변경하도록 보정
- iOS 18 상세 전환은 각 셀에 `matchedTransitionSource(id: asset.id, in: namespace)`를 주고, 상세 뷰는 현재 `currentIndex`의 asset id로 zoom transition source를 매칭

### 5. 이번 세션에서 실제로 수정된 파일

- `PHOU/Presentation/MediaDetail/MediaDetailView.swift`
  - 사진 initial fit 계산을 aspect-fit 기준으로 보정해 Y축 중앙 정렬 수정
  - `UIScrollView` 기반 zoom/pan 도입
  - inactive video pause 로직 추가
  - 플레이어 로딩 경로를 `requestPlayerItem(forVideo:)`로 교체
  - iOS 18 zoom transition 적용
  - 시스템 playback controls 비활성화
- `PHOU/Presentation/Components/PhotoThumbnailView.swift`
  - caching/cancel 유지
  - 썸네일 화질 복구
  - 실제 셀 크기 기반 요청
  - `PHAsset` cache 추가
- `PHOU/Presentation/Gallery/GalleryView.swift`
  - zoom transition source 연결
  - 핀치 기반 열 수 조절
  - 실제 셀 크기 전달
- `PHOU/Presentation/Album/AlbumPhotoGridView.swift`
  - zoom transition source 연결
  - 핀치 기반 열 수 조절
  - 실제 셀 크기 전달
- `PHOU/Presentation/Album/AlbumView.swift`
  - 앨범 커버 썸네일도 변경된 `PhotoThumbnailView` 시그니처에 맞춰 실제 크기 전달
- `dev/active/media-detail-viewer/custom-video-player-issue.md`
  - 커스텀 비디오 플레이어 후속 작업용 이슈 초안 작성
- `dev/active/media-detail-viewer/media-detail-viewer-tasks.md`
  - 진행 상태 메모 및 검증 현황 반영

---

## 오픈 질문

- 현재 숨겨 둔 시스템 playback controls 대신 어떤 커스텀 컨트롤 레이아웃을 채택할지
- 핀치 기반 열 수 변경이 회전/iPad/split view에서도 충분히 자연스러운지
- 썸네일 preheat(`startCachingImages`)가 실제 체감 성능 개선에 얼마나 기여하는지 profiling이 필요한지

---

## 다음 즉시 작업

1. 시뮬레이터에서 사진 세로 중앙 정렬, zoom transition, 핀치 열 수 변경 수동 검증
2. 동영상 상세에서 현재 임시 상태(controls hidden)가 제품적으로 허용 가능한지 확인
3. 커스텀 비디오 플레이어 이슈를 기준으로 후속 범위 분리
4. 테스트 타깃 추가 여부 결정

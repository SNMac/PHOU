# Media Detail Viewer — 컨텍스트 및 핵심 파일

**GitHub Issue**: #6  
**Last Updated**: 2026-04-30

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
| 미디어 상세 Feature | `PHOU/Presentation/MediaDetail/MediaDetailFeature.swift` |
| 미디어 상세 View | `PHOU/Presentation/MediaDetail/MediaDetailView.swift` |
| 미디어 상세 모델/포맷 | `PHOU/Presentation/MediaDetail/MediaDetailModels.swift` |
| 미디어 상세 asset loader | `PHOU/Presentation/MediaDetail/MediaDetailAssetLoader.swift` |
| 미디어 상세 페이지 뷰 | `PHOU/Presentation/MediaDetail/MediaDetailPages.swift` |
| 미디어 상세 패널/레이아웃 | `PHOU/Presentation/MediaDetail/MediaDetailPanels.swift` |
| 미디어 상세 UIKit bridge | `PHOU/Presentation/MediaDetail/MediaDetailUIKit.swift` |
| 미디어 상세 PhotoKit bridge | `PHOU/Presentation/MediaDetail/MediaDetailPhotoKitBridge.swift` |
| 미디어 상세 공유 시트 | `PHOU/Presentation/MediaDetail/MediaDetailShareSheet.swift` |

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
- 다만 user report 기준 최초 진입 직후 사진의 Y축 중앙 정렬은 아직 완전히 해결되지 않았고, 한 번 확대/축소 후에야 맞춰지는 재현이 남아 있음
- iOS 18 기준으로 `matchedTransitionSource` + zoom transition 기반 상세 진입을 적용하는 방향으로 전환
- `GalleryView`, `AlbumPhotoGridView`는 핀치 제스처로 2~6열 범위에서 동적으로 열 수를 변경 가능
- `PhotoThumbnailView`는 실제 셀 크기를 받아 그 크기에 맞는 썸네일을 요청하고, `PHAsset` 재조회 비용을 줄이기 위해 간단한 asset cache를 둠
- 동영상은 현재 브랜치에서 시스템 playback controls를 숨겨 상세 뷰 chrome과 겹치지 않게만 정리함
- 런타임 경고 `SWIFT TASK CONTINUATION MISUSE: loadThumbnail() leaked its continuation` 의 직접 원인은 취소된 PhotoKit request가 callback에서 return만 하고 continuation을 끝내지 않던 경로로 확인됨
- 상세 뷰 초기 진입/페이지 전환 지연의 주요 원인은 `TabView` 안 모든 페이지가 동시에 무거운 로딩을 시작하던 구조로 판단하고, 현재/인접 페이지 우선 로딩 + 캐시 재사용으로 방향을 바꿈
- 상세 뷰 chrome은 상단 toolbar / 하단 `safeAreaInset` / overlay chrome / system toolbar를 거쳐 왔고, 현재는 `ToolbarItem` 기반 toolbar 구성을 유지하면서 inline info panel과 함께 다듬는 중임
- 상단 중앙 타이틀은 위치 유무에 따라 `위치 / 날짜+시간` 또는 `날짜 / 시간` 2줄 구조를 사용함
- 위치 문자열은 `administrativeArea/locality/subLocality/thoroughfare/name` 조합 기반으로 확장되어 `수원시 - 매산로3가` 같은 표기를 시도함
- 다만 상단 타이틀 데이터는 현재 summary metadata 비동기 로딩 결과에 의존해, 상세 진입 직후 날짜만 먼저 보였다가 잠시 뒤 위치가 붙으면서 타이틀 폭과 줄 배치가 미세하게 흔들리는 체감 이슈가 있음
- 상세정보는 더 이상 `sheet(item:)` 기반 modal이 아니라, 위로 스와이프하거나 info 버튼으로 여는 inline panel 구조로 재설계 중
- 파일명은 `PHAssetResource.originalFilename`, 소속 앨범은 `PHAssetCollection.fetchAssetCollectionsContaining`, 촬영 기기는 사진 자산의 TIFF metadata 추출을 사용함
- 편집 버튼은 현재 안내 alert를 유지함. crop 또는 다른 실제 편집 기능은 GitHub Issue `#12` `미디어 상세 뷰 사진 편집 기능 구현`으로 분리됨
- 배경은 기본 `systemBackground`이고 단일 탭으로 black immersive background를 토글 가능
- 사진은 `UIScrollView` 레벨의 double-tap zoom을 추가
- 가장 최근 리팩토링 세션에서 `MediaDetailView.swift` / `MediaDetailSupport.swift` 책임 분리를 실제로 수행함
- 최신 사용자 확인 기준으로 리팩토링 후 빌드와 실행은 모두 정상 동작함
- 최신 커밋 `5d753c6`에서 iOS 26 미만 하단 toolbar 배치를 `ToolbarItem(.bottomBar)` + `ToolbarItemGroup(.status)` + `ToolbarItem(.bottomBar)` 형태로 다시 조정했고, 사용자 확인 기준 의도한 레이아웃이 맞음
- 현재 `MediaDetailView`의 상세정보 표시는 `showsDetailsPanel` 불리언과 `MediaDetailsPanel` overlay 조합으로 구현되어 있음
- 이 구조는 기술적으로는 modal sheet가 아니지만, 화면 하단에 별도 레이어가 올라오는 인상이 강해서 iOS 기본 사진 앱의 "같은 화면 안에서 아래 내용이 이어지는" 감각과는 차이가 남
- 2026-04-24 후속 구현에서 상단 title은 더 이상 generic placeholder에서 시작하지 않고, `PHAsset.location` 존재 여부를 즉시 반영한 provisional summary로 시작하도록 바뀜
- 즉, 위치가 있는 자산은 첫 진입부터 `위치 확인 중 / 날짜+시간` 2줄 구조를 유지하고, 이후 실제 위치 문자열로 치환되어 title 재배치를 줄이는 방향으로 보정됨
- 같은 날 상세 정보 표현을 `ScrollView + LazyVStack + scrollPosition` 기반 integrated scroll surface로 1차 전환해 봤지만, 사용자 피드백 기준으로 Photos 레퍼런스의 체감과 달랐고 세로 사진 Y축 중앙 정렬도 흐트러지는 부작용이 확인됨
- 이후 최신 커밋 `9f9bc5c`에서 해당 시도를 되돌리고, 현재는 `showsDetailsPanel` + `MediaDetailsPanel` overlay 구조를 유지하되 "시트가 올라오면서 사진도 함께 위로 lift 되는" 방향을 기준선으로 삼고 있음
- 즉, 현재 상세 정보 UI는 엄밀한 modal sheet도, 스크롤로 이어지는 content layer도 아니고, toolbar 위계는 유지하면서 Photos 앱처럼 붙어 올라오는 인상을 내는 custom bottom presentation에 더 가까움
- 사용자 요청에 따라 상세 정보 내부의 `캡션 추가` UI는 제거된 상태임
- 가장 최근 후속 수정에서 상세정보 시트의 grabber는 제거했고, 상단 radius/card 인상도 줄여 현재 외형을 잠정 기준선으로 둠
- 같은 후속 수정에서 panel open 상태로 좌우 paging 해도 panel을 닫지 않고, `currentAssetID` 변경 시 provisional summary를 즉시 교체한 뒤 새 asset metadata를 이어서 로드하도록 보정함
- 성능 로그 `Missing prefetched properties for PHAssetOriginalMetadataProperties ... Fetching on demand on the main queue, which may degrade performance.` 도 아직 재현됨
- 최신 시도에서 `resolvedDeviceText`를 detached utility task + cache 경로로 옮겼지만, 해당 경고는 여전히 남아 있어 단순 호출 스레드 문제만은 아닐 가능성이 큼
- 따라서 다음 세션에서는 "기기명 추출 시점/경로"뿐 아니라 `PHAsset` fetch 시 prefetch 가능한 속성, `requestImageDataAndOrientation` 자체의 metadata fault 유발 여부를 같이 봐야 함
- 이번 세션에서는 root cause 후보를 `requestImageDataAndOrientation` 경로로 더 좁혔고, 상세 패널의 촬영 기기명 추출을 `PHAssetResourceManager.requestData` + incremental `CGImageSource` probe 방식으로 교체함
- 새 경로는 TIFF/EXIF 속성이 확인되는 즉시 data request를 cancel 하도록 설계해, 원본 이미지 전체 decode 및 `PHAssetOriginalMetadataProperties` fault 가능성을 줄이는 방향임
- 후속 컴파일 수정으로 `CGImageSourceCreateIncremental(nil)` 결과를 optional binding 하던 두 경로를 제거했고, 현재 구현은 incremental source를 non-optional로 직접 사용하는 상태임
- 현재 MediaDetail 핵심 파일 길이:
  - `PHOU/Presentation/MediaDetail/MediaDetailView.swift`: 456줄
  - `PHOU/Presentation/MediaDetail/MediaDetailAssetLoader.swift`: 340줄
  - `PHOU/Presentation/MediaDetail/MediaDetailPhotoKitBridge.swift`: 260줄
  - `PHOU/Presentation/MediaDetail/MediaDetailUIKit.swift`: 243줄
- 다만 이번 후속 구현은 현재 세션에서 code change까지만 반영됐고, compile/runtime verification은 아직 남아 있음
- model harness(`MediaAssetDetails.provisionalTitleTexts`)는 red-green 확인했지만, 최신 unrestricted `xcodebuild -project PHOU.xcodeproj -target PHOU build`는 SPM 의존성 쪽 `ConcurrencyExtras` / `IssueReporting` 모듈 해석 실패로 멈춤
- 다음 단계의 핵심은 구조 분리 자체보다 남은 compile/runtime 검증, toolbar 경고 재현 여부, scroll gesture 체감 확인임

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
- 취소/에러 경로도 반드시 `resume(returning: nil)` 되도록 해야 Swift runtime continuation misuse 경고를 피할 수 있습니다.
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
- 이전 세션에서 상세 뷰 로딩/공유/메타데이터 처리를 `MediaDetailSupport.swift`로 모아두었고, 이번 세션에서 그 책임을 역할별 파일로 다시 분리함
- 상세 뷰는 현재/인접 사진 페이지만 우선 로드하고, 비디오는 active page에서만 플레이어를 준비하도록 바꿔 initial presentation/swipe 비용을 낮춤
- 초기 사진 Y축 정렬 문제는 `UIScrollView.contentInsetAdjustmentBehavior = .never`, layout 후 centering, background-aware zoom view 갱신으로 한 차례 보정했지만 user report 기준 최초 진입 재현이 남아 있음
- 공유는 `UIActivityViewController` sheet로 연결했고, 편집 버튼은 공개 시스템 사진 편집 API 부재를 안내하는 alert로 처리
- 이번 세션에서는 `LayoutAwareScrollView`를 추가해 layout 시점마다 centering을 다시 적용하도록 보정함
- 이번 세션에서는 뷰어 루트에 `NavigationStack`은 유지하되, 실제 상단/하단 chrome은 overlay로 분리해 fade/immersive/inline panel과 함께 움직이도록 다시 조정함
- 이번 세션에서는 `MediaDetailAssetLoader.details(for:)`가 제목용 날짜/시간, 상세 위치, 파일명, 촬영 기기, 앨범 이름을 함께 계산하도록 확장됨
- 이번 세션에서는 상세 정보 버튼이 placeholder/실데이터 두 번 세팅 때문에 modal이 다시 뜨는 문제를 확인했고, `sheet`를 없애고 inline panel을 단일 source of truth로 바꾸는 방향으로 수정함
- 이번 세션에서는 immersive 탭 전환이 배경색만 바꾸는 수준이 아니라 chrome opacity와 viewport 크기를 함께 전환하도록 수정함
- 이번 세션에서는 위로 스와이프 시 사진이 위로 lift 되면서 정보 패널이 올라오는 reference UX의 첫 버전을 추가함
- 이번 세션에서는 사용자 요청에 따라 iOS 26 기본 사진 앱의 Liquid Glass 인상을 맞추기 위해 `MediaDetailView`의 상단/하단 chrome을 overlay에서 `NavigationStack + ToolbarItem/ToolbarItemGroup + ToolbarSpacer` 기반 system toolbar로 다시 전환함
- 이번 세션에서는 `ToolbarItem(placement: .principal)`로 2줄 title을 옮기고, iOS 26 이상에서 `.sharedBackgroundVisibility(.hidden)`를 적용해 title item이 별도 glass grouping을 가지도록 조정함
- 이번 세션에서는 하단 액션을 `bottomBar` placement에 share / favorite+info+crop group / delete로 재배치하고, iOS 26에서는 `ToolbarSpacer(.flexible)`로 그룹 간 분리를 시도함
- 이번 세션에서는 iPhone 13 mini 레이아웃 문제를 줄이기 위해 `MediaDetailLayout`의 chrome reserve를 낮추고, `ZoomableImageView`가 requested viewport 대신 실제 `UIScrollView.bounds`를 기준으로 reset/centering 하도록 보정함
- 하지만 user report 기준으로 레이아웃 문제는 여전히 해결되지 않았고, runtime 중 `Adding 'UIKitToolbar' as a subview of UIHostingController.view is not supported...` 경고가 새로 관찰됨
- runtime 중 함께 관찰된 `Error returned from daemon: Error Domain=com.apple.accounts Code=7 "(null)"` 및 `CMPhotoJFIFUtilities err=-17102` 로그는 현재 코드 변경과 직접 연관인지 불명확함
- 가장 최근 세션에서는 세로 사진이 normal 모드에서 immersive보다 더 작게 보이는 문제를 줄이기 위해 `MediaDetailLayout.viewportSize`가 toolbar reserve를 빼지 않고 전체 container 크기를 쓰도록 다시 단순화함
- 가장 최근 세션에서는 사용자의 디자인 의도에 맞춰 하단 액션도 다시 `ToolbarItem` 기반으로 유지하고, iOS 18에서는 `bottomBar` + `status` placement 조합으로 `share+favorite / info / crop+delete` 3구역에 가깝게 재배치함
- 가장 최근 세션에서는 사용자가 iOS 26 미만 배치가 의도대로 맞았다고 확인해, 하단 toolbar 레이아웃 자체는 현재 기준선으로 봐도 됨
- 가장 최근 세션에서는 favorite 버튼의 기본 검정 tint를 제거하고, non-favorite는 accent color, favorite는 pink tint가 되도록 보정함
- 가장 최근 세션에서는 동영상이 과하게 확대되어 보이는 문제를 줄이기 위해 `AVPlayerViewController`를 제거하고, `AVPlayerLayer.videoGravity = .resizeAspect`를 쓰는 경량 player view로 교체함
- 가장 최근 세션에서는 실기기에서 라이브러리 규모가 큰 경우 상세 뷰 진입/전환이 느려질 수 있다는 가설 하에, `MediaDetailFeature.State`의 `Equatable` 비교를 전체 `items` 배열 대신 현재 index/current asset snapshot 중심으로 줄이는 최적화를 추가함
- 가장 최근 세션에서는 `TabView` 콘텐츠 전체를 항상 `ignoresSafeArea()` 하도록 바꿔, normal/immersive 전환이 미디어 크기를 바꾸지 않고 배경/UI visibility만 바꾸도록 정리함
- 가장 최근 세션에서는 위 리팩토링 방향을 실제 코드로 반영함:
  - `MediaDetailView.swift`는 화면 조립과 state orchestration 중심으로 축소
  - page content는 `MediaDetailPages.swift`, 패널/레이아웃은 `MediaDetailPanels.swift`, UIKit bridge는 `MediaDetailUIKit.swift`로 이동
  - 기존 `MediaDetailSupport.swift`는 제거하고 loader/models/PhotoKit bridge/share sheet로 역할별 분리
  - UIKit 감사는 “무조건 제거”가 아니라 “SwiftUI가 더 단순한 경우만 전환” 원칙을 유지해 `ZoomableImageView`, `PlayerLayerView`는 남기고 `ShareSheetView`만 단순 wrapper 후보로 분류

### 5. 이번 사용자 피드백으로 scope가 다시 바뀜

- 상세 뷰 사진은 최초 진입 시점부터 Y축 중앙 정렬이 맞아야 함
- 상세정보는 완전한 "스크롤 연장면"보다는, 아래에서 시트처럼 올라오되 사진도 그에 맞춰 함께 위로 이동하는 형태가 레퍼런스 체감에 더 가까움
- info 버튼과 upward swipe는 동일한 panel reveal 동작으로 수렴해야 함
- 상단 toolbar가 정보 위에 남아 보이는 reference UX는 유지하되, 구현 방식은 content layer scroll보다 custom bottom presentation 쪽이 더 적합하다는 쪽으로 최근 판단이 바뀜
- 따라서 다음 구현의 핵심은 `MediaDetailView`의 overlay panel 구조를 버리는 것이 아니라, 시트와 사진의 동반 이동감, dismiss 감도, 레이아웃 안정성을 더 Photos답게 다듬는 것임
- 성능 이유로 늦춘 metadata 로딩 때문에 상단 위치/날짜 title이 placeholder에서 실데이터로 바뀌며 살짝 버벅이는 문제도 이번 범위에 포함해야 함
- 특히 principal title은 "날짜만 먼저 표시 -> 위치까지 합쳐 재배치" 흐름이 눈에 띄지 않도록 초기 표시 정책과 로딩 타이밍을 다시 설계해야 함
- `PHAssetOriginalMetadataProperties` 성능 경고는 detached task/caching 이후에도 남아 있어, 보다 근본적인 PhotoKit metadata 접근 전략 재검토가 필요함
- 상단/하단 chrome은 커스텀 디자인 대신 기본 SwiftUI 요소를 사용해야 함
- 편집은 `PHContentEditingController` 기반 시스템 편집 호출을 기대하지 않음. Issue #6에서는 안내 Alert를 유지하고, 앱 내 crop-only 구현은 GitHub Issue `#12`에서 다룸
- 위치는 가능한 경우 `광역/시군구 - 동/가/세부지명` 수준까지 더 자세히 표시
- 상단 중앙 타이틀은 위치/날짜/시간 2줄 구조로 재설계
- 상세정보 시트는 날짜+시간, 사진 이름(파일명), 촬영 기기, 위치, 소속 앨범을 표시해야 함
- iOS 26 기준 네비바와 하단 버튼은 가능하면 system toolbar + Liquid Glass 인상에 더 가깝게 보여야 함
- 다만 system toolbar 전환이 실제로 안정적인지, 또는 overlay 전략이 더 안전한지는 아직 미정임

### 6. API / 데이터 가용성 메모

- 확인됨: Apple Developer Documentation 기준 `PHContentEditingController`는 Photos 앱이 호스팅하는 photo editing extension UI용 프로토콜임. 즉, 우리 앱 내부에서 시스템 사진 편집 화면을 그대로 여는 해법으로 보면 안 됨.
- 확인됨: 사용자 결정에 따라 Issue #6에서는 편집 버튼을 현재 안내 Alert로 유지하고, 실제 사진 편집/crop-only 구현은 GitHub Issue `#12`로 분리함.
- 확인됨: 파일명은 `PHAssetResource.assetResources(for:)`의 `originalFilename`으로 가져올 수 있음.
- 확인됨: 소속 앨범은 `PHAssetCollection.fetchAssetCollectionsContaining(_:with:options:)` 또는 album fetch 결과 비교로 조회 가능한 방향이 있음.
- 이 세션 이전 구현 기준 확인됨: 사진 자산에 대해 `requestImageDataAndOrientation` + `CGImageSourceCopyPropertiesAtIndex` + TIFF metadata(`Make`/`Model`)로 촬영 기기를 추출했음.
- 이번 세션 반영: 해당 경로를 `PHAssetResource.assetResources(for:)` + `PHAssetResourceManager.requestData` + incremental `CGImageSourceCopyPropertiesAtIndex` probe로 교체했고, metadata가 보이면 조기 cancel 하도록 변경함.
- 같은 후속 세션에서 `withCheckedContinuation` 타입 명시와 `PHPhotosError.operationCancelled` 제거, `CGImageSourceCreateIncremental(nil)` non-optional 처리까지 compile fix를 연달아 amend 반영함.
- 추론: 비디오 촬영 기기명까지 안정적으로 맞추려면 QuickTime metadata 경로를 별도로 추가 검토해야 함.
- caveat: 사용자가 첨부한 HEIC 레퍼런스 이미지는 이 환경에서 직접 렌더링하지 못해, 요청한 정보 밀도는 텍스트 설명 기준으로만 반영함.

### 7. 이번 세션에서 실제로 수정된 파일

- `PHOU/Presentation/MediaDetail/MediaDetailView.swift`
  - scene state, toolbar orchestration, panel open/close, share/alert/sheet presentation만 남도록 축소
  - page view / panel layout / UIKit bridge를 다른 파일로 이동해 조립 책임 중심으로 정리
- `PHOU/Presentation/MediaDetail/MediaDetailFeature.swift`
  - 최신 수정: 대규모 라이브러리에서 상세 뷰 state 비교 비용을 줄이기 위해 `Equatable`을 current item 중심으로 축소
- `PHOU/Presentation/MediaDetail/MediaDetailAssetLoader.swift`
  - detail image / player item / metadata / share item 로딩 책임 분리
  - asset cache, image cache, location cache 유지
- `PHOU/Presentation/MediaDetail/MediaDetailModels.swift`
  - `MediaAssetDetails`와 날짜/시간/타이틀 formatter 분리
- `PHOU/Presentation/MediaDetail/MediaDetailPhotoKitBridge.swift`
  - PhotoKit request cancel safety와 continuation box를 별도 파일로 격리
- `PHOU/Presentation/MediaDetail/MediaDetailPages.swift`
  - `MediaPageView`, `MediaImagePageView`, `MediaVideoPageView` 분리
- `PHOU/Presentation/MediaDetail/MediaDetailPanels.swift`
  - inline info panel, `MediaDetailLayout`, album picker를 분리
- `PHOU/Presentation/MediaDetail/MediaDetailUIKit.swift`
  - `ZoomableImageView`, `PlayerLayerView`, `LayoutAwareScrollView`를 별도 파일로 분리
- `PHOU/Presentation/MediaDetail/MediaDetailShareSheet.swift`
  - `UIActivityViewController` wrapper를 단독 파일로 분리
- `PHOU/Presentation/Components/PhotoThumbnailView.swift`
  - caching/cancel 유지
  - 썸네일 화질 복구
  - 실제 셀 크기 기반 요청
  - `PHAsset` cache 추가
  - cancel/error 경로 continuation 누수 방지
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

### 8. 현재 blocker / caveat

- 사용자 확인 기준으로 다음 두 증상은 아직 미해결 상태:
  - normal/immersive 전환 시 사진 여백과 상단 spacing이 기대와 다름
  - iPhone 13 mini에서 상세 뷰 레이아웃이 더 쉽게 깨짐
- 사용자 최신 피드백 기준 추가 재검증 필요 항목:
  - 세로 사진은 normal/immersive가 사실상 같은 크기로 보여야 함
  - iOS 18 하단 `ToolbarItem` 배치는 사용자 확인 기준 맞았으므로, 이후 리팩토링 뒤에도 같은 배치가 유지되는지만 보면 됨
  - 실기기에서만 상세 뷰 진입/사진 간 전환/normal↔immersive 전환/dismiss가 심하게 느림
  - 동영상이 크롭 없이 safe-area 무시 full-bleed 프레임 안에서 기대한 aspect-fit으로 보이는지 미확인
- system toolbar 전환 후 runtime 경고:
  - `Adding 'UIKitToolbar' as a subview of UIHostingController.view is not supported and may result in a broken view hierarchy.`
- 위 경고는 현재 `bottomBar/status` 조합에서도 남는지 먼저 확인해야 하며, 남는다면 `fullScreenCover`로 띄운 SwiftUI 상세 뷰 내부의 toolbar/presentation 조합과 연관될 가능성이 높음
- `com.apple.accounts Code=7` 및 `CMPhotoJFIFUtilities err=-17102` 로그는 시스템/자산 레벨 노이즈일 가능성이 있으나, 아직 근거가 부족하므로 원인 미상으로 보존해야 함
## 2026-04-27 후속 세션 — 런타임 경고 완전 해결

### PHAssetOriginalMetadataProperties 경고 근본 원인 및 해결

**경고**: `Missing prefetched properties for PHAssetOriginalMetadataProperties ... Fetching on demand on the main queue, which may degrade performance.`

**근본 원인**: `provisionalSummaryDetails`가 `onChange(of: currentAssetID)` 핸들러(메인 스레드)에서 동기 호출되면서 내부에서 두 가지 PHAsset 속성에 접근했음:
1. `phAsset.location` — 일부 자산은 GPS 정보가 PHAsset DB가 아닌 이미지 파일 EXIF에 저장되어 있어, 메인 스레드에서 접근 시 `PHAssetOriginalMetadataProperties`를 fault-load함
2. `PHAssetResource.assetResources(for: phAsset)` (`resolvedFilename`) — 리소스 목록 조회도 동일하게 metadata fault 유발 가능

이전에 촬영 기기 추출 경로를 `requestImageDataAndOrientation`에서 `PHAssetResourceManager.requestData` + incremental probe로 교체했을 때 경고가 줄었지만 완전히 사라지지 않았던 이유가 이것임.

**해결**: `provisionalSummaryDetails`를 `PhotoAsset` + `locationCache` 전용으로 제한. PHAsset/PHAssetResource 접근 완전 제거.
- `phAsset.location` → `locationCache` 조회로 대체 (없으면 "위치 확인 중" 플레이스홀더)
- `resolvedFilename(for: phAsset)` → "정보 확인 중" 플레이스홀더로 대체
- `phAsset.isFavorite` → `asset.isFavorite` (PhotoAsset, TCA 상태)
- `phAsset.pixelWidth/Height` → "-" 플레이스홀더로 대체

**부수 효과**: `UIKitToolbar` hierarchy 경고도 함께 사라짐. 경고의 근본 원인이 PHAsset 메타데이터 fault로 인한 메인 스레드 부하였던 것으로 추정됨.

### ContinuationBox<T> 제네릭의 Swift 6 sending 파라미터

**문제**: 제네릭 `ContinuationBox<T>`에서 `func resume(_ value: T)` 호출 시 `Sending 'value' risks causing data races` Swift 6 오류 발생.

**원인**: Swift 6에서 `CheckedContinuation.resume(returning:)`은 `sending T` 파라미터를 요구함. `T: Sendable` 제약 없는 제네릭에서 값 전달 시 region-isolation 오류 발생.

**해결**: `func resume(_ value: sending T)` — `sending` 키워드로 호출자가 disconnected region에서 값을 전달함을 명시, `resume(returning:)` 체인이 성립함. UIImage, AVPlayerItem 등 non-Sendable 타입도 별도 래퍼 없이 처리 가능.

### Xcode MCP 도입

- `xcrun mcpbridge` 기반 Xcode MCP 서버 등록 (`claude mcp add --transport stdio xcode -- xcrun mcpbridge`)
- `mcp__xcode__BuildProject`로 Xcode에서 직접 빌드 성공 확인 가능해짐
- 이전까지 scheme 부재/SPM sandbox 제약으로 막혀 있던 빌드 검증 문제 해소
- `tabIdentifier: windowtab5` (현재 열린 PHOU 프로젝트 탭)

### 이번 세션 커밋 목록

| 커밋 | 내용 |
|------|------|
| `4fc2bb1` | `refactor: #6 - MediaDetail 코드 품질 수정` (ContinuationBox 통합, dead code 제거 등) |
| `7c6e3fa` | `fix: #6 - ContinuationBox.resume sending 파라미터 추가` |
| `8aa72f2` | `fix: #6 - provisionalSummaryDetails 메인 스레드 metadata fault 제거` |

---

## 2026-04-27 코드 품질 수정 세션 요약

### 이번 세션에서 적용된 수정

**`MediaDetailPhotoKitBridge.swift`**:
- `ImageContinuationBox`, `PlayerItemContinuationBox`, `URLContinuationBox`, `DataContinuationBox`, `ImagePropertiesContinuationBox` 5개 클래스를 제네릭 `ContinuationBox<T>: @unchecked Sendable` 하나로 통합했음. NSLock 자체는 필요하다고 판단 — PhotoKit callback 스레드와 Swift task 취소 핸들러가 동시에 continuation을 resume할 수 있기 때문.
- `requestImage`에서 도달 불가한 두 번째 조건 제거: `isDegraded == true`이고 `deliveryMode == .highQualityFormat`일 때 degraded 이미지를 반환하는 분기. `.highQualityFormat`은 degraded를 먼저 보내지 않으므로 실제 도달하지 않는 dead code였음.
- 미사용 `requestImageData` 함수 제거 (정의만 있고 호출처 없음).

**`MediaDetailAssetLoader.swift`**:
- `provisionalSummaryDetails`가 `onChange(of: currentAssetID)` 핸들러에서 메인 스레드에 동기 호출되면서 내부에서 `PHAsset.fetchAssets`를 실행하는 문제 수정. 이제 `assetCache` 미스 시 즉시 `.placeholder`를 반환. 실데이터는 항상 뒤따르는 async `refreshCurrentDetails()` task가 채움.
- `deduplicatedLocationComponent(_, fallback:)` 함수 제거 — `preferred ?? fallback` 동일 구현. 호출부를 직접 nil 병합으로 대체.

**`MediaDetailView.swift`**:
- `detailsPanel(layout:)` 내 이중 nil 병합 제거. `displayedDetails`가 이미 `currentDetails ?? currentAsset.map(.placeholder)` fallback을 포함하므로 두 번째 `?? currentAsset.map(...)` 불필요.

**`MediaDetailPanels.swift`**:
- `AlbumPickerSheet`의 `ForEach(Array(albums.enumerated()), id: \.element.id)` → `ForEach(albums)` (`AlbumGroup: Identifiable` 활용).

### 빌드 검증 상태
- xcodebuild target 빌드는 기존 sandbox SPM 모듈 해석 오류(`ConcurrencyExtras`, `IssueReporting`)로 막혀 있음. 이번 세션 변경과 무관한 기존 blocker.
- 수정된 파일 자체의 로직 오류는 없음을 코드 리뷰로 확인.

---

## 현재 MediaDetail 파일 구조

- `MediaDetailView.swift`
  - 화면 조립, toolbar content, panel open/close, route-level state
- `MediaDetailPages.swift`
  - `MediaPageView`, `MediaImagePageView`, `MediaVideoPageView`
- `MediaDetailPanels.swift`
  - inline info panel, `MediaDetailLayout`, album picker
- `MediaDetailUIKit.swift`
  - `ZoomableImageView`, `PlayerLayerView`, `LayoutAwareScrollView`
- `MediaDetailAssetLoader.swift`
  - display image / player item / share item / metadata load
- `MediaDetailModels.swift`
  - `MediaAssetDetails`와 formatter
- `MediaDetailPhotoKitBridge.swift`
  - continuation box와 request cancel safety 래퍼
- `MediaDetailShareSheet.swift`
  - 공유 시트 브리지

## UIKit 감사 메모

- 현재 UIKit 사용 지점
  - `ZoomableImageView` + `UIScrollView`
  - `PlayerLayerView` + `AVPlayerLayer`
  - `ShareSheetView` + `UIActivityViewController`
- 우선 유지 후보
  - `ZoomableImageView`: pinch center, pan, centering, double-tap zoom 요구사항 때문에 당장은 UIKit 유지 쪽이 더 안전
  - `PlayerLayerView`: 현재 `VideoPlayer`보다 제어가 단순하고 full-bleed aspect behavior를 직접 맞추기 쉬움
- SwiftUI 전환 검토 후보
  - `ShareSheetView`: `ShareLink`로 충분한 UX를 낼 수 있는지 검토
  - UIKit helper가 단순 wrapper 수준으로만 남아 있는 경우 별도 SwiftUI component 또는 modifier로 대체 가능성 검토

## 실기기 성능 가설 업데이트

- 가장 유력한 병목은 `TabView`가 현재/인접 페이지만 로드하더라도 body 재계산 시 전체 `items` 컬렉션을 기준으로 page tree를 다시 구성하는 점입니다. 라이브러리 규모가 클수록 진입/스와이프/닫기 시 diff와 identity 비교 비용이 누적될 수 있습니다.
- 두 번째 후보는 고해상도 이미지 decode 비용입니다. 현재는 `displayImage(for:targetSize:)`가 viewport 기준으로 큰 이미지를 요청하고 있고, 실제 디코드/리사이즈 타이밍이 메인 스레드 frame budget과 겹치면 첫 진입과 페이지 전환에서 hitch가 생길 수 있습니다.
- 세 번째 후보는 `fullScreenCover + NavigationStack + zoom transition + toolbar` 조합입니다. 특히 하단 `bottomBar/status` 조합과 함께 `UIKitToolbar` 경고가 관찰돼 hierarchy 구성 자체가 불안정할 가능성이 있습니다.
- 네 번째 후보는 동영상/메타데이터 부가 작업입니다. 활성 페이지 video player item 준비, 현재 asset의 summary metadata 계산, reverse geocoding, album membership 조회가 같은 시점에 겹치면 체감이 더 나빠질 수 있습니다. 이 중 geocoding/album 조회는 현재도 비교적 늦게 로드하지만, summary title 갱신과 player 준비는 여전히 전환 직후에 맞물립니다.
- 현재 수정으로 줄어든 비용:
  - video rendering을 `AVPlayerViewController`에서 `AVPlayerLayer`로 단순화
  - immersive 전환 시 viewport 재계산 대신 UI/background visibility만 변경
  - `MediaDetailFeature.State`의 `Equatable` 범위를 current item 중심으로 축소
- 다음 profiling 우선순위:
  1. 상세 뷰 진입 직후 Time Profiler에서 main-thread 상위 비용이 image decode인지 SwiftUI layout/diff인지 분리
  2. SwiftUI Instruments에서 `MediaDetailView` body invalidation 범위와 빈도 확인
  3. 라이브러리 규모가 큰 기기에서 현재 index ±N window만 실제 page tree에 올리는 구조로 줄여야 하는지 판단
  4. 필요 시 상세 메타데이터 title summary도 placeholder 고정 후 idle 시점에 갱신하도록 더 늦출지 검토

---

## 오픈 질문

- 촬영 기기명을 사진/동영상 모두에서 같은 수준으로 제공할 수 있는지, 아니면 자산 타입별 fallback 정책이 필요한지
- 상세정보 시트의 소속 앨범을 모든 앨범 제목 리스트로 보여줄지, 사용자에게 의미 있는 대표 앨범만 보여줄지
- 현재 toolbar 기반 chrome 구조(상단 navigation toolbar + 하단 bottomBar/status)가 `fullScreenCover` + zoom transition + inline panel 조합에서 hierarchy 경고 없이 유지 가능한지
- 현재 분리된 MediaDetail 파일 구조가 장기적으로도 유지보수하기 좋은지
- inline 정보 패널 drag가 pager/zoom과 실제 사용에서 충돌하지 않는지
- 핀치 기반 열 수 변경이 회전/iPad/split view에서도 충분히 자연스러운지
- 썸네일 preheat(`startCachingImages`)가 실제 체감 성능 개선에 얼마나 기여하는지 profiling이 필요한지

---

## 다음 즉시 작업

1. `UIKitToolbar` hierarchy 경고가 어떤 presentation 조합에서 나는지 재현 조건을 좁히기
2. 세로 사진이 normal/immersive에서 같은 fit size를 유지하는지 실기기와 작은 시뮬레이터에서 수동 확인
3. 실기기 지연이 라이브러리 규모, TCA state diff, metadata 로딩, `TabView` 페이지 유지, player 생성 중 어디에서 오는지 profiling/가설 검증
4. 현재 toolbar 기반 chrome 구조가 충분히 안정적인지 확인하고, 필요 시 placement 조합 또는 overlay fallback 범위를 다시 검토
5. 사진/동영상/줌 상태에서 inline 패널 drag가 pager와 충돌하지 않는지 확인
6. iPad 레이아웃/회전 및 split view에서 상세 뷰가 깨지지 않는지 확인

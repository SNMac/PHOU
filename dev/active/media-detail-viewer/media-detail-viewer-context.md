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
| 미디어 상세 Feature | `PHOU/Presentation/MediaDetail/MediaDetailFeature.swift` |
| 미디어 상세 View | `PHOU/Presentation/MediaDetail/MediaDetailView.swift` |
| 미디어 상세 지원 코드 | `PHOU/Presentation/MediaDetail/MediaDetailSupport.swift` |

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
- 상세 뷰 chrome은 상단(뒤로가기, 날짜/위치, 즐겨찾기 상태) / 하단(공유, 상세정보, 편집 안내) 구조로 확장됨
- 현재 상단/하단 chrome은 capsule/circle 배경의 커스텀 SwiftUI UI이며, 사용자 요청은 이를 기본 SwiftUI 요소 기반으로 단순화하는 것임
- 상단 중앙 타이틀은 현재 날짜 1줄 + 위치 1줄 구조인데, 요청사항은 위치 유무에 따라 위치/날짜/시간 2줄 위계를 바꾸는 것임
- 위치 문자열은 현재 `locality`, `subLocality`, `name`, `administrativeArea` 중 첫 non-empty 값 하나만 사용해 `수원시`, `서울특별시` 같은 얕은 정보만 나올 수 있음
- 상세정보 시트는 현재 날짜, 위치, 종류, 크기, 즐겨찾기만 보여주며 파일명, 촬영 기기, 소속 앨범을 제공하지 않음
- 편집 버튼은 현재 alert만 띄우고 있으며 crop 또는 다른 실제 편집 기능은 없음
- 배경은 기본 `systemBackground`이고 단일 탭으로 black immersive background를 토글 가능
- 사진은 `UIScrollView` 레벨의 double-tap zoom을 추가

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
- 현재 세션에서 상세 뷰 로딩/공유/메타데이터 처리를 `MediaDetailSupport.swift`로 분리해 request cancel safety, display image cache, player item load, share item 준비, 위치 reverse geocoding fallback을 한 곳에서 관리
- 상세 뷰는 현재/인접 사진 페이지만 우선 로드하고, 비디오는 active page에서만 플레이어를 준비하도록 바꿔 initial presentation/swipe 비용을 낮춤
- 초기 사진 Y축 정렬 문제는 `UIScrollView.contentInsetAdjustmentBehavior = .never`, layout 후 centering, background-aware zoom view 갱신으로 한 차례 보정했지만 user report 기준 최초 진입 재현이 남아 있음
- 공유는 `UIActivityViewController` sheet로 연결했고, 편집 버튼은 공개 시스템 사진 편집 API 부재를 안내하는 alert로 처리

### 5. 이번 사용자 피드백으로 scope가 다시 바뀜

- 상세 뷰 사진은 최초 진입 시점부터 Y축 중앙 정렬이 맞아야 함
- 상단/하단 chrome은 커스텀 디자인 대신 기본 SwiftUI 요소를 사용해야 함
- 편집은 `PHContentEditingController` 기반 시스템 편집 호출을 기대하지 않고, 앱 내 구현이 필요하면 crop-only부터 시작
- 위치는 가능한 경우 `광역/시군구 - 동/가/세부지명` 수준까지 더 자세히 표시
- 상단 중앙 타이틀은 위치/날짜/시간 2줄 구조로 재설계
- 상세정보 시트는 날짜+시간, 사진 이름(파일명), 촬영 기기, 위치, 소속 앨범을 표시해야 함

### 6. API / 데이터 가용성 메모

- 확인됨: Apple Developer Documentation 기준 `PHContentEditingController`는 Photos 앱이 호스팅하는 photo editing extension UI용 프로토콜임. 즉, 우리 앱 내부에서 시스템 사진 편집 화면을 그대로 여는 해법으로 보면 안 됨.
- 확인됨: 파일명은 `PHAssetResource.assetResources(for:)`의 `originalFilename`으로 가져올 수 있음.
- 확인됨: 소속 앨범은 `PHAssetCollection.fetchAssetCollectionsContaining(_:with:options:)` 또는 album fetch 결과 비교로 조회 가능한 방향이 있음.
- 추론: 촬영 기기 표시는 원본 이미지/비디오 메타데이터(EXIF/TIFF/QuickTime metadata) 추출이 필요할 가능성이 높고, 일부 자산에서는 값이 없을 수 있음.
- caveat: 사용자가 첨부한 HEIC 레퍼런스 이미지는 이 환경에서 직접 렌더링하지 못해, 요청한 정보 밀도는 텍스트 설명 기준으로만 반영함.

### 7. 이번 세션에서 실제로 수정된 파일

- `PHOU/Presentation/MediaDetail/MediaDetailView.swift`
  - 사진 initial fit 계산을 aspect-fit 기준으로 보정했지만 최초 진입 Y축 중앙 정렬 이슈는 아직 추가 수정 필요
  - `UIScrollView` 기반 zoom/pan 도입
  - inactive video pause 로직 추가
  - 플레이어 로딩 경로를 `requestPlayerItem(forVideo:)`로 교체
  - iOS 18 zoom transition 적용
  - 시스템 playback controls 비활성화
  - 단일 탭 배경 토글, double-tap zoom, 상단/하단 chrome, share/info/edit UI 추가
  - 현재/인접 페이지 우선 로딩 반영
- `PHOU/Presentation/MediaDetail/MediaDetailSupport.swift`
  - PhotoKit request safety 래퍼 추가
  - detail image / player item / metadata / share item 로딩 공용화
  - location reverse geocoding + fallback 처리
  - 다음 수정에서는 파일명/앨범/기기 메타데이터와 Photos-style 날짜/시간 formatter 확장이 들어갈 가능성이 높음
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

---

## 오픈 질문

- 촬영 기기명을 사진/동영상 모두에서 같은 수준으로 제공할 수 있는지, 아니면 자산 타입별 fallback 정책이 필요한지
- 상세정보 시트의 소속 앨범을 모든 앨범 제목 리스트로 보여줄지, 사용자에게 의미 있는 대표 앨범만 보여줄지
- 편집 버튼이 즉시 crop 화면으로 들어갈지, 추후 기능 확장을 고려해 별도 action sheet를 둘지
- 상단 우측의 즐겨찾기 상태를 계속 read-only로 둘지, 실제 toggle 액션까지 연결할지
- 핀치 기반 열 수 변경이 회전/iPad/split view에서도 충분히 자연스러운지
- 썸네일 preheat(`startCachingImages`)가 실제 체감 성능 개선에 얼마나 기여하는지 profiling이 필요한지

---

## 다음 즉시 작업

1. `ZoomableImageView`의 초기 layout/centering 순서를 다시 점검해 최초 진입 Y축 중앙 정렬 버그를 해결
2. `MediaDetailView`의 커스텀 top/bottom bar를 기본 SwiftUI toolbar / action 구성으로 전환
3. `MediaDetailSupport.swift`에 위치/날짜/시간 formatter와 상세 정보 데이터 소스를 확장
4. 파일명, 앨범 membership, 촬영 기기 메타데이터의 실제 가용성을 코드로 확인하고 info sheet에 연결
5. 편집 액션 범위를 crop-only로 확정할지 판단하고, 확정 시 UI/저장 경로를 설계

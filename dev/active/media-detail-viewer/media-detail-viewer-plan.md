# feat: 재사용 가능한 미디어 상세 뷰어 구현

**GitHub Issue**: #6  
**Last Updated**: 2026-04-30

---

## Executive Summary

현재 앱에는 그리드 셀 탭 후 진입하는 상세 미디어 뷰어가 없습니다. 이번 작업의 목표는 갤러리 전용 사진 상세 화면이 아니라, 앱 어디서든 재사용할 수 있는 전체화면 미디어 뷰어를 구현하는 것입니다.

1차 범위는 `PhotoAsset` 기반 입력으로 사진과 동영상을 모두 표시할 수 있는 `MediaDetailFeature` / `MediaDetailView`를 만드는 것입니다. 사진은 pinch-to-zoom을 우선 지원하고, 동영상은 재생 중심으로 구현하되 추후 줌 확장이 가능하도록 상태/레이아웃 구조를 설계합니다. 첫 적용 화면은 `Gallery`와 `AlbumPhotoGrid`입니다.

현재는 iOS 최소 버전이 18.0 이상으로 올라가면서, 상세 진입 전환도 시스템 zoom transition을 활용하는 방향으로 범위가 확장되었습니다. 또한 그리드 썸네일 쪽은 체감 성능 개선을 위해 실제 셀 크기 기반 요청과 asset 재조회 감소를 반영합니다.

이번 세션에서는 상세 뷰를 "몰입형 미디어 레이어 + 정보 chrome" 구조로 확장해, 단일 탭 배경 토글, 더블 탭 줌, 상하단 액션 바, 현재 asset 메타데이터 표시까지 같은 흐름에서 정리합니다. 지연 완화는 모든 페이지를 동시에 고해상도 로딩하던 기존 방식 대신 현재/인접 페이지 중심 로딩으로 보정합니다.

추가 사용자 피드백으로 scope가 다시 조정되었습니다. 상세 뷰는 iPhone 기본 사진 앱에 더 가깝게 다듬어야 하며, 상단/하단 chrome은 fade되는 overlay 성격으로 유지하되 제스처와 safe area 변화에 자연스럽게 반응해야 합니다. 또한 상세 정보는 별도 modal sheet보다 Photos 앱처럼 아래에서 올라오는 inline info panel 구조가 더 맞는 것으로 범위가 재정의되었습니다. 편집 기능은 공개 시스템 사진 편집 UI를 앱 내부에서 직접 띄우는 방향이 아니라, 필요 시 crop-only 커스텀 편집으로 축소하는 쪽으로 재정의합니다.

2026-04-24 추가 사용자 피드백으로 방향이 한 번 더 좁혀졌습니다. 현재의 inline info panel도 여전히 "하단에서 별도 레이어가 올라오는 패널"에 가깝고, reference인 iOS 기본 사진 앱처럼 "같은 상세 화면을 위로 스크롤하면 정보가 이어지고, 스냅되며, toolbar는 그 위에 남아있는" 감각과는 차이가 있습니다. 다음 구현은 패널 polish보다 구조 변경이 우선입니다.

같은 맥락으로, 이전 성능 최적화에서 metadata 로딩 시점을 늦춘 영향으로 상단 principal title이 진입 직후 잠깐 불안정해지는 부작용도 확인됐습니다. 현재는 날짜만 먼저 보였다가 위치가 나중에 붙으며 title 폭과 줄 배치가 살짝 바뀌기 때문에, 다음 구현에서는 "정보를 늦게 불러오더라도 상단 요약 UI는 안정적으로 유지"를 별도 목표로 둡니다.

가장 최근 세션에서는 iOS 26 기본 사진 앱의 Liquid Glass 인상을 맞추기 위해 `ToolbarItem` / `ToolbarItemGroup` 기반 system toolbar 전환을 시도했습니다. 사용자의 최신 피드백에 따라 하단도 `ToolbarItem` 기반을 유지합니다. 2026-04-24 커밋(`5d753c6`)에서 iOS 26 미만 경로를 `bottomBar` + `status` placement 조합으로 다시 조정했고, 사용자 확인 기준 의도한 3구역 배치가 맞는 상태입니다.

가장 최근 세션에서 위 리팩토링을 실제로 수행했습니다. `MediaDetailView.swift`는 화면 조립 중심으로 줄였고, 기존 `MediaDetailSupport.swift`는 역할별 파일로 해체했습니다. 편집 기능은 Issue #6 범위에서는 현재 안내 Alert를 유지하고, 실제 사진 편집/crop-only 구현은 GitHub Issue #12로 분리했습니다. 현재 우선순위는 남은 UX/polish 검증을 이어가는 것입니다.

2026-04-30 후속 UX 세션에서는 상세정보 패널의 metadata preload, placeholder 전환, title 깜빡임, 내부 텍스트 위치 흔들림은 대부분 정리됐습니다. 다만 Photos 스타일 reveal에서 사진이 패널과 함께 위로 lift 될 때 `TabView + ZoomableImageView(UIScrollView)` 조합이 위아래로 떨리는 문제가 남았습니다. 여러 UIKit 안정화 시도 후에도 완전히 해결되지 않아, 현재 코드에서는 임시로 사진 lift를 제거한 상태입니다. 이 상태는 떨림 회피에는 유리하지만 사용자가 원하는 "시트가 올라오며 사진도 함께 위로 움직이는" UX와 어긋납니다.

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
| 상세 미디어 화면 | ✅ 1차 구현 완료 | 사진/동영상 full-screen viewer는 연결됐고, 현재는 UX polish 단계 |
| 셀 탭 액션 | ✅ 구현 완료 | `GalleryView`, `AlbumPhotoGridView` 그리드 셀이 뷰어 진입을 트리거함 |
| 갤러리 fetch 범위 | ✅ mixed media 전환 완료 | `fetchMedia()` 기반으로 사진/동영상 혼합 자산을 표시 |
| 고해상도 원본 로딩 | ✅ 1차 구현 완료 | detail image loader와 현재/인접 페이지 우선 로딩이 반영됨 |
| 동영상 재생 | ✅ 1차 구현 완료 | 재생은 가능하며, 최신 수정에서 `AVPlayerLayer` 기반으로 단순화해 크롭 없이 한 축이 꽉 차는 aspect-fit 표시를 우선 적용 |
| 사진 초기 세로 정렬 | ⚠️ 보정 후 재검증 필요 | `LayoutAwareScrollView` 기반 재-centering 경로를 추가했지만 실제 사용자 재현이 사라졌는지는 아직 수동 확인 필요 |
| 상세 chrome 구성 | ✅ 안정화 | iOS 26 미만 하단 `ToolbarItem` 배치 맞음. `UIKitToolbar` 경고는 `provisionalSummaryDetails` 메인 스레드 PHAsset 접근 제거 후 함께 사라짐 |
| 위치/날짜 포맷 | ✅ 1차 구현 완료 | 위치 유무에 따른 2줄 타이틀과 최근성/24시간 설정 기반 포맷이 코드에 반영됨 |
| 상세정보 표시 | ⚠️ 구조 전환 중 | metadata preload/title 안정화/내부 행 고정은 반영됨. 최신 수정에서 `TabView` 자체 대신 각 page content에 `visualEffect` lift를 적용해 미디어 동반 이동을 복원했고, 사용자 확인 기준 reveal 중 사진 떨림은 사라짐. dismiss 마지막 jump와 확대 pan 관성 보정은 남음 |
| 편집 기능 | ✅ 범위 확정 | Issue #6에서는 현재 안내 alert를 유지하고, crop-only 편집 구현은 GitHub Issue #12로 분리 |
| 파일 구조 | ✅ 1차 리팩토링 완료 | `MediaDetailView.swift`를 456줄까지 줄였고, support 책임은 loader / models / pages / panels / UIKit bridge / PhotoKit bridge / share sheet 파일로 분리됨 |

### 현재 구현 반영 상태

- `MediaDetailFeature` / `MediaDetailView` 구현 완료
- `GalleryFeature`는 `fetchMedia()` 기반 mixed media fetch로 전환 완료
- `GalleryView`, `AlbumPhotoGridView`에서 동일한 full-screen 미디어 뷰어 연결 완료
- 사진은 `UIScrollView` 기반 zoom/pan으로 전환되어 일반 사진 앱에 가까운 상호작용을 목표로 보정됐지만, 최초 진입 직후 Y축 중앙 정렬은 아직 완전히 해결되지 않음
- 동영상은 `requestPlayerItem(forVideo:)` 이후 `AVPlayerLayer` 기반 뷰로 표시해, safe area를 무시한 full-bleed 프레임 안에서 aspect-fit으로 가로 또는 세로 한 축이 항상 꽉 차도록 조정
- 활성 페이지가 아닌 동영상은 pause 하도록 로직 추가
- 썸네일은 `PHCachingImageManager` + request cancel을 유지하면서 화질을 다시 `highQualityFormat` 쪽으로 복구
- 상단/하단 chrome 모두 `ToolbarItem` 기반을 유지하되, 하단은 iOS 18에서 `bottomBar` + `status` placement 조합으로 재배치함
- iOS 26 미만 하단 `ToolbarItem` 재배치는 사용자 확인 기준으로 의도한 레이아웃이 맞는 상태
- 중앙 타이틀은 위치 유무에 따라 `위치 / 날짜+시간` 또는 `날짜 / 시간` 2줄 구조를 사용함
- 위치 표기는 `administrativeArea/locality/subLocality/thoroughfare/name` 조합 기반의 best-effort 상세 문자열로 확장됨
- 상세정보는 이제 modal sheet 대신 inline panel 후보 구조로 전환 중이며, 날짜+시간, 파일명, 촬영 기기, 위치, 소속 앨범을 같은 데이터 소스로 표시함
- 촬영 기기 표시는 현재 사진 자산에서 `PHAssetResourceManager.requestData` + incremental ImageIO metadata probe 기반 best-effort 구현으로 전환 중이며, `CGImageSourceCreateIncremental(nil)`는 current SDK에서 non-optional 취급으로 맞춰 정리했고, 비디오 및 일부 자산은 `정보 없음` fallback이 남음
- 편집 버튼은 현재 "공개 시스템 사진 편집 UI를 직접 열 수 없다"는 안내 alert를 유지하며, 실제 편집 기능은 GitHub Issue #12에서 다룸
- `xcodebuild -quiet -project PHOU.xcodeproj -scheme PHOU build` 재성공
- 테스트 타깃은 아직 없어 reducer/unit test는 미구현
- 사용자 런타임 보고:
  - `Adding 'UIKitToolbar' as a subview of UIHostingController.view is not supported...` 경고가 상세 뷰 진입 중 관찰됨
  - `Error returned from daemon: Error Domain=com.apple.accounts Code=7 "(null)"` 로그가 함께 관찰됨
  - `<<<< CMPhotoJFIFUtilities >>>> signalled err=-17102` 로그가 반복 관찰됨
- 위 세 로그 중 마지막 두 개는 현재 구현과 직접 연관인지 아직 확인되지 않았고, 첫 번째 `UIKitToolbar` 경고는 최근 toolbar 구조 전환과 연관 가능성이 높아 보이므로 우선 조사 대상임
- 구조 리팩토링은 1차 완료됨
- 최신 사용자 확인 기준으로 빌드와 실행 모두 정상 동작함
- 다음 작업의 최우선순위는 사진 떨림 없이 Photos 스타일 reveal을 복원하는 것임. 현재는 `TabView + UIScrollView`를 직접 offset으로 움직이는 방식 대신 snapshot/proxy layer 또는 별도 non-layout transform container를 검토해야 함

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
- 상단 principal title에 필요한 최소 요약 데이터(날짜/시간/위치 fallback)를 어느 시점에 확보할지 정하고, 늦은 metadata 로딩 때문에 title이 재배치되지 않도록 정책을 정의합니다.

### Phase 2: MediaDetailFeature 상태 설계

- `items`, `currentIndex`, loading/error, dismiss/paging 액션을 정의합니다.
- 사진 줌 상태와 동영상 재생 상태를 한 Feature 내부에서 다루되, 뷰 단에서 분기 가능한 구조로 유지합니다.
- `@Presents` 또는 `sheet/fullScreenCover` 진입 방식을 결정합니다.

### Phase 3: MediaDetailView UI 구현

- 전체화면 레이아웃, dismiss affordance, 현재 index 기준 media 표시를 구현합니다.
- 사진은 고해상도 이미지와 pinch-to-zoom을 지원합니다.
- 동영상은 `AVPlayer` / `VideoPlayer` 기반 재생을 지원합니다.
- 좌우 스와이프 paging UX를 구현합니다.
- 상단 chrome은 기본 SwiftUI navigation bar / toolbar 기반 구성을 우선 시도하되, `fullScreenCover` + `ToolbarItem` 조합에서 hierarchy 경고나 레이아웃 깨짐이 남으면 overlay 전략으로 되돌리는 것도 허용합니다.
- 위치가 있으면 상단 줄에 위치, 하단 줄에 날짜+시간을 표시하고, 위치가 없으면 상단 줄에 날짜, 하단 줄에 시간을 표시합니다.
- 날짜는 현재 시점 기준 최근 1주 이내면 요일, 같은 해면 `M월 d일`, 그보다 과거면 `yyyy년 M월 d일` 규칙을 따릅니다.
- 시간은 사용자의 24시간 표기 설정을 따라 24시 또는 `오전`/`오후` 12시간 형식으로 표시합니다.
- 하단 액션은 `ToolbarItem` 기반을 유지합니다. iOS 18에서는 `bottomBar`와 `status` placement를 조합해 `share+favorite / info / crop+delete` 3구역에 가깝게 맞추고, iOS 26에서는 기존 `ToolbarSpacer` 기반 glass grouping 실험을 유지합니다.
- 단일 탭 immersive 전환은 배경색과 chrome visibility만 바꾸고, 미디어 viewport 크기는 normal/immersive에서 동일하게 유지합니다.
- 사진은 더블 탭으로 확대/축소를 지원합니다.
- 사진은 최초 진입 직후에도 별도 상호작용 없이 Y축 중앙 정렬되어야 합니다.
- 위로 스와이프하면 사진이 위로 lift 되면서 하단에서 inline 정보 패널이 올라와야 합니다.

### Phase 3B: Photos 스타일 시트 표현으로 재정렬

- `MediaDetailView`의 상세 정보 표현 모델은 `ZStack + bottom overlay panel + media lift` 구조를 유지하되, "별도 패널이 뜬다"보다 "시트가 올라오면서 사진이 함께 붙어 올라간다"는 체감에 맞춰 다듬습니다.
- info 버튼과 upward swipe는 모두 같은 panel reveal 동작을 트리거하도록 유지합니다.
- 세로 사진은 details reveal 전후에도 viewport 기준 중앙 정렬을 잃지 않아야 합니다.
- panel이 열린 상태에서 horizontal paging을 해도 panel은 유지되고, 내부 메타데이터는 새 current asset 기준으로 즉시 갱신되어야 합니다. 현재 코드에는 이 동작이 반영되었습니다.
- 상단 toolbar는 content 바깥 chrome으로 유지하고, 하단 액션도 system toolbar를 우선 유지합니다.
- 현재 `currentDetails`의 summary/details 2단계 로딩 구조는 유지하되, summary는 첫 진입부터 title 안정화에 충분한 정보를 제공해야 하고 expanded metadata는 panel 노출 시점에 이어서 불러옵니다.
- summary/details 2단계 로딩을 유지하더라도, 상단 principal title은 placeholder에서 실데이터로 바뀌며 폭이 흔들리지 않도록 별도 안정화 경로를 둡니다.
- 후보는 1) title용 최소 요약 데이터를 더 이른 시점에 preload, 2) 위치가 준비될 때까지도 고정 높이/폭 정책 유지, 3) 초기 fallback 문자열을 더 보수적으로 잡아 재배치를 줄이는 방식입니다.
- 상세 정보 내부에는 `캡션 추가` 같은 편집성 UI를 두지 않고, 메타데이터 중심으로만 구성합니다.
- 목표 UX는 "기본 SwiftUI sheet처럼 분리된 모달"도 아니고 "세로 스크롤로 이어지는 상세 본문"도 아닌, Photos 앱 레퍼런스처럼 상단 chrome 위계를 유지한 채 bottom sheet와 미디어가 함께 움직이는 표현입니다.

### Phase 3.5: 메타데이터 / 편집 범위 확장

- inline 정보 패널에 날짜+시간, 파일명, 촬영 기기, 위치, 소속 앨범을 표시할 수 있도록 데이터 소스를 확장합니다.
- 위치는 가능한 경우 `광역/시군구 - 동/가/세부지명` 수준까지 조합하고, 부족한 경우 안전한 fallback 규칙을 둡니다.
- 파일명은 `PHAssetResource` 기반으로 가져오는 방향을 우선 검토합니다.
- 소속 앨범은 PhotoKit album membership 조회로 수집합니다.
- 촬영 기기 표시는 원본 메타데이터(EXIF/TIFF/QuickTime metadata)에서 추출 가능한지 확인하고, 없는 자산은 fallback을 정의합니다.
- `PHAssetOriginalMetadataProperties` 경고가 계속 남는다면, 현재의 `PHAssetResourceManager` probe 이후에도 로그가 남는지 먼저 확인하고, 여전히 남을 때만 PhotoKit fetch/prefetch 전략까지 넓혀 재설계합니다.
- 편집 기능은 `PHContentEditingController`를 앱 내부 시스템 편집기로 오해하지 않도록 범위를 분리하고, 앱 내 구현이 필요하면 crop-only 편집부터 시작합니다.

### Phase 4: 첫 소비처 연결

- `GalleryView` 셀 탭 시 뷰어 진입을 연결합니다.
- `AlbumPhotoGridView` 셀 탭 시 동일 뷰어를 재사용하도록 연결합니다.
- 두 화면이 같은 입력 계약을 사용하도록 정리합니다.

### Phase 5: 검증 및 후속 정리

- 빌드/시뮬레이터 기준으로 사진 확대, 동영상 재생, paging, dismiss를 확인합니다.
- mixed media UX에서 남는 후속 항목(비디오 배지, 자동 재생 정책, iPad 레이아웃)을 별도 이슈로 분리할지 결정합니다.

### Phase 6: 구조 리팩토링 및 UIKit 감사

- 완료:
  - `MediaDetailView.swift`는 scene state와 toolbar/panel orchestration 중심으로 축소했습니다.
  - page content는 `MediaDetailPages.swift`로, inline panel과 layout은 `MediaDetailPanels.swift`로, UIKit bridge는 `MediaDetailUIKit.swift`로 옮겼습니다.
  - 기존 `MediaDetailSupport.swift`는 제거하고, `MediaDetailAssetLoader.swift`, `MediaDetailModels.swift`, `MediaDetailPhotoKitBridge.swift`, `MediaDetailShareSheet.swift`로 역할별 분리했습니다.
- 판단:
  - `ZoomableImageView`와 `PlayerLayerView`는 현재 UX 요구사항상 UIKit 유지가 더 안전하다고 보고 유지했습니다.
  - `ShareSheetView`는 단순 wrapper라 추후 `ShareLink` 전환 후보로 남깁니다.
- 검증 상태:
  - 최신 사용자 확인 기준으로 리팩토링 후 빌드와 실행은 모두 정상입니다.
  - 후속 검증은 구조가 아닌 제품 동작과 UX polish 항목 위주로 이어갑니다.

### 현재 남은 후속 작업

- 사진 lift 떨림 없이 Photos 스타일 reveal 복원
  - 최신 코드 상태: `TabView` 자체는 고정하고 각 `MediaPageView` content에 `visualEffect` 기반 lift를 적용함
  - 금지할 가능성이 높은 접근: paging을 담당하는 `TabView`/UIKit page container 자체에 직접 animated `offset` 적용
  - 사용자 확인: 상세 정보 패널 reveal 중 사진 떨림은 사라짐
  - 남은 확인: panel dismiss 마지막에 기본 배율 사진이 중앙으로 jump 하듯 움직이는 현상 제거. 확대 상태에서는 재현되지 않아 기본 fit/centering 복귀 경로를 우선 조사
  - fallback 후보: 현재 사진 snapshot/proxy layer를 따로 lift하거나, zoomable view 외부에 UIKit layout과 분리된 transform 전용 wrapper 도입
- 시뮬레이터/실기기에서 실제 진입/스와이프/동영상 재생 수동 확인
- 복원 후 bottom sheet 표현에서 사진과 시트의 동반 이동감이 레퍼런스처럼 느껴지는지 수동 확인
- upward swipe / downward dismiss 감도와 horizontal media paging/zoom pan의 제스처 충돌 수준 확인
- 확대 상태 사진 pan의 관성이 강해 사용자가 의도한 위치보다 더 이동하는 현상 완화
- info 버튼 탭과 upward swipe가 완전히 같은 reveal/dismiss 상태 전이를 쓰는지 점검
- details reveal 중에도 상단/하단 chrome이 어느 수준까지 유지되어야 하는지 정책 확정
- 상단 위치/날짜 title의 placeholder -> 실데이터 전환은 개선됐지만 실제 기기에서 다시 확인
- 필요 시 현재 페이지 표시와 제스처 충돌 UX 미세 조정
- 사진 세로 중앙 정렬이 최초 진입 시에도 완전히 해결됐는지 수동 검증
- 하단 `ToolbarItem` 배치가 iPhone 작은 기기에서도 `share+favorite / info / crop+delete` 3구역으로 안정적으로 보이는지 확인
- `UIKitToolbar` hierarchy 경고가 현재 `bottomBar/status` 조합에서도 재현되는지, 특정 presentation 조합(`fullScreenCover`, zoom transition, nested NavigationStack)과 연결되는지 확인
- 위치/날짜/시간 포맷이 한국어 로케일과 사용자의 24시간 설정에서 기대대로 보이는지 검증
- 상세정보 시트의 파일명/기기/앨범 정보가 실제 자산에서 일관되게 채워지는지 검증
- `PHAssetOriginalMetadataProperties` 경고가 새 resource-data probe 경로에서도 재현되는지 확인하고, 남는다면 다른 `PHAsset` metadata access 지점을 추가 분리
- crop-only 편집이 도입되면 저장/취소/원본 보존 정책을 추가 검증
- 갤러리 스크롤 성능이 여전히 체감 이슈면 별도 profiling/issue 분리
- `UIKitToolbar` 경고가 여전히 남는지, 현재 구조에서 자연스럽게 사라졌는지 재확인
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
- 현재 구현은 `fullScreenCover` 기반입니다.
- iOS 18+에서는 `matchedTransitionSource` + zoom transition을 통해 셀에서 상세 뷰로 이어지는 확대 전환을 우선 적용합니다.
- 동영상 재생 UI는 현재 브랜치에서 시스템 playback controls를 숨겨 기존 chrome 충돌만 해소하고, 커스텀 플레이어 설계/구현은 별도 후속 작업으로 분리합니다.

### 3. chrome은 ToolbarItem 기반으로 유지

- 상단 title/menu/back affordance는 system navigation toolbar를 유지합니다.
- 하단 액션도 사용자 의도에 맞춰 기본적으로는 `ToolbarItem` 기반을 유지합니다.
- iOS 18에서는 `bottomBar`와 `status` placement를 조합해 중앙 info를 분리하고, 좌측/우측 그룹을 나눠 배치합니다.
- public API 범위 안에서는 Photos 앱의 원형 그룹 버튼을 완전히 동일하게 만들 수 없으므로, 우선순위는 `ToolbarItem` 유지와 3구역 레이아웃 근사입니다.
- 다만 Photos 스타일 integrated scroll surface 전환 후 `UIKitToolbar` hierarchy 경고나 safe area 충돌이 지속되면, 하단 액션은 overlay/safeAreaInset로 되돌리는 fallback을 허용합니다.

### 4. 제목 포맷은 Photos 앱 유사 정책

- 위치가 있으면 1행 위치, 2행 날짜+시간.
- 위치가 없으면 1행 날짜, 2행 시간.
- 날짜는 최근성 기준으로 요일 / `M월 d일` / `yyyy년 M월 d일`로 변환합니다.
- 시간은 시스템 24시간 설정을 따릅니다.

### 5. 편집 기능은 crop-only부터 재검토

- Apple의 `PHContentEditingController`는 Photos 앱이 호스팅하는 편집 extension UI용 프로토콜이므로, 앱 내부에서 시스템 사진 편집 화면을 직접 띄우는 해법으로 보지 않습니다.
- Issue #6에서는 현재 안내 Alert를 유지합니다.
- 앱 내 편집이 필요하면 전체 편집기를 한 번에 만들기보다 GitHub Issue #12에서 crop-only 기능부터 별도 구현합니다.

### 6. 사진/동영상 공통 pager + 타입별 콘텐츠 분리

- 상위 컨테이너는 paging, dismiss, chrome만 담당합니다.
- 실제 콘텐츠는 `ImageDetailContent` / `VideoDetailContent` 성격의 분리된 View로 나누는 편이 유지보수에 유리합니다.

### 8. UIKit은 필요 최소한만 유지

- SwiftUI가 더 단순한 경우 UIKit bridge는 줄입니다.
- 1차 감사 대상은 `ShareSheetView`처럼 단순 래퍼인 코드와 과도하게 뷰 파일에 섞인 UIKit helper입니다.
- `ZoomableImageView`와 low-level player rendering은 현재 UX 요구사항상 UIKit 유지 가능성이 높으므로, 먼저 분리부터 하고 전환 여부는 별도 검증 후 결정합니다.

### 7. Gallery fetch 범위 확장 가능성

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
| 확대 전환이 상세 뷰 내 paging과 함께 동작할 때 dismiss source가 바뀔 수 있음 | 중간 | zoom source는 현재 `currentIndex` 기준 asset id를 사용하고, off-screen 셀인 경우 시스템 fallback을 허용 |
| 동영상 playback controls를 숨긴 상태라 현재 브랜치에서는 재생 제어가 부족함 | 높음 | 커스텀 비디오 플레이어를 별도 Issue로 분리하고 현재는 겹침 제거만 반영 |
| 핀치 기반 열 수 변경 시 썸네일 재요청이 빈번해질 수 있음 | 중간 | 실제 셀 크기 기반 요청으로 정확도를 높이고, preheat는 후속 profiling 범위로 유지 |
| PhotoKit request cancel 시 continuation leak으로 런타임 경고가 날 수 있음 | 높음 | 취소/에러 경로에서도 `nil`로 반드시 resume 되는 래퍼 사용 |
| 전체 페이지가 동시에 고비용 로딩을 시작하면 초기 진입/스와이프가 무거워짐 | 높음 | 현재 페이지와 인접 페이지만 우선 로드하고 캐시 재사용 |
| `ToolbarItem` 기반 상세 chrome이 `fullScreenCover`/hosting hierarchy와 충돌할 수 있음 | 높음 | `UIKitToolbar` 경고 재현 조건을 좁히고, 필요 시 overlay chrome 또는 presentation 구조 재조정 |
| 위치 문자열 reverse geocoding이 느릴 수 있음 | 중간 | 좌표 fallback과 캐시를 두고, top bar는 placeholder에서 점진 업데이트 |
| 지오코딩 결과가 지역마다 다른 깊이로 내려와 세부 위치 문자열 품질이 들쭉날쭉할 수 있음 | 높음 | `administrativeArea/locality/subLocality/name/thoroughfare` 조합 규칙과 중복 제거 규칙을 명시 |
| vertical scroll + horizontal paging + zoom 제스처가 서로 충돌할 수 있음 | 높음 | scroll snap 대상은 화면 전체가 아닌 상위 surface로 제한하고, zoom 중에는 vertical snap 반응을 줄이는 정책을 명시 |
| details section이 실제 scroll content가 되면 expanded metadata/map 로딩이 첫 진입 성능에 영향을 줄 수 있음 | 중간 | summary는 즉시, 무거운 metadata와 map은 details section 근처에서 lazy load |
| title용 위치 메타데이터를 늦게 채우면 상단 principal title이 진입 직후 버벅여 보일 수 있음 | 높음 | title용 최소 요약 데이터는 preload하거나, fallback 문자열/고정 레이아웃으로 재배치를 줄임 |
| 촬영 기기 메타데이터가 편집본, 다운로드본, 일부 비디오에서 비어 있을 수 있음 | 중간 | 메타데이터 추출 실패 시 "정보 없음" fallback을 허용하고 UX에 반영 |
| 소속 앨범 조회가 많아지면 상세정보 시트 진입 시 지연이 생길 수 있음 | 중간 | 현재 asset 기준 필요한 시점에만 조회하고 결과 캐시를 검토 |
| 사용자의 24시간 설정 / 한국어 표기 규칙이 formatter 구현과 어긋날 수 있음 | 중간 | `Date.FormatStyle` 또는 locale-aware formatter를 사용하고 실기기/시뮬레이터 검증 |
| `NavigationStack`를 full-screen 뷰어 내부에 추가하면서 기존 presentation/navigation transition과 상호작용 차이가 생길 수 있음 | 중간 | 실제 진입/종료 애니메이션과 toolbar 동작을 시뮬레이터에서 수동 확인 |
| inline 정보 패널의 drag gesture가 paging / zoom / dismiss 제스처와 충돌할 수 있음 | 높음 | 수직 drag 임계값을 두고, 패널 open/close와 일반 미디어 탐색 제스처를 분리 검증 |

---

## Success Criteria

- [x] `MediaDetailFeature` / `MediaDetailView`가 사진과 동영상을 모두 처리함
- [x] `GalleryView`와 `AlbumPhotoGridView`에서 같은 뷰어를 재사용함
- [x] 사진 pinch-to-zoom이 동작함
- [x] 동영상 재생이 정상 동작함
- [x] 좌우 스와이프로 이전/다음 미디어 이동이 가능함
- [x] Swift 6 strict concurrency 경고 없이 빌드됨
- [x] iOS 18 zoom transition 기반 상세 진입이 코드상 연결됨
- [x] 갤러리/앨범 그리드에서 핀치로 열 수를 2~6 범위에서 조절할 수 있음
- [x] 썸네일 요청이 실제 셀 크기를 기준으로 이뤄짐
- [x] 썸네일 로딩 시 asset 재조회 감소가 반영됨
- [x] 사진 더블 탭 확대/축소가 코드상 연결됨
- [x] 상세 뷰 배경이 탭으로 `systemBackground` / black 전환 가능함
- [x] 상단/하단 chrome 초안이 현재 asset 메타데이터와 액션을 표시함
- [ ] 최초 진입 직후 사진이 별도 확대/축소 상호작용 없이도 Y축 중앙 정렬됨
- [x] 상단/하단 chrome이 커스텀 capsule/circle 대신 기본 SwiftUI 요소로 정리됨
- [x] 위치 표기가 가능한 경우 `시/도 - 동/가/세부지명` 수준까지 더 자세히 표시됨
- [x] 중앙 타이틀이 위치/날짜/시간을 Photos 앱 유사 규칙으로 2줄 표시함
- [x] inline 정보 패널이 날짜+시간, 파일명, 촬영 기기, 위치, 소속 앨범을 표시할 데이터 경로를 사용함
- [x] 편집 액션 정책이 확정됨: Issue #6에서는 안내 Alert 유지, 실제 crop-only 편집은 GitHub Issue #12에서 처리
- [ ] 진입/종료 및 mixed media 전환이 시뮬레이터에서 확인됨
- [ ] immersive 전환 시 chrome fade와 safe-area-aware viewport 확장/축소가 체감상 자연스럽게 동작함
- [ ] 위로 스와이프하는 inline 정보 패널이 reference UX와 비슷한 흐름으로 동작함

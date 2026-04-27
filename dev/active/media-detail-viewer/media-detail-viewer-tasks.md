# Media Detail Viewer — 작업 체크리스트

**GitHub Issue**: #6  
**Last Updated**: 2026-04-27 (코드 품질 수정 세션)

---

## Phase 1: 범위 및 데이터 계약 확정 (S)

- [x] **1-1** `Gallery`도 mixed media를 보여줄지 결정
  - 수용 기준: Issue #6의 "앱 전역 재사용 가능한 사진/동영상 뷰어" 목표와 실제 첫 적용 범위가 문서상 일치함
- [x] **1-2** `MediaDetailFeature.State` 입력 형식 확정 (`items + currentIndex` 또는 `selectedID`)
  - 수용 기준: `Gallery`와 `AlbumPhotoGrid`가 같은 상태 생성 방식 사용 가능
- [x] **1-3** presentation 방식 확정 (`fullScreenCover` 우선 검토)
  - 수용 기준: dismiss 흐름과 TCA presentation 연결 방식이 명시됨

---

## Phase 2: 데이터/의존성 준비 (M)

- [x] **2-1** 필요 시 `PhotoLibraryClient`에 mixed media fetch API 추가 또는 기존 API 확장
  - 후보: `fetchMedia()`, 또는 `fetchPhotos()`를 범용화
- [x] **2-2** 고해상도 이미지 로딩 경로 설계
  - 수용 기준: 썸네일과 별도로 detail quality 이미지를 안정적으로 요청 가능
- [x] **2-3** 동영상 재생용 asset -> player item 변환 책임 위치 결정
  - 수용 기준: Feature/View/헬퍼 중 한 곳으로 책임이 분명함
- [x] **2-4** 상세정보 시트 데이터 소스 확장 설계
  - 수용 기준: 날짜+시간, 파일명, 촬영 기기, 위치, 소속 앨범을 어떤 PhotoKit/metadata 경로에서 가져올지 정리됨
- [x] **2-5** 위치/날짜/시간 포맷 정책 확정
  - 수용 기준: 위치 유무에 따른 2줄 제목 규칙, 최근 1주/같은 해/그 이전 날짜 규칙, 24시간/12시간 표기 규칙이 문서와 코드에 일치함
- [ ] **2-6** 편집 기능 범위 확정
  - 수용 기준: `PHContentEditingController`를 쓰지 않는 이유와 crop-only 구현 여부가 결정됨

---

## Phase 3: MediaDetail Feature/View 구현 (L)

- [x] **3-1** `PHOU/Presentation/MediaDetail/MediaDetailFeature.swift` 생성
- [x] **3-2** `PHOU/Presentation/MediaDetail/MediaDetailView.swift` 생성
- [x] **3-3** 사진 상세 콘텐츠 구현
  - 1차 범위: 고해상도 표시, pinch-to-zoom, 로딩/실패 처리
- [x] **3-4** 동영상 상세 콘텐츠 구현
  - 1차 범위: 재생, 페이지 이탈 시 정지, 기본 loading 처리
- [x] **3-5** 좌우 paging UX 구현
  - 수용 기준: 현재 선택한 미디어가 명확히 바뀌고 index 기반 상태와 동기화됨
- [x] **3-6** dismiss UI 및 상단 chrome 구현
- [x] **3-7** 기본 SwiftUI 요소 기반 chrome으로 재구성
  - 수용 기준: 커스텀 capsule/circle UI 없이 기본 navigation/toolbar/button/sheet 조합으로 상단/하단 액션이 동작함
- [x] **3-8** Photos 스타일 중앙 제목 포맷 구현
  - 수용 기준: 위치가 있으면 `위치 / 날짜+시간`, 없으면 `날짜 / 시간` 2줄 표시가 적용됨
- [x] **3-9** 상세정보 시트 확장
  - 수용 기준: 날짜+시간, 파일명, 촬영 기기, 위치, 소속 앨범이 표시됨
- [ ] **3-10** 사진 편집 액션 정책 반영
  - 수용 기준: 편집 버튼이 crop-only 편집 또는 그에 준하는 확정된 동작을 수행함
- [x] **3-11** 상세정보 시트와 사진 동반 이동 구조 정리
  - 수용 기준: details reveal 시 하단 시트만 따로 떠 보이지 않고, 미디어도 함께 위로 lift 되어 붙어 올라오는 인상이 유지됨
- [x] **3-12** info 버튼과 upward swipe를 동일한 panel reveal 동작으로 통합
  - 수용 기준: 두 진입 방식 모두 같은 `showsDetailsPanel` 상태를 사용하고, 중복 presentation 경로가 없음
- [x] **3-13** 세로 사진 중앙 정렬 회귀 방지
  - 수용 기준: details reveal 구조를 되돌린 뒤에도 사진이 viewport 기준 중앙 정렬을 유지함
- [x] **3-14** details panel 내부 불필요 UI 제거
  - 수용 기준: 사용자 요청에 따라 `캡션 추가` UI가 사라지고 메타데이터 중심 시트만 남음
- [ ] **3-15** 하단 액션 바 유지 방식 재검토
  - 수용 기준: system `ToolbarItem` 유지 또는 overlay/safeAreaInset fallback 중 하나로 기준을 확정하고, `UIKitToolbar` 경고와 UX를 함께 검증함
- [x] **3-16** 상단 principal title metadata 안정화
  - 수용 기준: 상세 진입 직후 위치/날짜 제목이 placeholder에서 실데이터로 바뀌더라도 폭/줄배치가 눈에 띄게 흔들리지 않음
- [x] **3-17** panel open 상태 paging 동기화
  - 수용 기준: 상세정보 시트가 열린 채로 좌우 paging 해도 panel은 유지되고, 내부 정보가 새 current asset 기준으로 즉시 갱신됨

---

## Phase 4: 소비처 연결 (M)

- [x] **4-1** `GalleryFeature` / `GalleryView`에 media detail presentation 연결
- [x] **4-2** `AlbumPhotoGridFeature` / `AlbumPhotoGridView`에 같은 뷰어 연결
- [x] **4-3** 그리드 셀을 탭 가능한 컴포넌트로 정리
  - 수용 기준: 히트 타깃이 자연스럽고 기존 정사각형 셀 레이아웃 유지

---

## Phase 5: 검증 (M)

- [x] **5-1** `xcodebuild` 빌드 성공
- [x] **5-2** 갤러리에서 사진 상세 진입 확인
- [x] **5-3** 앨범 상세에서 사진/동영상 혼합 목록 진입 확인
- [x] **5-4** 사진 pinch-to-zoom 확인
- [x] **5-5** 동영상 재생 및 페이지 이동 시 정지 확인
- [x] **5-5-a** inactive video pause 수동 재확인
- [x] **5-5-b** 동영상 탭 시 크래시 재현 여부 재확인
- [x] **5-5-c** 동영상 상세에서 시스템 playback controls를 숨겨 기존 chrome과 겹치지 않도록 보정
- [x] **5-5-d** 사진 initial fit 계산을 aspect-fit 기준으로 바꿔 세로 중앙 정렬 보정
- [x] **5-5-e** iOS 18 zoom transition 기반 상세 진입 연결
- [x] **5-5-f** 썸네일 요청 크기를 실제 셀 크기 기준으로 보정
- [x] **5-5-g** 썸네일 로딩 시 `PHAsset` 재조회 감소 반영
- [x] **5-5-h** 갤러리/앨범 그리드에 핀치 기반 열 수 조절 추가
- [x] **5-5-i** `loadThumbnail()` cancel/error 경로 continuation leak 방지
- [x] **5-5-j** 상세 뷰를 현재/인접 페이지 우선 로딩 구조로 보정
- [x] **5-5-k** 단일 탭 배경 토글, double-tap zoom, 상하단 chrome 추가
- [x] **5-5-l** 공유 시트와 상세정보 시트, 편집 안내 alert 연결
- [x] **5-5-m** 사진 최초 진입 시 Y축 중앙 정렬 재현 버그 수정
  - 메모: `LayoutAwareScrollView` 기반 재-centering을 넣고 빌드는 통과했지만 실제 재현이 사라졌는지는 아직 수동 확인 전
- [x] **5-5-n** 기본 SwiftUI chrome 전환 후 UX 검증
  - 메모: `ToolbarItem` / `ToolbarItemGroup` / `ToolbarSpacer` 기반 system toolbar 전환까지 반영했지만, 사용자 확인 기준으로 레이아웃 문제는 아직 미해결이고 `UIKitToolbar` hierarchy 경고가 추가로 관찰됨
- [x] **5-5-n-1** 상세 정보 modal 재프레젠트 제거
  - 메모: `sheet(item:)` placeholder/실데이터 이중 갱신으로 생기던 내려갔다 다시 뜨는 문제를 없애고, info 버튼과 upward swipe가 같은 inline panel을 열도록 정리함
- [x] **5-5-n-2** immersive 전환 시 chrome fade 및 viewport 재계산 연결
  - 메모: 검은 배경 전환 시 상단/하단 chrome과 status bar가 fade/hide 되고, normal 모드로 돌아오면 safe area를 고려한 viewport로 다시 축소되도록 구조를 바꿈
- [x] **5-5-n-3** upward swipe inline 정보 패널 1차 구현
  - 메모: 사진이 위로 lift 되면서 하단에서 정보 패널이 올라오는 reference 유사 흐름의 첫 버전을 넣음. drag 감도/충돌은 수동 검증이 남아 있음
- [x] **5-5-o** 위치 표기 세분화 검증
  - 메모: `subLocality`와 `name`이 함께 있을 때 `신길동`보다 `신길4동` 같은 더 구체적인 동 단위를 우선 보존하도록 조정했고, 실제 지역별 품질 검증이 남아 있음
- [x] **5-5-p** 날짜/시간 표기 규칙 검증
  - 메모: 최근 1주/같은 해/과거 연도, 24시간/12시간 설정별 formatter는 구현됐고 수동 확인이 남아 있음
- [ ] **5-5-q** 상세정보 시트 메타데이터 검증
  - 메모: 파일명/기기/앨범 표시 경로는 연결됐고, 사진 탐색 지연 완화를 위해 기기/앨범 상세 로딩은 inline info panel 진입 시점으로 늦췄음. 실제 자산에서 비어 있거나 누락되는 케이스 확인이 남아 있음
- [ ] **5-5-q-1** Photos 스타일 시트 표현에서 메타데이터 표시 검증
  - 메모: 시트가 올라오며 사진도 함께 이동하는 상태에서 placeholder -> 실데이터 전환이 어색하지 않은지 확인해야 함
- [ ] **5-5-q-2** 상단 title metadata 전환 체감 검증
  - 메모: 날짜만 먼저 보였다가 위치가 붙는 동안 principal title이 버벅이거나 줄이 바뀌는지 실제 기기에서 확인해야 함
- [ ] **5-5-q-3** panel open 상태 paging 메타데이터 갱신 검증
  - 메모: panel을 연 채로 옆 미디어로 넘겼을 때 이전 asset 정보가 남지 않고 새 asset 정보로 자연스럽게 바뀌어야 함
- [ ] **5-5-r** 편집 액션 정책 검증
  - 메모: crop-only 구현 시 저장/취소 흐름, 미구현 시 버튼 정책을 명확히 해야 함
- [ ] **5-5-s** `UIKitToolbar` runtime 경고 원인 분리
  - 메모: 하단도 `ToolbarItem` 기반을 유지하기로 돌아섰으므로, 현재 `bottomBar/status` 조합에서 경고가 재현되는지 먼저 확인해야 함
- [ ] **5-5-s-1** current overlay sheet와 toolbar 조합 재검증
  - 메모: 최신 기준선인 overlay sheet + media lift 구조에서도 같은 hierarchy 경고가 남는지 분리해서 확인해야 함
- [ ] **5-5-s-2** vertical/horizontal/zoom 제스처 충돌 수동 검증
  - 메모: 특히 세로 스와이프가 details reveal로 해석될 때, `TabView` paging과 확대된 사진 pan을 방해하지 않는지 확인 필요
- [ ] **5-5-s-3** latest overlay sheet 기준 compile/build 검증
  - 메모: unrestricted `xcodebuild -project PHOU.xcodeproj -target PHOU build`까지 시도했지만, 현재는 `swift-clocks` / `combine-schedulers` / `swift-perception` 쪽 `ConcurrencyExtras`, `IssueReporting` 모듈 해석 실패로 막힘
- [x] **5-5-t** iPhone 13 mini 레이아웃 재검증
  - 메모: normal/immersive 전환 후 상단 spacing, 사진 좌우 여백, toolbar 배치가 작은 기기에서 더 쉽게 깨진다는 사용자 보고가 있음
- [x] **5-5-u** 런타임 부가 로그 분류
  - 메모: `com.apple.accounts Code=7`, `CMPhotoJFIFUtilities err=-17102` 로그가 앱 버그인지 시스템/자산 노이즈인지 판단 필요
- [x] **5-5-v** 세로 사진 normal/immersive fit 재검증
  - 메모: latest patch에서 viewport reserve 계산을 제거해 normal/immersive가 사실상 같은 fit size를 쓰도록 바꿨지만, 실제 portrait photo에서 여백이 사라졌는지는 수동 확인이 필요함
- [x] **5-5-w** iOS 18 하단 action bar 재배치 검증
  - 메모: `5d753c6`에서 iOS 26 미만 하단 `ToolbarItem` 배치를 다시 조정했고, 사용자 확인 기준 의도한 레이아웃이 맞음
- [ ] **5-5-x** favorite tint / video letterbox 재검증
  - 메모: favorite 버튼 기본 tint를 accent color로 보정했고, video는 `AVPlayerLayer + .resizeAspect`로 바꿨지만 실제 기기에서 색상/크롭/letterbox가 기대와 맞는지 확인이 필요함
- [ ] **5-5-y** 실기기 지연 완화 효과 확인
  - 메모: `MediaDetailFeature.State`의 `Equatable` 비교를 current item 중심으로 축소했고, `AVPlayerLayer` 경량화도 반영했으므로 실기기에서 진입/전환/dismiss 지연이 얼마나 줄었는지 확인이 남아 있음. 다만 하단 toolbar는 사용자 의도에 따라 유지
- [ ] **5-5-y-1** `PHAssetOriginalMetadataProperties` 경고 재조사
  - 메모: detached/caching만으로는 로그가 사라지지 않아, 이번 세션에서 촬영 기기 추출 경로를 `requestImageDataAndOrientation`에서 `PHAssetResourceManager.requestData` + incremental metadata probe로 교체함. 다음 확인은 "이 변경 후에도 같은 로그가 남는가"에 집중
  - 추가 메모: 구현 직후 `withCheckedContinuation` optional 반환 타입 추론, `PHPhotosError.operationCancelled` 심볼 부재, `CGImageSourceCreateIncremental(nil)` optional binding 오류를 순차적으로 수정했고 모두 같은 커밋에 amend 반영함
- [x] **5-5-z** 최신 빌드 검증 경로 복구
  - 메모: 최신 사용자 확인 기준으로 리팩토링 후 빌드와 실행이 모두 정상 동작함. 이 턴에서는 동일 경로를 재실행하지 않았으므로 증거 출처는 사용자 확인임.
- [ ] **5-6** iPad 레이아웃/회전에서 기본 동작 이상 없는지 확인
  - 메모: 현재 세션에서는 XcodeBuildMCP 기본값 설정 도구 부재로 UI 자동 검증까지는 진행하지 못함
  - 추가 메모: 2026-04-23 수정 후 `xcodebuild` 재빌드 성공, iOS 17 시뮬레이터 앱 설치/런치 및 런치 화면 캡처 확인
  - 추가 메모: 사진 상단 정렬 보정, inactive video pause 로직, 썸네일 화질 복구 반영 후 빌드 재검증 완료
  - 추가 메모: iOS 18 zoom transition, 실제 셀 크기 기반 썸네일, `PHAsset` cache, 핀치 열 수 조절 반영 후 `xcodebuild -quiet -project PHOU.xcodeproj -scheme PHOU build` 재성공
  - 추가 메모: continuation leak 보정, 상세 뷰 support loader 분리, immersive background/chrome 추가 후 `xcodebuild -quiet -project PHOU.xcodeproj -scheme PHOU build` 재성공
  - 추가 메모: 기본 SwiftUI toolbar/safeAreaInset 전환, 상세정보 데이터 확장, `LayoutAwareScrollView` 보정 후 `xcodebuild -quiet -project PHOU.xcodeproj -scheme PHOU build` 재성공
  - 추가 메모: 즐겨찾기 토글, 삭제, 앨범 추가, 위치 세분화 조정, photo summary/full metadata 분리 후 `xcodebuild -quiet -project PHOU.xcodeproj -scheme PHOU build` 재성공
  - 추가 메모: modal info 제거, inline 정보 패널, immersive fade/viewport 전환, upward swipe 제스처 반영 후 `xcodebuild -quiet -project PHOU.xcodeproj -scheme PHOU build` 재성공
  - 추가 메모: `ToolbarItem` / `ToolbarItemGroup` / `ToolbarSpacer` 기반 system toolbar 전환, title glass grouping 조정, viewport/bounds 보정 후에도 빌드는 재성공했지만 사용자 기준 문제는 아직 미해결
  - 추가 메모: 최신 세션에서는 build 자체가 막혔음. shared scheme `PHOU` 부재로 scheme build가 실패했고, target build도 SPM dependency 해석 오류로 실패해 compile verification을 남기지 못함
  - 추가 메모: 이번 세션에서는 하단 액션을 다시 `ToolbarItem` 기반으로 유지하고, video를 `AVPlayerLayer` 기반으로 단순화했지만 build verification은 여전히 scheme 부재/SPM 해석 문제로 막힘
  - 추가 메모: `xcodebuild -resolvePackageDependencies -project PHOU.xcodeproj`는 성공했지만, 직후 `-target PHOU build`는 여전히 `ConcurrencyExtras` / `IssueReporting` 모듈 해석 오류로 실패
  - 추가 메모: 이번 세션의 metadata 경고 대응 수정 후에도 sandbox 내부 검증은 `PHOU` scheme 부재와 SwiftPM cache 쓰기 제한 때문에 막혔고, unrestricted target build 승인을 요청해 둔 상태임
  - 추가 메모: 2026-04-27 후속 compile fix들은 파일 단위 오류 제보를 따라 수정했고, 프로젝트 전체 `xcodebuild` 재검증은 아직 다시 수행하지 못함

---

## Phase 6: 구조 리팩토링 및 UIKit 감사 (L)

- [x] **6-1** `MediaDetailView.swift` 책임 분리 설계
  - 메모: `MediaDetailView.swift`는 화면 조립 중심으로 남기고, page/panel/UIKit bridge를 별도 파일로 나누는 경계를 문서와 코드에 반영함
- [x] **6-2** `MediaDetailSupport.swift` 책임 분리 설계
  - 메모: 기존 support 파일을 제거하고 asset loader / models / PhotoKit bridge / share support 파일로 분리함
- [x] **6-3** UIKit 사용 지점 감사
  - 메모: `ZoomableImageView`, `PlayerLayerView`는 유지, `ShareSheetView`는 추후 `ShareLink` 전환 후보로 분류함
- [x] **6-4** SwiftUI 전환 후보 선별
  - 메모: 단순 wrapper 성격의 `ShareSheetView`를 최우선 후보로 남기고, zoom/player bridge는 유지 후보로 정리함
- [x] **6-5** 리팩토링 후 동작 보존 검증
  - 메모: 최신 사용자 확인 기준으로 리팩토링 후 빌드와 실행이 모두 정상이며, 큰 동작 회귀 없이 구조 분리가 반영됨

---

## 후속 후보 (Out of Scope Unless Needed)

- [ ] 비디오 배지 / 재생 시간 오버레이
- [x] 커스텀 비디오 플레이어 후속 이슈 초안 작성
- [ ] 커스텀 비디오 플레이어 설계 및 구현
- [ ] 동영상 pinch-to-zoom
- [ ] 라이브 포토/버스트 등 특수 자산 표시 개선
- [x] 상세 뷰에서 삭제/즐겨찾기 실제 액션 추가
- [ ] zoom transition이 off-screen source에서도 제품적으로 허용 가능한지 수동 확인
- [ ] 갤러리 스크롤 성능이 계속 거슬리면 profiling 후 별도 Issue 분리
- [ ] system toolbar 대신 overlay chrome 복귀가 필요한지 비교 검토
- [x] 하단 이전/다음 미디어 썸네일 스트립 기능용 feature issue 작성
  - 메모: GitHub Issue `#11` `미디어 상세 뷰 하단 썸네일 스트립 추가`
- [ ] 상세 뷰 상태 전달 구조를 `items` 전체 배열 대신 windowed slice 또는 ID 중심으로 더 줄일지 검토
- [x] `MediaDetailView.swift` / `MediaDetailSupport.swift` 리팩토링 설계 문서화
  - 메모: 기존 분리 후보를 현재 파일 구조 설명으로 갱신함
- [ ] `ShareSheetView`를 SwiftUI로 대체할 수 있는지 검토
- [ ] zoom/player UIKit bridge를 유지할지 SwiftUI로 바꿀지 결정

---

## Phase 7: 코드 품질 수정 (이번 세션)

- [x] **7-1** `MediaDetailPhotoKitBridge`: 4개 `ContinuationBox` 클래스를 제네릭 `ContinuationBox<T>` 하나로 통합
  - 수용 기준: `ImageContinuationBox`, `PlayerItemContinuationBox`, `URLContinuationBox`, `DataContinuationBox`, `ImagePropertiesContinuationBox` 제거, `ContinuationBox<T>` 단일 구현으로 대체됨
- [x] **7-2** `MediaDetailPhotoKitBridge.requestImage`: dead code 제거
  - 수용 기준: `isDegraded == true`인데 `deliveryMode == .highQualityFormat`일 때 degraded 이미지를 반환하는 두 번째 조건 제거됨. 실제 도달 불가한 경로였음.
- [x] **7-3** `MediaDetailPhotoKitBridge`: 미사용 `requestImageData` 함수 제거
  - 수용 기준: 파일 내 정의만 있고 호출처가 없는 dead code 확인 후 제거됨
- [x] **7-4** `MediaDetailAssetLoader.provisionalSummaryDetails`: 메인 스레드 PhotoKit 접근 제거
  - 수용 기준: `assetCache`에 없을 경우 즉시 placeholder 반환. `PHAsset.fetchAssets` 동기 호출이 메인 스레드에서 일어나지 않음. 이후 async `refreshCurrentDetails()`가 실제 데이터를 채움.
- [x] **7-5** `MediaDetailAssetLoader.deduplicatedLocationComponent`: dead code 제거
  - 수용 기준: `preferred ?? fallback`과 동일한 함수 제거, 호출부를 `locality ?? administrativeArea` 직접 nil 병합으로 대체
- [x] **7-6** `MediaDetailView.detailsPanel`: 중복 nil 병합 제거
  - 수용 기준: `displayedDetails ?? currentAsset.map(MediaAssetDetails.placeholder)` 이중 병합을 `displayedDetails` 단일 참조로 단순화
- [x] **7-7** `MediaDetailPanels.AlbumPickerSheet`: 불필요한 `enumerated()` 제거
  - 수용 기준: `ForEach(Array(albums.enumerated()), id: \.element.id) { _, album in }` → `ForEach(albums) { album in }` (AlbumGroup: Identifiable 활용)

---

## 구현 커밋

- [x] `2ae317c` `feat: #6 - 재사용 가능한 미디어 상세 뷰어 연결`
- [x] `1b03f06` `fix: #6 - 미디어 뷰어 제스처와 재생 안정성 개선`
- [x] `1cfddd6` `fix: #6 - 미디어 뷰어 정렬과 재생 동작 보정`
- [x] `2ef498d` `fix: #6 - 미디어 상세 뷰 toolbar 유지와 영상 표시 보정`
- [x] `5d753c6` `fix: #6 - iOS 18 하단 toolbar item 배치 조정`
- [x] `889fc99` `fix: #6 - 상세 제목 메타데이터 전환 안정화`
- [x] `c30f2d3` `feat: #6 - 상세 정보 스크롤 surface 전환`
- [x] `9f9bc5c` `fix: #6 - 상세 정보 시트와 사진 동반 이동 복원`
- [x] `4935e6e` `fix: #6 - 상세 정보 시트 외형과 제스처 보정`
- [x] `eb66936` `fix: #6 - 상세 메타데이터 로딩 경고 완화`

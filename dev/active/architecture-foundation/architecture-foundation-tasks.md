# Architecture Foundation — Task Checklist

Last Updated: 2026-04-22

---

## Phase 1 — 폴더 구조 & Domain 엔티티 (S)

- [ ] **1-1** 폴더 생성: `Domain/Entity/`, `Domain/Interface/`, `Domain/UseCase/`
- [ ] **1-2** 폴더 생성: `Data/Client/`, `Data/Repository/`
- [ ] **1-3** 폴더 생성: `Presentation/App/`, `Presentation/Gallery/`, `Presentation/Components/`
- [ ] **1-4** 폴더 생성: `Core/Extension/`
- [ ] **1-5** `PhotoAsset.swift` 작성 — `Identifiable, Equatable, Sendable` 준수, `MediaType` 중첩 enum 포함
- [ ] **1-6** `AlbumGroup.swift` 작성 — `Identifiable, Equatable, Sendable` 준수, `AlbumType` 중첩 enum 포함
- [ ] **1-7** 빌드 확인 — `xcodebuild` 에러 없음

---

## Phase 2 — PhotoLibraryClient (M)

- [ ] **2-1** `PhotoLibraryClient.swift` 작성 — `@DependencyClient` 매크로 적용
  - `requestAuthorization: @Sendable () async -> PHAuthorizationStatus`
  - `fetchPhotos: @Sendable () async throws -> [PhotoAsset]`
  - `fetchAlbums: @Sendable () async throws -> [AlbumGroup]`
  - `deleteAssets: @Sendable (_ ids: [String]) async throws -> Void`
- [ ] **2-2** `liveValue` 구현 — `PHPhotoLibrary` 권한 요청 + `PHFetchResult` → `[PhotoAsset]` 변환
- [ ] **2-3** `previewValue` 구현 — 하드코딩 Mock 데이터 (5~10개)
- [ ] **2-4** `testValue` 구현 — `unimplemented` 또는 빈 응답
- [ ] **2-5** `DependencyValues` extension 추가
- [ ] **2-6** `Info.plist`에 `NSPhotoLibraryUsageDescription` 추가
- [ ] **2-7** `Info.plist`에 `NSPhotoLibraryAddUsageDescription` 추가
- [ ] **2-8** Swift 6 Sendable 경고 없음 확인

---

## Phase 3 — AppFeature & 루트 뷰 교체 (M)

- [ ] **3-1** `GalleryFeature.swift` — 빈 stub (`State: Equatable`, `Action`, Reduce 뼈대)
- [ ] **3-2** `AppFeature.swift` 작성 — `Tab` enum, `GalleryFeature` scope 포함
- [ ] **3-3** `AppView.swift` 작성 — `TabView`, `@Bindable var store: StoreOf<AppFeature>`
- [ ] **3-4** `PHOUApp.swift` 수정 — `Store<AppFeature.State, AppFeature.Action>` 생성, `AppView` 렌더링
- [ ] **3-5** `ContentView.swift` 삭제 (또는 비워두기)
- [ ] **3-6** 빌드 + 시뮬레이터 실행 — 탭 바 표시 확인

---

## Phase 4 — GalleryFeature 완성 (L)

- [ ] **4-1** `GalleryFeature.State` 정의
  - `authorizationStatus: PHAuthorizationStatus`
  - `photos: [PhotoAsset]`
  - `isLoading: Bool`
  - `error: String?`
- [ ] **4-2** `GalleryFeature.Action` 정의 — `view(ViewAction)`, `internal(InternalAction)` 분리
- [ ] **4-3** Reducer `body` 구현
  - `.view(.onAppear)` → 권한 요청 Effect
  - 권한 허가 → 사진 로드 Effect
  - `InternalAction` 응답 처리
- [ ] **4-4** `GalleryView.swift` 작성
  - `LazyVGrid` 3열 그리드
  - 권한 없음 상태 분기 뷰
  - `ProgressView` 로딩 오버레이
- [ ] **4-5** `PhotoThumbnailView.swift` 컴포넌트 작성
  - `PHImageManager` 기반 썸네일 로드
  - `onAppear`/`onDisappear` 요청 취소 처리
- [ ] **4-6** 실기기 or 시뮬레이터에서 사진 표시 확인
- [ ] **4-7** 권한 거부 시나리오 테스트
- [ ] **4-8** (선택) Instruments로 메모리 누수 확인

---

## Phase 5 — 앨범 탭 Stub (S)

- [ ] **5-1** `AlbumFeature.swift` — 최소 stub (빈 State, Action, Reducer)
- [ ] **5-2** `AlbumView.swift` — "앨범 준비 중" 텍스트 뷰
- [ ] **5-3** `AppFeature`에 `AlbumFeature` Scope 추가
- [ ] **5-4** `AppView`에 앨범 탭 추가
- [ ] **5-5** 전체 빌드 + 탭 전환 확인

---

## 완료 기준 (Definition of Done)

- [ ] `xcodebuild` 에러 0개, 경고 최소화
- [ ] 갤러리 탭에서 사진 그리드 표시
- [ ] 권한 미허가 시 안내 UI 표시
- [ ] `previewValue`로 `#Preview` 정상 동작
- [ ] Swift 6 strict concurrency 위반 없음

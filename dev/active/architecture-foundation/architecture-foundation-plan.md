# PHOU — Architecture Foundation Plan (Option A)

Last Updated: 2026-04-22

## Executive Summary

TCA + Clean Architecture 기반의 폴더 구조와 핵심 Dependency를 먼저 확립한 뒤, 갤러리 탭 Feature를 end-to-end로 구현한다. `@Dependency` 없이 Feature를 먼저 만들면 PhotoKit 권한 처리와 추상화가 엉켜 나중에 전면 리팩토링이 필요해진다. 처음부터 올바른 레이어 경계를 잡는 것이 목표다.

---

## Current State

| 항목 | 상태 |
|------|------|
| Xcode 프로젝트 | ✅ 생성됨 (`PHOU.xcodeproj`) |
| TCA 의존성 | ✅ ComposableArchitecture ≥ 1.24.1 추가됨 |
| 소스 파일 | `PHOUApp.swift`, `ContentView.swift` 두 개뿐 |
| 폴더 구조 | ❌ Domain/Data/Presentation/Core 없음 |
| PhotoKit 연동 | ❌ 없음 |
| TCA Feature | ❌ 없음 |

**중요**: `PBXFileSystemSynchronizedRootGroup` 방식 → `PHOU/` 하위에 파일/폴더를 추가하면 pbxproj 수정 없이 자동으로 빌드에 포함됨.

---

## Proposed Future State

```
PHOU/
├── Domain/
│   ├── Entity/
│   │   ├── PhotoAsset.swift
│   │   └── AlbumGroup.swift
│   ├── Interface/
│   │   └── PhotoLibraryRepositoryInterface.swift
│   └── UseCase/
│       └── FetchPhotosUseCase.swift
├── Data/
│   ├── Client/
│   │   └── PhotoLibraryClient.swift          ← TCA @Dependency
│   └── Repository/
│       └── PhotoLibraryRepository.swift
├── Presentation/
│   ├── App/
│   │   ├── AppFeature.swift                  ← Root Reducer (탭 바)
│   │   └── AppView.swift
│   ├── Gallery/
│   │   ├── GalleryFeature.swift
│   │   └── GalleryView.swift
│   └── Components/
│       └── PhotoThumbnailView.swift
├── Core/
│   └── Extension/
│       └── PHAsset+Extension.swift
├── PHOUApp.swift                             ← Store 주입
└── ContentView.swift                         ← 삭제 예정
```

---

## Implementation Phases

### Phase 1 — 폴더 구조 & Domain 엔티티 (Effort: S)

**목표**: 빌드에 영향 없는 폴더와 핵심 엔티티를 먼저 만든다.

#### 1-1. 폴더 생성
- `PHOU/Domain/Entity/`
- `PHOU/Domain/Interface/`
- `PHOU/Domain/UseCase/`
- `PHOU/Data/Client/`
- `PHOU/Data/Repository/`
- `PHOU/Presentation/App/`
- `PHOU/Presentation/Gallery/`
- `PHOU/Presentation/Components/`
- `PHOU/Core/Extension/`

**수락 기준**: Xcode에서 파일 네비게이터에 모든 그룹이 표시되고, 빌드 성공.

#### 1-2. `PhotoAsset` 엔티티
```swift
// Domain/Entity/PhotoAsset.swift
import Foundation

struct PhotoAsset: Identifiable, Equatable, Sendable {
    let id: String          // PHAsset.localIdentifier
    let creationDate: Date?
    let isFavorite: Bool
    let mediaType: MediaType

    enum MediaType: Equatable, Sendable {
        case image, video, unknown
    }
}
```
**수락 기준**: `Sendable`, `Equatable` 준수, 외부 프레임워크 import 없음.

#### 1-3. `AlbumGroup` 엔티티
```swift
// Domain/Entity/AlbumGroup.swift
import Foundation

struct AlbumGroup: Identifiable, Equatable, Sendable {
    let id: String          // PHAssetCollection.localIdentifier
    let title: String
    let assetCount: Int
    let albumType: AlbumType

    enum AlbumType: Equatable, Sendable {
        case smartAlbum, userAlbum
    }
}
```

---

### Phase 2 — PhotoLibraryClient (TCA Dependency) (Effort: M)

**목표**: PhotoKit 접근을 TCA `@Dependency`로 완전히 캡슐화한다.

#### 2-1. `PhotoLibraryClient` 정의
```swift
// Data/Client/PhotoLibraryClient.swift
import ComposableArchitecture
import Photos

@DependencyClient
struct PhotoLibraryClient: Sendable {
    var requestAuthorization: @Sendable () async -> PHAuthorizationStatus = { .notDetermined }
    var fetchPhotos: @Sendable () async throws -> [PhotoAsset] = { [] }
    var fetchAlbums: @Sendable () async throws -> [AlbumGroup] = { [] }
    var deleteAssets: @Sendable (_ ids: [String]) async throws -> Void = { _ in }
}

extension PhotoLibraryClient: DependencyKey {
    static var liveValue: PhotoLibraryClient { /* 실제 PhotoKit 구현 */ }
    static var previewValue: PhotoLibraryClient { /* Mock 데이터 */ }
    static var testValue: PhotoLibraryClient { /* XCTest용 */ }
}

extension DependencyValues {
    var photoLibraryClient: PhotoLibraryClient {
        get { self[PhotoLibraryClient.self] }
        set { self[PhotoLibraryClient.self] = newValue }
    }
}
```

**수락 기준**:
- `liveValue`에서 `PHPhotoLibrary.requestAuthorization` 호출
- `fetchPhotos`에서 `PHAsset` → `PhotoAsset` 변환 완료
- `@MainActor`/`Sendable` 컴파일러 경고 없음

#### 2-2. `Info.plist` 권한 키 추가
- `NSPhotoLibraryUsageDescription` 문자열 추가
- `NSPhotoLibraryAddUsageDescription` 추가 (삭제 기능 대비)

**수락 기준**: 시뮬레이터에서 앱 실행 시 권한 다이얼로그 표시됨.

---

### Phase 3 — AppFeature (Root Reducer + 탭 바) (Effort: M)

**목표**: 탭 바 구조를 TCA로 잡아 이후 Feature 추가를 쉽게 한다.

#### 3-1. `AppFeature`
```swift
// Presentation/App/AppFeature.swift
import ComposableArchitecture

@Reducer
struct AppFeature {
    enum Tab: Equatable { case gallery, album }

    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .gallery
        var gallery = GalleryFeature.State()
    }

    enum Action {
        case selectTab(Tab)
        case gallery(GalleryFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.gallery, action: \.gallery) { GalleryFeature() }
        Reduce { state, action in
            switch action {
            case let .selectTab(tab):
                state.selectedTab = tab
                return .none
            case .gallery: return .none
            }
        }
    }
}
```

#### 3-2. `AppView` (TabView 래퍼)
- `@Bindable var store: StoreOf<AppFeature>` 패턴 사용
- `ContentView.swift` 제거 후 `PHOUApp.swift`에서 `AppView` 직접 사용

**수락 기준**: 빌드 성공, 탭 전환 시 State 변경 확인.

---

### Phase 4 — GalleryFeature (end-to-end) (Effort: L)

**목표**: 권한 요청 → 사진 로드 → Grid 표시까지 완성.

#### 4-1. `GalleryFeature` Reducer
```swift
@Reducer
struct GalleryFeature {
    @ObservableState
    struct State: Equatable {
        var authorizationStatus: PHAuthorizationStatus = .notDetermined
        var photos: [PhotoAsset] = []
        var isLoading = false
        var error: String?
    }

    enum Action {
        case view(ViewAction)
        case `internal`(InternalAction)
    }

    enum ViewAction {
        case onAppear
        case refreshTapped
    }

    enum InternalAction {
        case authorizationResponse(PHAuthorizationStatus)
        case photosResponse(Result<[PhotoAsset], Error>)
    }

    @Dependency(\.photoLibraryClient) var photoLibraryClient

    var body: some ReducerOf<Self> { ... }
}
```

#### 4-2. `GalleryView`
- `LazyVGrid` 3열 그리드
- `onAppear` → `store.send(.view(.onAppear))`
- 권한 없음 상태 → 안내 뷰 분기
- 로딩 중 → `ProgressView` 오버레이
- `PhotoThumbnailView` 컴포넌트 분리

**수락 기준**:
- 실기기/시뮬레이터에서 사진 라이브러리의 사진이 그리드로 표시됨
- 권한 거부 시 별도 안내 UI 표시
- 메모리 누수 없음 (Instruments로 확인)

---

### Phase 5 — 앨범 탭 Stub (Effort: S)

**목표**: 탭 바 구조 완성을 위한 최소 앨범 탭.

- `AlbumFeature`와 `AlbumView` — "앨범 준비 중" 빈 뷰로 stub
- `AppFeature.State`에 `album = AlbumFeature.State()` 추가

**수락 기준**: 탭 전환이 정상 동작, 빌드 성공.

---

## Risk Assessment

| 리스크 | 확률 | 영향 | 완화 방법 |
|--------|------|------|----------|
| Swift 6 Sendable 경고 폭발 | 높음 | 중간 | `PHAsset` 직접 사용 금지, `PhotoAsset` DTO 변환 레이어에서 처리 |
| PhotoKit 권한 시뮬레이터 이슈 | 중간 | 낮음 | `previewValue` Mock으로 UI 개발 병행 |
| TCA `@DependencyClient` 매크로 컴파일 느림 | 낮음 | 낮음 | Xcode 빌드 캐시 활용 |
| `PBXFileSystemSynchronizedRootGroup` 그룹 인식 지연 | 낮음 | 낮음 | Xcode 재시작으로 해결 |

---

## Success Metrics

1. `xcodebuild` 빌드 성공 (경고 0개 목표)
2. 갤러리 탭에서 실 사진이 그리드로 표시됨
3. 권한 미허가 시 적절한 UX 표시
4. TCA `testValue`로 Unit Test 작성 가능한 구조

---

## Timeline Estimate

| Phase | 예상 소요 |
|-------|----------|
| Phase 1 — 구조 & 엔티티 | 30분 |
| Phase 2 — PhotoLibraryClient | 1시간 |
| Phase 3 — AppFeature | 30분 |
| Phase 4 — GalleryFeature | 1.5시간 |
| Phase 5 — 앨범 Stub | 20분 |
| **합계** | **~4시간** |

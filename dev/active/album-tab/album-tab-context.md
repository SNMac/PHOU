# Album Tab — 컨텍스트 및 핵심 파일

**Last Updated**: 2026-04-23  
**Status**: ✅ 구현 완료, 빌드 성공. 시뮬레이터 수동 테스트 필요.

---

## 실제 파일 경로

> ⚠️ 문서의 `PHOU/Presentation/...` 경로는 실제로 `PHOU/PHOU/PHOU/Presentation/...` 입니다.  
> 즉, 프로젝트 루트 기준 소스 파일은 모두 `PHOU/PHOU/PHOU/` 하위에 있습니다.

---

## 수정/생성된 파일

| 파일 | 경로 | 상태 |
|------|------|------|
| `AlbumGroup.swift` | `PHOU/PHOU/PHOU/Domain/Entity/AlbumGroup.swift` | ✅ `coverAssetId: String?` 필드 추가 |
| `PhotoLibraryClient.swift` | `PHOU/PHOU/PHOU/Data/Client/PhotoLibraryClient.swift` | ✅ `fetchAlbums` coverAssetId 수집 + `fetchAssetsInAlbum` 신규 추가 |
| `AlbumFeature.swift` | `PHOU/PHOU/PHOU/Presentation/Album/AlbumFeature.swift` | ✅ 전체 구현 완료 |
| `AlbumView.swift` | `PHOU/PHOU/PHOU/Presentation/Album/AlbumView.swift` | ✅ 섹션 List UI 구현 완료 |
| `AlbumPhotoGridFeature.swift` | `PHOU/PHOU/PHOU/Presentation/Album/AlbumPhotoGridFeature.swift` | ✅ 신규 생성 완료 |
| `AlbumPhotoGridView.swift` | `PHOU/PHOU/PHOU/Presentation/Album/AlbumPhotoGridView.swift` | ✅ 신규 생성 완료 |

---

## 핵심 구현 결정 및 트릭

### 1. `@Presents` vs `@PresentationState`

`@ObservableState`와 함께 사용할 때는 **반드시 `@Presents`** 를 사용해야 합니다.  
`@PresentationState`는 `@ObservableState` 매크로와 충돌하여 컴파일 오류 발생.

```swift
// ❌ 오류 발생
@ObservableState struct State {
    @PresentationState var albumPhotoGrid: AlbumPhotoGridFeature.State?
}

// ✅ 올바른 패턴
@ObservableState struct State {
    @Presents var albumPhotoGrid: AlbumPhotoGridFeature.State?
}
```

`ifLet` 연결 문법은 동일하게 `\.$albumPhotoGrid` 사용.

### 2. `@Bindable var store` 필수

`$store.scope(state:action:)` 문법을 사용하려면 `@Bindable`이 필요합니다.

```swift
// ❌ $store를 찾을 수 없음
struct AlbumView: View {
    let store: StoreOf<AlbumFeature>
}

// ✅ 올바른 패턴
struct AlbumView: View {
    @Bindable var store: StoreOf<AlbumFeature>
}
```

GalleryView는 `$store.scope`를 사용하지 않아서 `let store`로 충분했지만,  
AlbumView는 navigationDestination에서 `$store.scope`가 필요하므로 `@Bindable` 필수.

### 3. `Foundation` import

`AlbumFeature.swift`는 `ComposableArchitecture`만 import 해도 빌드되지 않습니다.  
`error.localizedDescription` 사용을 위해 `import Foundation`이 별도로 필요합니다.

### 4. `.clipShape(RoundedRectangle(cornerRadius:))` 패턴

`.cornerRadius(_:)` 는 iOS 16부터 deprecated. iOS 17 타겟 프로젝트에서는 항상 아래 패턴 사용:

```swift
.clipShape(RoundedRectangle(cornerRadius: 8))
```

### 5. `fetchAssetsInAlbum` 구현

`PhotoLibraryClient`에 추가된 메서드. `albumId`(= `PHAssetCollection.localIdentifier`)로 컬렉션을 찾고 `creationDate` 내림차순 정렬로 에셋을 반환합니다.

---

## 최종 커밋 히스토리 (feature/#5-album)

```
41e89e3 fix: #5 - @Presents 매크로 적용 및 Foundation import, @Bindable 수정
cb3f69a fix: #5 - AlbumView cornerRadius deprecated API 수정
e2de10f feat: #5 - AlbumView 섹션 List UI 구현
7c7d63a refactor: #5 - PhotoLibraryClient unused extension 제거 및 파일 헤더 복원
9a288a9 feat: #5 - AlbumPhotoGridFeature/View 및 fetchAssetsInAlbum 구현
1efbe95 feat: #5 - AlbumFeature 앨범 목록 fetch 로직 구현
e158a5b feat: #5 - coverAssetId 필드 정리 및 fetchAlbums 첫 번째 에셋 ID 수집
53b8373 feat: #5 - AlbumGroup에 coverAssetId 필드 추가
```

---

## 다음 단계

1. **시뮬레이터 수동 테스트** — 앨범 탭 진입, 커버 이미지 로드, 앨범 탭 → 그리드 이동 확인
2. **빈 앨범 / 권한 없음 시나리오 확인**
3. **PR 생성** — `feature/#5-album` → `develop` (GitHub Issue #5 close)

---

## AlbumGroup 엔티티 최종 상태

```swift
struct AlbumGroup: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let assetCount: Int
    let coverAssetId: String?   // 첫 번째 에셋 localIdentifier, 없으면 nil
    let albumType: AlbumType

    enum AlbumType: Equatable, Sendable {
        case smartAlbum, userAlbum
    }
}
```

---

## AlbumFeature 최종 구조

```swift
@Reducer
struct AlbumFeature {
    @ObservableState
    struct State: Equatable {
        var authStatus: PhotoAuthStatus = .notDetermined
        var albums: [AlbumGroup] = []
        var isLoading = false
        var errorMessage: String?
        @Presents var albumPhotoGrid: AlbumPhotoGridFeature.State?
    }

    enum Action {
        case view(ViewAction)
        case `internal`(InternalAction)
        case albumPhotoGrid(PresentationAction<AlbumPhotoGridFeature.Action>)

        enum ViewAction { case onAppear, retryTapped, albumTapped(AlbumGroup) }
        enum InternalAction {
            case authResponse(PhotoAuthStatus)
            case albumsResponse(Result<[AlbumGroup], Error>)
        }
    }
}
```

---

## AlbumView 레이아웃 최종 구조

```
NavigationStack
├── .navigationTitle("앨범")
├── .onAppear → store.send(.view(.onAppear))
├── .navigationDestination(item: $store.scope(state: \.albumPhotoGrid, action: \.albumPhotoGrid))
│   └── AlbumPhotoGridView(store: gridStore)
└── content (authStatus switch)
    ├── .notDetermined → ProgressView
    ├── .denied/.restricted → ContentUnavailableView (설정 열기 버튼)
    └── .authorized/.limited
        ├── isLoading && albums.isEmpty → ProgressView
        └── albumList (List .insetGrouped)
            ├── Section("시스템 앨범") [smartAlbums, 비면 미표시]
            └── Section("나의 앨범") [userAlbums, 비면 미표시]
                └── albumRow: HStack { 커버(60×60, clipShape) | title + count | Spacer }
```

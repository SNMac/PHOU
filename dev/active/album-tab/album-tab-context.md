# Album Tab — 컨텍스트 및 핵심 파일

**Last Updated**: 2026-04-23  
**Status**: ✅ 구현 완료, 시뮬레이터 동작 확인됨. 앨범 행 터치 영역 및 구분선 보정 반영, 최종 수동 재확인 필요.

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
| `AlbumView.swift` | `PHOU/PHOU/PHOU/Presentation/Album/AlbumView.swift` | ✅ 섹션 List UI 구현 완료 + 행 전체 터치 영역/구분선 보정 |
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

### 6. Album row 터치 영역 보정

시뮬레이터에서 앨범 탭 동작 자체는 확인됐지만, `AlbumView`의 앨범 행이 `.buttonStyle(.plain)` 상태에서 보이는 콘텐츠 중심으로만 터치되는 것처럼 느껴지는 문제가 있었다.

이를 보정하기 위해 `albumRow(_:)`의 버튼 라벨 `HStack`에 아래를 추가했다.

```swift
.frame(maxWidth: .infinity, alignment: .leading)
.contentShape(Rectangle())
.padding(.vertical, 4)
```

핵심 의도는 다음과 같다.

- 행의 레이아웃 폭을 리스트 가용 폭까지 넓힘
- 투명 여백도 탭 영역으로 인식되도록 `contentShape(Rectangle())` 적용
- 세로 히트 타깃을 약간 넉넉하게 확보

즉, 썸네일이나 텍스트 위만 눌리던 느낌을 줄이고, 행 전체가 자연스럽게 탭되도록 만드는 수정이다.

### 7. Album row 구분선 전체 폭 보정

기본 `List` separator는 텍스트 콘텐츠 기준 inset이 들어가서, 앨범 셀 사이 구분선이 썸네일 왼쪽 영역까지 이어지지 않았다.

이를 보정하기 위해 `albumRow(_:)`의 버튼에 아래를 추가했다.

```swift
.alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
.alignmentGuide(.listRowSeparatorTrailing) { dimensions in
    dimensions.width
}
```

핵심 의도는 다음과 같다.

- row separator의 시작 위치를 리스트 행의 선두로 맞춤
- row separator의 끝 위치도 행 전체 폭으로 확장
- 썸네일 영역 앞쪽이 비어 보이지 않도록 전체 폭으로 구분선 표시
- 기존 `List(.insetGrouped)` 스타일과 행 레이아웃은 유지

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

1. **터치 영역/구분선 최종 수동 테스트** — 앨범 셀의 빈 여백 탭과 separator 전체 폭 표시 재확인
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
                └── albumRow: Button(.plain) { HStack { 커버(60×60, clipShape) | title + count | Spacer } + contentShape(Rectangle()) } + separatorLeading(0) + separatorTrailing(fullWidth)
```

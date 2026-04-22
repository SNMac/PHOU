# Album Tab — 컨텍스트 및 핵심 파일

**Last Updated**: 2026-04-22

---

## 핵심 파일

### 수정 대상

| 파일 | 경로 | 변경 내용 |
|------|------|-----------|
| `AlbumFeature.swift` | `PHOU/Presentation/Album/AlbumFeature.swift` | fetch 로직 추가, AlbumPhotoGridFeature 연결 |
| `AlbumView.swift` | `PHOU/Presentation/Album/AlbumView.swift` | 섹션 List UI 구현 |
| `AlbumGroup.swift` | `PHOU/Domain/Entity/AlbumGroup.swift` | `coverAssetId: String?` 필드 추가 |
| `PhotoLibraryClient.swift` | `PHOU/Data/Client/PhotoLibraryClient.swift` | `fetchAlbums` liveValue에서 첫 번째 에셋 ID 수집 |

### 신규 생성 대상

| 파일 | 경로 | 역할 |
|------|------|------|
| `AlbumPhotoGridFeature.swift` | `PHOU/Presentation/Album/AlbumPhotoGridFeature.swift` | 특정 앨범 내 사진 fetch + 상태 관리 |
| `AlbumPhotoGridView.swift` | `PHOU/Presentation/Album/AlbumPhotoGridView.swift` | 앨범 내 사진 LazyVGrid |

### 참고 파일 (변경 없음)

| 파일 | 경로 | 참고 이유 |
|------|------|-----------|
| `GalleryFeature.swift` | `PHOU/Presentation/Gallery/GalleryFeature.swift` | 권한 체크 → fetch 패턴 참고 |
| `GalleryView.swift` | `PHOU/Presentation/Gallery/GalleryView.swift` | LazyVGrid + PhotoThumbnailView 패턴 참고 |
| `PhotoThumbnailView.swift` | `PHOU/Presentation/Components/PhotoThumbnailView.swift` | 커버 이미지 재사용 컴포넌트 |
| `AppFeature.swift` | `PHOU/Presentation/App/AppFeature.swift` | AlbumFeature 연결 확인 |

---

## AlbumGroup 엔티티 변경 계획

```swift
// 변경 전
struct AlbumGroup: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let assetCount: Int
    let albumType: AlbumType
}

// 변경 후 — coverAssetId 추가
struct AlbumGroup: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let assetCount: Int
    let coverAssetId: String?   // 첫 번째 에셋 로컬 ID, 없으면 nil
    let albumType: AlbumType
}
```

---

## PhotoLibraryClient fetchAlbums 변경 계획

`liveValue`의 `fetchAlbums` 클로저에서 각 컬렉션의 첫 번째 에셋 ID를 수집합니다.

```swift
fetchAlbums: {
    func firstAssetId(in collection: PHAssetCollection) -> String? {
        let options = PHFetchOptions()
        options.fetchLimit = 1
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(in: collection, options: options).firstObject?.localIdentifier
    }
    // ... 기존 enumeration 로직에서 coverAssetId: firstAssetId(in: collection) 추가
}
```

---

## AlbumFeature 구현 패턴

GalleryFeature를 그대로 따릅니다. 권한이 authorized / limited일 때만 fetchAlbums를 호출합니다.

```swift
@Reducer
struct AlbumFeature {
    @ObservableState
    struct State: Equatable {
        var authStatus: PhotoAuthStatus = .notDetermined
        var albums: [AlbumGroup] = []
        var isLoading = false
        var errorMessage: String?
        @PresentationState var albumPhotoGrid: AlbumPhotoGridFeature.State?
    }

    enum Action {
        case view(ViewAction)
        case `internal`(InternalAction)
        case albumPhotoGrid(PresentationAction<AlbumPhotoGridFeature.Action>)

        enum ViewAction {
            case onAppear
            case albumTapped(AlbumGroup)
        }
        enum InternalAction {
            case authResponse(PhotoAuthStatus)
            case albumsResponse(Result<[AlbumGroup], Error>)
        }
    }
}
```

---

## AlbumView 레이아웃 구조

```
NavigationStack
└── List
    ├── Section("시스템 앨범")  ← albumType == .smartAlbum
    │   └── NavigationLink { AlbumRowView } destination: { AlbumPhotoGridView }
    └── Section("나의 앨범")    ← albumType == .userAlbum
        └── NavigationLink { AlbumRowView } destination: { AlbumPhotoGridView }
```

`AlbumRowView` 레이아웃:
```
HStack
├── 커버 이미지 (60×60, cornerRadius 8) — PhotoThumbnailView 또는 placeholder
├── VStack(alignment: .leading)
│   ├── Text(album.title) .font(.body)
│   └── Text("\(album.assetCount)") .font(.subheadline) .foregroundStyle(.secondary)
└── Spacer
```

---

## 주요 의존성

- `PhotoLibraryClient.fetchAlbums` — 이미 liveValue 구현됨, coverAssetId만 추가
- `PhotoThumbnailView` — 재사용 (변경 없음)
- TCA `@PresentationState` / `.sheet` 또는 NavigationStack `.navigationDestination`

---

## 참고: TCA PresentationState 연결 예시

```swift
// AlbumFeature body
.ifLet(\.$albumPhotoGrid, action: \.albumPhotoGrid) {
    AlbumPhotoGridFeature()
}

// AlbumView
.navigationDestination(
    item: $store.scope(state: \.albumPhotoGrid, action: \.albumPhotoGrid)
) { gridStore in
    AlbumPhotoGridView(store: gridStore)
}
```

# Architecture Foundation — Context & Key Decisions

Last Updated: 2026-04-23

---

## 현재 상태 요약

**PR #2 머지 완료** — Architecture Foundation 작업은 메인라인에 반영되었고, 현재는 후속 기능과 UX 개선 이슈를 이어서 진행 중.

---

## 구현 완료 파일

| 파일 | 경로 | 상태 |
|------|------|------|
| 앱 진입점 | `PHOU/PHOUApp.swift` | ✅ 완료 |
| Domain 엔티티 | `PHOU/Domain/Entity/` | ✅ 완료 (3개 파일) |
| PhotoKit 클라이언트 | `PHOU/Data/Client/PhotoLibraryClient.swift` | ✅ 완료 |
| 갤러리 Feature | `PHOU/Presentation/Gallery/GalleryFeature.swift` | ✅ @Reducer 유지 |
| 갤러리 뷰 | `PHOU/Presentation/Gallery/GalleryView.swift` | ✅ 완료 |
| 썸네일 뷰 | `PHOU/Presentation/Components/PhotoThumbnailView.swift` | ✅ 완료 |
| 루트 Feature | `PHOU/Presentation/App/AppFeature.swift` | ✅ @Reducer 복원 |
| 루트 뷰 | `PHOU/Presentation/App/AppView.swift` | ✅ 완료 |
| 앨범 Feature | `PHOU/Presentation/Album/AlbumFeature.swift` | ✅ @Reducer 복원 |
| 앨범 뷰 | `PHOU/Presentation/Album/AlbumView.swift` | ✅ 완료 |

---

## 2차 세션에서 해결한 문제

### 근본 원인 확정

`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` + `SWIFT_APPROACHABLE_CONCURRENCY = YES` (Xcode 26 Beta 자동 설정)이 `@Reducer` 매크로와 충돌.

**충돌 구조:**
- 이 설정 → 모듈 내 모든 타입이 암시적 `@MainActor`
- `@Reducer` 매크로 → `Reducer` 프로토콜 준수 코드를 `nonisolated`로 생성
- `@MainActor` 타입 + `nonisolated` 요구사항 = circular reference

**TCA 저자(Brandon Williams) 공식 입장** (GitHub Issue #3808):
> "default main actor isolation just isn't that useful outside of an exploratory phase of building an app. It is largely incompatible with nearly every 3rd party library and even many of Apple's 1st party libraries. So I recommend turning that setting off."

### 적용한 해결책

1. **TCA 1.25.5 업데이트** (사용자가 직접)
2. **`project.pbxproj`에서 두 설정 제거** (Debug & Release 모두):
   - `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
   - `SWIFT_APPROACHABLE_CONCURRENCY = YES`
3. **`AppFeature.swift` — `@Reducer` 복원**:
   - `extension AppFeature: Reducer` + `nonisolated var body` → `@Reducer struct AppFeature` 내부로 통합
   - `@CasePathable` 제거 (`@Reducer` 매크로가 자동 생성)
4. **`AlbumFeature.swift` — `@Reducer` 복원**:
   - `extension AlbumFeature: Reducer` + `nonisolated func reduce` → `@Reducer struct AlbumFeature` 내부로 통합
   - `reduce(into:action:)` → `body` 방식으로 변경 (GalleryFeature와 일관성)
   - `@CasePathable` 제거

### 롤백한 임시 워크어라운드

- `PhotoLibraryClient.swift` `init(from:)` 의 `nonisolated` 제거 — 설정 제거로 불필요해짐

---

## 현재 코드 상태 (이번 세션 종료 기준)

**AppFeature.swift:**
```swift
@Reducer
struct AppFeature {
    enum Tab: Equatable { case gallery, album }

    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .gallery
        var gallery = GalleryFeature.State()
        var album = AlbumFeature.State()
    }

    enum Action {
        case selectTab(Tab)
        case gallery(GalleryFeature.Action)
        case album(AlbumFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.gallery, action: \.gallery) { GalleryFeature() }
        Scope(state: \.album, action: \.album) { AlbumFeature() }
        Reduce { state, action in
            switch action {
            case let .selectTab(tab):
                state.selectedTab = tab
                return .none
            case .gallery, .album:
                return .none
            }
        }
    }
}
```

**AlbumFeature.swift:**
```swift
@Reducer
struct AlbumFeature {
    @ObservableState
    struct State: Equatable {}

    enum Action {
        case onAppear
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            }
        }
    }
}
```

---

## 빌드 환경 정보

- Xcode 26 Beta (`LastUpgradeCheck = 2640`)
- Swift 6.0
- **`SWIFT_DEFAULT_ACTOR_ISOLATION`**: 제거됨 ✅
- **`SWIFT_APPROACHABLE_CONCURRENCY`**: 제거됨 ✅
- TCA: **1.25.5** (이번 세션에서 업데이트)
- iOS 17.0 Deployment Target

---

## 코드 컨벤션 확정 사항

### @Reducer 패턴 (변경 없음 — 유지)
- `@Reducer` 매크로 사용. `@CasePathable`, `@ObservableState` 통합 자동 생성
- `extension`으로 분리하지 않고 struct 내부에 `body` 정의
- `nonisolated` 수동 추가 금지

### Action 네이밍 (GalleryFeature 기준)
```swift
enum Action {
    case view(ViewAction)
    case `internal`(InternalAction)
}
```
- stub Feature는 단순 `case onAppear` 허용

### PhotoKit 접근
- `@preconcurrency import Photos` — Swift 6 strict concurrency에서 PhotoKit Sendable 경고 억제 목적. 의도적 패턴, 제거 금지
- `PHAuthorizationStatus` → `PhotoAuthStatus` 변환은 `PhotoLibraryClient` 내부(`init(from:)`)에서만

### Mixed Media 방향성 확인
- `PhotoAsset.MediaType`가 `image`, `video`, `unknown`을 모두 가지도록 설계된 점에서, Architecture Foundation 단계부터 mixed media 확장을 수용하는 구조였음
- 이후 앨범 탭 구현에서 `fetchAssetsInAlbum(_:)`도 실제 `PHAsset.mediaType`을 보존하도록 보정됨
- mixed media UI 자체(비디오 배지, 재생 시간, 필터 UI)는 아키텍처 수정 이슈가 아니라 후속 UX/표현 이슈로 분리
- 후속 추적: GitHub Issue #8 `feat: 앨범 상세 mixed media 표시 개선`

---

## GalleryView 그리드 수정 (3차 세션)

### 문제
셀이 이미지 원본 비율로 렌더링 — 행 높이가 가장 큰 이미지 기준으로 확장됨

### 원인
`PhotoThumbnailView` 내부 `Image`의 `.aspectRatio(contentMode: .fill)`이  
외부 `.aspectRatio(1, contentMode: .fill)`과 충돌하여 1:1 제약이 무시됨

### 해결 패턴 (`GalleryView.swift`)
```swift
// 변경 전
PhotoThumbnailView(id: asset.id)
    .aspectRatio(1, contentMode: .fill)
    .clipped()

// 변경 후
Color.clear
    .aspectRatio(1, contentMode: .fill)
    .overlay { PhotoThumbnailView(id: asset.id) }
    .clipped()
```
`Color.clear`가 레이아웃 시스템에서 1:1 영역을 확보하고, `PhotoThumbnailView`는 그 위에 overlay로 채움.
`GridItem(.adaptive)` → `GridItem(.flexible)` 3열 고정으로 변경.

---

## 코드 리뷰 반영 (4차 세션, PR #2)

### [HIGH] withCheckedContinuation 이중 resume — 수정 완료 (커밋 2ae591b)
`PHImageManager.requestImage`는 `isSynchronous=false`일 때 핸들러를 여러 번 호출 가능.
`resumed` 플래그로 첫 번째 호출에서만 `continuation.resume` 되도록 보장.

```swift
var resumed = false
PHImageManager.default().requestImage(...) { result, _ in
    guard !resumed else { return }
    resumed = true
    continuation.resume(returning: result)
}
```

### [MEDIUM] fetchPhotos 전체 배열 변환 메모리 이슈 — Issue #3 등록
현재 Phase 범위 밖. 갤러리 안정화 후 페이지네이션 도입 예정.

### [MEDIUM] 셀마다 PHAsset 재fetch 성능 이슈 — Issue #4 등록
`PhotoThumbnailView`에 `id: String`만 전달하는 것은 **의도된 설계** (Domain 분리).
`PHCachingImageManager` 도입 시점에 함께 최적화 예정.

---

## 후속 추적 사항

- [x] PR #2 Merge
- [x] GitHub Issue #1 Close
- [x] 권한 거부 시나리오 테스트
- [ ] mixed media 표시 정책은 GitHub Issue #8에서 후속 검토

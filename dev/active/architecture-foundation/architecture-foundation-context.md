# Architecture Foundation — Context & Key Decisions

Last Updated: 2026-04-22 (2차 세션 종료 시점)

---

## 현재 상태 요약

**빌드 미확인** — 이번 세션에서 근본 원인을 해결했으나, Xcode에서 `⌘B` 빌드 성공 여부 아직 확인 필요.

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

---

## 다음 세션 할 일

### Step 1 — 빌드 확인 (최우선)
Xcode 재시작 후 `⌘B`. 오류 발생 시 오류 전문을 확인.

### Step 2 — 빌드 성공 시
- [ ] commit: `fix: SWIFT_DEFAULT_ACTOR_ISOLATION 제거 및 @Reducer 패턴 복원`
- [ ] PR 생성 (`feature/#1-architecture-foundation` → `main`)
- [ ] GitHub Issue #1 Close

### Step 3 — 빌드 실패 시 대안
혹시 다른 오류가 남아 있을 경우 오류 메시지 전문을 다음 세션에 붙여넣기.

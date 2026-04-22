# Architecture Foundation — Context & Key Decisions

Last Updated: 2026-04-22

---

## 핵심 파일 위치

| 파일 | 경로 | 역할 |
|------|------|------|
| 앱 진입점 | `PHOU/PHOUApp.swift` | Store 생성 및 AppView 주입 |
| 현재 루트 뷰 | `PHOU/ContentView.swift` | Phase 3에서 삭제 대상 |
| Xcode 프로젝트 | `PHOU.xcodeproj/project.pbxproj` | 직접 수정 불필요 (자동 동기화) |

---

## 아키텍처 결정 사항

### 1. PBXFileSystemSynchronizedRootGroup
Xcode 16+의 자동 파일 동기화 기능 사용 중. `PHOU/` 폴더 하위에 파일/폴더를 만들면 pbxproj 수정 없이 자동으로 빌드 대상에 포함된다.

**실천 방법**: 터미널 또는 Claude Code의 Write 도구로 Swift 파일 생성 → Xcode에서 즉시 인식.

### 2. PhotoAsset DTO 패턴
`PHAsset`은 `Sendable`이 아니고 Main Thread 의존성이 있다. `PhotoLibraryClient.liveValue` 내부에서만 `PHAsset`을 다루고, 외부로는 반드시 `PhotoAsset` (순수 Swift struct) 으로 변환해서 내보낸다.

```
PHAsset (PhotoKit, Main Thread 의존) 
  → [PhotoAsset] (Sendable struct, 레이어 경계)
  → TCA State
```

### 3. @DependencyClient 매크로
TCA 1.9+부터 `@DependencyClient` 매크로로 보일러플레이트 제거. `liveValue` / `previewValue` / `testValue` 세 가지를 모두 구현해야 `#Preview`와 테스트 모두 작동.

### 4. Action 네이밍 컨벤션
```swift
enum Action {
    case view(ViewAction)      // 사용자 인터랙션
    case `internal`(InternalAction)  // 내부 로직, Effect 응답
    case delegate(DelegateAction)    // 부모 Feature로 이벤트 전달
}
```
이 구조를 모든 Feature에 일관되게 적용한다.

### 5. @ObservableState
TCA 1.7+에서 도입된 `@ObservableState`를 사용. `@Bindable var store: StoreOf<Feature>`와 함께 쓰면 `ViewStore` 래핑 불필요. `WithViewStore`는 사용하지 않는다.

### 6. Swift 6 Strict Concurrency
- `PHAsset` 관련 코드는 `@MainActor` 블록 내에서 처리
- `PhotoLibraryClient` 내 클로저는 모두 `@Sendable` 마킹
- `Actor` 격리 경계를 `PhotoLibraryClient`에서 처리하고 상위 레이어는 `async/await`만 사용

---

## 외부 의존성

| 패키지 | 버전 | 추가 방법 |
|--------|------|----------|
| ComposableArchitecture | ≥ 1.24.1 | ✅ 이미 추가됨 |
| SwiftData | — | iOS 17+ 내장 |
| PhotoKit (Photos.framework) | — | iOS 내장 |
| Vision.framework | — | iOS 내장, Phase 후반 |
| CoreML | — | iOS 내장, Phase 후반 |

**추가 SPM 패키지 불필요** (현재 Phase 기준).

---

## Info.plist 권한 키

Phase 2에서 반드시 추가해야 할 항목:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>사진을 정리하려면 사진 라이브러리 접근이 필요합니다.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>정리된 사진을 앨범에 저장하려면 접근 권한이 필요합니다.</string>
```

Xcode에서 `PHOU` 타겟 → Info 탭에서 추가하거나, `Info.plist` 파일에 직접 추가.

---

## 알려진 함정

1. **PHAuthorizationStatus `.limited`** — iOS 14+에서 선택적 접근 허용 시 발생. `fetchPhotos`에서 `.limited` 상태도 정상 처리해야 함.
2. **썸네일 메모리 누수** — `PHImageManager.requestImage`는 캐시를 자동 관리하지 않음. `LazyVGrid`의 `onDisappear`에서 요청을 취소해야 함.
3. **시뮬레이터 사진** — 시뮬레이터는 기본 사진 없음. `previewValue`에서 Mock 데이터를 제공하거나 시뮬레이터에 사진을 직접 추가.

---

## 참고 자료

- TCA 공식 문서: https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/
- TCA Dependency 가이드: https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/dependencymanagement
- PhotoKit 권한 처리: https://developer.apple.com/documentation/photokit/phphotolibrary/requestauthorization(for:handler:)

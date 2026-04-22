# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

PHOU(PHOto for U)는 SwiftUI + TCA + 온디바이스 AI를 활용한 iOS/iPadOS 갤러리·사진 정리 앱입니다.

- **플랫폼**: iOS/iPadOS 17.0+, Swift 6.0
- **번들 ID**: com.snmac.PHOU

## 빌드 및 실행

**⚠️ 빌드 설정 주의**: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`와 `SWIFT_APPROACHABLE_CONCURRENCY = YES`는 TCA `@Reducer` 매크로와 충돌하여 circular reference 오류를 발생시킵니다. 이 프로젝트에서는 두 설정을 제거한 상태로 유지합니다. (TCA 저자 공식 권고, GitHub Issue #3808)

Xcode에서 `PHOU.xcodeproj`를 열어 빌드합니다.

```bash
# CLI 빌드 (시뮬레이터)
xcodebuild -project PHOU.xcodeproj -scheme PHOU -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=17.0' build

# 테스트 실행 (Swift Testing 사용)
xcodebuild -project PHOU.xcodeproj -scheme PHOU -destination 'platform=iOS Simulator,name=iPhone 13 mini,OS=17.0' test

# 의존성 갱신
xcodebuild -resolvePackageDependencies
```

## 아키텍처

**TCA (The Composable Architecture) + Clean Architecture** 를 조합하여 사용합니다.

### 프로젝트 구조

- `PHOU/Domain`: 비즈니스 로직 및 엔티티 (Interface, UseCase)
- `PHOU/Data`: 데이터 소스 및 저장소 구현 (SwiftData, PhotoKit Client)
- `PHOU/Presentation`: UI 및 TCA Reducer (Feature 단위 분리)
- `PHOU/Core`: 공통 유틸리티 및 AI 모델 (Vision, CoreML)

### TCA 패턴

- **State**: 구조체로 정의하며, UI에 필요한 상태만 최소한으로 유지합니다.
- **Action**: Enum으로 정의하며, 유저 인터랙션(`view`), 내부 로직(`internal`), 의존성 응답(`delegate`)으로 명확히 네이밍합니다.
- **Reducer**: `Reduce` 클로저 내에서 로직을 처리하며, Side Effect는 `Dependency`를 통해서만 수행합니다.
- **View**: `@Bindable`을 사용하여 Store와 연결합니다. (TCA 1.0+ 최신 문법 지향)
- **의존성 주입**: TCA의 `@Dependency`를 통해 Repository를 주입하여 테스트 가능성을 확보합니다.

## 주요 의존성 (SPM)

| 패키지 | 버전 | 용도 |
|--------|------|------|
| [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) | ≥ 1.25.5 | 상태 관리 아키텍처 |

## 핵심 기술

- **PhotoKit**: 사진 라이브러리 접근 및 삭제
- **CoreML / Vision Framework**: 온디바이스 AI — 흔들린 사진 감지, 유사 사진 그룹화, 키워드 검색
- **SwiftData**: 앱 내부 영구 저장소
- **SwiftUI**: 전체 UI (iOS 17+ API 사용 가능)

## SwiftUI / UI 가이드

- **iPad 대응**: `NavigationSplitView`를 사용하여 사이드바와 디테일 뷰 구조를 유지합니다.
- **멀티태스킹**: Split View, Slide Over 환경에서도 레이아웃이 깨지지 않도록 유연한 레이아웃을 작성합니다.
- **베스트 컷 비교 뷰**: 모달 대신 화면 분할 방식을 우선 고려합니다.
- **그리드 UI**: `LazyVGrid`를 사용하며, 대용량 에셋 로드 시 메모리 해제를 위해 `onAppear`/`onDisappear` 최적화를 적용합니다.
- **정사각형 그리드 셀**: `Color.clear.aspectRatio(1, contentMode: .fill).overlay { ... }.clipped()` 패턴 사용. `aspectRatio` 단독 사용 시 내부 Image의 비율과 충돌.
- **PhotoKit import**: `@preconcurrency import Photos` — Swift 6 strict concurrency에서 Sendable 경고 억제 목적. 의도적 패턴.
- **PHImageManager + withCheckedContinuation**: `isSynchronous = false` 시 핸들러가 여러 번 호출될 수 있으므로 `resumed` 플래그로 이중 resume 방지 필수.
- **컴포넌트**: 재사용 가능한 UI 컴포넌트는 `Sources/Presentation/Components`에 위치시킵니다.

## Git 컨벤션

- **커밋 메시지**: `keyword: #[이슈번호] - [내용]` 형식 (예: `feat: #1 - Domain 엔티티 정의`)

## Swift 스타일 가이드

- **네이밍**: 변수/함수는 camelCase, 타입은 PascalCase를 사용합니다.
- **비동기**: `async/await`와 `Task`를 기본으로 사용합니다.
- **안정성**: 강제 언래핑(`!`)을 지양하고 `guard let` 또는 `if let`을 사용합니다.
- **Swift 6 strict concurrency**: `@MainActor`, `Sendable` 등을 적극 활용하고, 컴파일러 경고를 오류로 취급합니다.

## 주요 기능 영역

1. **갤러리 탭** — iOS 17 이전 스타일의 클래식 Grid 뷰
2. **사진 정리** — AI 분석 후 스와이프 UI로 흔들린 사진·유사 사진·스크린샷 정리
3. **최종 확인 뷰** — 삭제 대상 사진 일괄 검토 및 삭제
4. **앨범 탭** — 시스템 기본 앨범 및 사용자 앨범 목록
5. **AI 키워드 검색** — 인터넷 없이 온디바이스에서 자연어로 사진 검색

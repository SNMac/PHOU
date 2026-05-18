# AGENTS.md

이 문서는 PHOU 프로젝트에서 Codex가 작업할 때 따라야 할 운영 지침입니다. 일반적인 답변보다 프로젝트의 현재 상태, 목표 아키텍처, 검증 방법을 우선합니다.

## 프로젝트 개요

- 프로젝트명: `PHOU`
- 플랫폼: iOS / iPadOS 앱
- 앱 목표: iOS 17 이전 스타일의 클래식 사진 그리드 경험과 온디바이스 AI 기반 사진 정리, 검색 기능 제공
- 핵심 기술: SwiftUI, Swift Observation, PhotoKit, Vision, CoreML, SwiftData
- Xcode 프로젝트: `PHOU.xcodeproj`
- 주요 scheme: `PHOU`
- 디자인 기준 문서: `DESIGN.md`
- 현재 소스 상태: 앱 본체는 `PHOU/PHOUApp.swift`, `PHOU/ContentView.swift` 중심의 초기 SwiftUI 템플릿 상태이며, README와 기획서에 목표 구조가 정의되어 있음

## 우선순위

1. 기존 사용자 변경사항을 보존한다.
2. README와 `PHOU 앱 기획서.md`에 적힌 제품 방향을 벗어나지 않는다.
3. 실제 파일 구조와 목표 구조를 구분해서 판단한다.
4. 온디바이스 처리와 사진 라이브러리 프라이버시를 기본 전제로 둔다.
5. UI를 작성하거나 수정하기 전에는 `DESIGN.md`를 먼저 읽고 반영한다.
6. 코드 변경 후 가능한 범위에서 빌드 또는 테스트로 검증한다.

## 현재 구조

현재 확인된 주요 파일:

```text
PHOU/
├── PHOU/
│   ├── PHOUApp.swift
│   ├── ContentView.swift
│   └── Assets.xcassets/
├── PHOUTests/
│   └── PHOUTests.swift
├── PHOUUITests/
│   ├── PHOUUITests.swift
│   └── PHOUUITestsLaunchTests.swift
├── PHOU.xcodeproj/
├── DESIGN.md
├── README.md
└── PHOU 앱 기획서.md
```

README의 목표 구조는 다음 방향을 가진다:

```text
App
Features
Domain
Infrastructure
Shared
```

새 기능을 추가할 때는 이 목표 구조를 기준으로 파일을 배치하되, 아직 존재하지 않는 디렉터리를 만들 때는 필요한 범위만 생성한다.

## 아키텍처 지침

- 화면 단위 기능은 `Features/<FeatureName>` 아래에 둔다.
- 순수 앱 모델, 추천/분석/채점 규칙, Repository 프로토콜은 `Domain`에 둔다.
- PhotoKit, Vision, CoreML, SwiftData 같은 Apple 프레임워크 직접 의존 구현은 `Infrastructure`에 둔다.
- 공용 UI, 확장, 유틸리티, 디자인 토큰은 `Shared`에 둔다.
- SwiftUI View 안에 PhotoKit 요청, AI 분석, 저장소 접근 같은 무거운 작업을 직접 넣지 않는다.
- Feature 상태는 SwiftUI Observation 기반 Store로 관리하는 방향을 따른다.
- 비즈니스 로직은 테스트 가능한 순수 타입으로 분리한다.

## Swift / SwiftUI 규칙

- Swift 6 문법과 Xcode 26 환경을 기준으로 작성한다.
- SwiftUI에서는 작고 명확한 View 구성 요소를 선호한다.
- `@Observable` Store를 사용할 때 View 소유 상태와 외부 의존성을 명확히 나눈다.
- 비동기 작업은 `async/await`를 우선 사용하고, UI 업데이트는 MainActor 경계를 분명히 한다.
- 미리보기(`#Preview`)는 가능한 유지하거나 추가한다.
- 사용하지 않는 import, 죽은 코드, 템플릿 주석은 새 코드에서 남기지 않는다.

## 사진 / AI 기능 지침

- 사진 분석, 추천, 검색 인덱싱은 서버 전송 없이 온디바이스 처리한다.
- PhotoKit 권한 상태를 명시적으로 처리하고, 제한된 사진 접근 권한도 고려한다.
- 삭제 또는 일괄 변경 플로우는 항상 최종 확인 단계를 둔다.
- "영구 보존" 대상은 SwiftData에 `localIdentifier` 기반으로 저장하는 방향을 따른다.
- 흔들린 사진, 비슷한 사진, 스크린샷, 다운로드 사진 추천 로직은 Domain 서비스로 분리한다.
- 베스트 컷 채점은 선명도, 눈 감음 여부, 미소, 얼굴 방향, saliency 같은 요소를 독립적으로 테스트할 수 있게 설계한다.

## UI / UX 지침

- UI 작업 전에는 반드시 `DESIGN.md`를 참고한다.
- `DESIGN.md`의 색상, 타이포그래피, spacing, radius, component token을 우선 사용한다.
- Apple-inspired 방향은 "사진이 먼저 보이고 UI chrome은 물러나는" 경험으로 해석한다.
- 앱의 핵심 경험은 사진 앱처럼 빠르고 익숙한 그리드, 앨범, 검색, 정리 흐름이다.
- 장식적인 UI보다 반복 사용에 편한 밀도와 명확한 상태 표현을 우선한다.
- 인터랙션 색상은 기본적으로 `DESIGN.md`의 Action Blue(`#0066cc`) 계열을 사용하고, 임의의 두 번째 accent color를 만들지 않는다.
- 카드, 버튼, 텍스트에는 장식용 그림자를 추가하지 않는다. 깊이감은 표면 색상, blur, 사진/제품 이미지의 제한적 shadow로 표현한다.
- decorative gradient를 배경으로 쓰지 않는다. 분위기는 사진, 표면 색상, 레이아웃 리듬으로 만든다.
- 주요 화면은 edge-to-edge 또는 넓은 사진 중심 구성을 우선하고, 필요할 때만 utility card를 사용한다.
- SwiftUI 구현에서는 `DESIGN.md` 토큰을 `Shared/DesignSystem`의 Color, Typography, Spacing, Radius 같은 재사용 가능한 타입으로 옮기는 방향을 선호한다.
- Dynamic Type과 iOS 접근성을 해치지 않도록 `DESIGN.md`의 웹 px 값은 SwiftUI에서 의미적으로 대응되는 text style과 spacing으로 변환한다.
- 사진 삭제, 보존, 영구 보존 같은 파괴적이거나 되돌리기 어려운 액션은 명확한 확인과 취소 가능성을 제공한다.
- iOS 기본 컴포넌트와 SwiftUI 네이티브 상호작용을 우선한다.
- 접근성 라벨, Dynamic Type, 다크 모드를 새 UI 작업의 기본 검토 항목으로 둔다.

## 빌드 및 테스트

기본 프로젝트 확인:

```sh
xcodebuild -list -project PHOU.xcodeproj
```

기본 빌드:

```sh
xcodebuild -project PHOU.xcodeproj -scheme PHOU -configuration Debug build
```

시뮬레이터 테스트 예시:

```sh
xcodebuild -project PHOU.xcodeproj -scheme PHOU -destination 'platform=iOS Simulator,name=iPhone 16' test
```

주의:

- 현재 `PHOU` 앱 타깃의 배포 대상은 project 파일 기준 `iOS 18.0`으로 보인다.
- README와 기획서는 `iOS 17.0+`를 명시한다.
- 테스트 타깃에는 `IPHONEOS_DEPLOYMENT_TARGET = 26.5`가 설정되어 있다.
- 배포 대상이나 Xcode 설정을 변경할 때는 이 불일치를 먼저 확인하고, 변경 이유를 명확히 남긴다.

## 작업 방식

- 기존 파일을 수정하기 전에 관련 파일과 README, 기획서를 먼저 읽는다.
- UI 관련 작업은 관련 SwiftUI 파일과 함께 `DESIGN.md`를 읽은 뒤 시작한다.
- 사용자의 명시 요청 없이 광범위한 리팩터링을 하지 않는다.
- 사용자의 기존 변경사항을 되돌리지 않는다.
- 새 파일은 실제로 필요한 경우에만 만든다.
- 기능 구현 시 최소한의 수직 단위로 끝까지 동작하게 만든다.
- 계획된 폴더 구조를 한 번에 모두 만들기보다, 구현하는 기능에 필요한 경로만 만든다.

## 검증 기준

코드 변경 후 가능한 검증을 수행한다:

- 단순 문서 변경: 파일 존재와 내용 확인
- Swift 코드 변경: `xcodebuild ... build`
- 로직 변경: Swift Testing 기반 단위 테스트 추가 또는 갱신
- UI 플로우 변경: UI 테스트 또는 시뮬레이터 수동 확인
- PhotoKit, Vision, CoreML, SwiftData 변경: 권한, 실패 상태, 빈 데이터 상태를 함께 확인

검증을 실행하지 못했다면 최종 응답에 이유와 남은 위험을 적는다.

## 응답 규칙

- 최종 응답은 간결하게 작성한다.
- 변경한 파일, 수행한 검증, 남은 이슈를 분리해서 말한다.
- 검증하지 않은 내용을 완료된 것처럼 말하지 않는다.
- 불확실한 내용은 추정이라고 표시한다.

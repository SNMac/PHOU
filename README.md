# PHOU
> PHOU는 SwiftUI와 온디바이스 AI를 활용한 갤러리 및 사진 정리 앱입니다.
> - 갤러리: iOS 17 이전 스타일의 클래식한 Grid 뷰
> - 사진 정리: AI 기반 흔들린 사진, 비슷한 사진, 스크린샷 추천 및 스와이프 정리
> - 사진 검색: 온디바이스 기반 자연어 키워드 검색
> 
> [Figma]()
> 
> 개발 기간: 2026.05.18 ~

<br>

<a href="">
    <img src="">
</a>

<br>

---

<br>

## 👥 대상 사용자
- 스마트폰 용량 관리가 필요하여 불필요한 사진을 정리하고 싶은 사람
- 흔들리거나 비슷한 연속 촬영 사진 중 '베스트 컷'만 남기고 싶은 사람
- 서버 전송 및 프라이버시 침해 걱정 없이 안전하게 AI 사진 추천/검색 기능을 사용하고 싶은 사람
- iOS 17 이전 버전의 직관적인 클래식 '사진' 앱 UI를 선호하는 사람

<br>

---

<br>

## 🛠️ 기술 스택
|    범위     | 기술 이름                        |
| :-------: | :--------------------------- |
| 의존성 관리 도구 | `SPM`                        |
| 형상 관리 도구  | `Git`, `GitHub`              |
|   아키텍처    | `Feature 중심 구조 + Domain / Infrastructure 계층 분리` |
|   상태 관리   | `SwiftUI Observation (@Observable)` |
|   인터페이스   | `SwiftUI`                    |
| AI / 머신러닝 | `CoreML`, `Vision Framework` |
| 사진 라이브러리  | `PhotoKit`                   |
|  내부 저장소   | `SwiftData`                  |

<br>

## 🏗️ 프로젝트 구조

```text
PHOU
├── App
│   ├── PHOUApp.swift
│   ├── AppEnvironment.swift
│   └── RootView.swift
│
├── Features
│   ├── Gallery
│   │   ├── GalleryView.swift
│   │   ├── GalleryStore.swift
│   │   ├── GalleryState.swift
│   │   └── Components
│   │       ├── PhotoGridView.swift
│   │       └── PhotoThumbnailView.swift
│   │
│   ├── Cleanup
│   │   ├── CleanupView.swift
│   │   ├── CleanupStore.swift
│   │   ├── CleanupState.swift
│   │   ├── SwipeCleanupView.swift
│   │   ├── FinalReviewView.swift
│   │   └── Components
│   │       ├── SwipeCardView.swift
│   │       └── BestShotCompareView.swift
│   │
│   ├── Album
│   │   ├── AlbumListView.swift
│   │   ├── AlbumStore.swift
│   │   └── AlbumState.swift
│   │
│   └── Search
│       ├── SearchView.swift
│       ├── SearchStore.swift
│       ├── SearchState.swift
│       └── SearchResultView.swift
│
├── Domain
│   ├── Models
│   │   ├── PhotoAsset.swift
│   │   ├── CleanupCandidate.swift
│   │   └── SimilarPhotoGroup.swift
│   │
│   ├── Services
│   │   ├── CleanupRecommendationService.swift
│   │   ├── BestShotScoringService.swift
│   │   ├── SimilarPhotoDetectionService.swift
│   │   └── PhotoSearchIndexingService.swift
│   │
│   └── Repositories
│       ├── PhotoRepository.swift
│       └── KeepForeverRepository.swift
│
├── Infrastructure
│   ├── PhotoKit
│   │   ├── PhotoKitPhotoRepository.swift
│   │   ├── PhotoLibraryChangeObserver.swift
│   │   └── ThumbnailProvider.swift
│   │
│   ├── Vision
│   │   ├── VisionImageAnalyzer.swift
│   │   ├── BlurDetectionAnalyzer.swift
│   │   └── FaceAnalysisService.swift
│   │
│   ├── Persistence
│   │   ├── SwiftDataContainer.swift
│   │   └── SwiftDataKeepForeverRepository.swift
│   │
│   └── Cache
│       └── ThumbnailCache.swift
│
└── Shared
    ├── Components
    ├── Extensions
    ├── Utilities
    └── DesignSystem
```

| 계층 | 역할 |
| :--- | :--- |
| `App` | 앱 진입점, 전역 의존성 구성, 루트 화면 관리 |
| `Features` | 화면, Feature 단위 상태 Store, Feature 전용 UI 컴포넌트 관리 |
| `Domain` | 앱의 핵심 모델, 추천/분석/채점 로직, Repository 인터페이스 관리 |
| `Infrastructure` | PhotoKit, Vision, CoreML, SwiftData 등 플랫폼 의존 구현체 관리 |
| `Shared` | 공용 UI 컴포넌트, 유틸리티, 확장 기능, 디자인 시스템 관리 |

<br>

---

<br>

## 🔨 개발 환경
![Static Badge|67](https://img.shields.io/badge/Swift%206-%23F05138?logo=swift&logoColor=white)
![Static Badge|93](https://img.shields.io/badge/Xcode%2026%20~-%23147EFB?logo=xcode&logoColor=white)
![Static Badge|89](https://img.shields.io/badge/iOS%2017.0%20~%20-%23000000?logo=ios&logoColor=white)

<br>

---

<br>

## 👨‍💻 트러블 슈팅


<br>

---

<br>

## 📊 다이어그램
### 앱 전체 아키텍처


### 베스트 컷 채점 로직 (Scoring System Flow)


<br>

---

<br>

## 📱 주요 기능

1. **갤러리 탭** iOS 17 이전 스타일의 직관적인 Grid 형식 사진 뷰입니다.

| 라이트 모드                             | 다크 모드                                   |
| ---------------------------------- | --------------------------------------- |
| <img width="300" alt="갤러리" src=""> | <img width="300" alt="갤러리 - 다크" src=""> |

2. **사진 정리 추천 (스와이프 UI)** AI가 분석한 흔들린 사진, 비슷한 사진, 스크린샷 등을 스와이프하여 손쉽게 분류합니다.    

| 정리 중                                   | 베스트 컷 비교                                |
| -------------------------------------- | --------------------------------------- |
| <img width="300" alt="스와이프 정리" src=""> | <img width="300" alt="베스트 컷 비교" src=""> |

3. **최종 정리 확인 뷰** 스와이프를 통해 삭제하기로 한 사진들을 마지막으로 검토하고 일괄 삭제합니다.

| 라이트 모드                               | 다크 모드                                     |
| ------------------------------------ | ----------------------------------------- |
| <img width="300" alt="최종 확인" src=""> | <img width="300" alt="최종 확인 - 다크" src=""> |

4. **앨범 탭** 시스템 기본 앨범 및 사용자 생성 앨범을 나열합니다.

|라이트 모드|다크 모드|
|---|---|
|<img width="300" alt="앨범" src="">|<img width="300" alt="앨범 - 다크" src="">|

5. **AI 키워드 검색** 사진 내 객체나 텍스트를 분석하여 인터넷 연결 없이 온디바이스에서 키워드로 사진을 검색합니다.

| 라이트 모드                            | 다크 모드                                  |
| --------------------------------- | -------------------------------------- |
| <img width="300" alt="검색" src=""> | <img width="300" alt="검색 - 다크" src=""> |

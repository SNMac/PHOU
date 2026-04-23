## 1. 프로젝트 개요
- **프로젝트 명:** PHOU (PHoto Organizer for U)
- **개발 환경:** Swift, SwiftUI, iOS/iPadOS 18.0+
- **핵심 아키텍처:** TCA (The Composable Architecture) 기반 Clean Architecture
- **주요 목표:** iOS/iPadOS 17 이전의 클래식한 갤러리 앱 사용성을 제공함과 동시에, 온디바이스 AI를 활용하여 불필요한 사진과 동영상을 효율적으로 정리하는 경험 제공.

## 2. 기술 스택 (Tech Stack)
- **UI 프레임워크:** SwiftUI
- **상태 관리:** TCA (Action - Reducer - State의 단방향 데이터 흐름)
- **데이터 지속성:** SwiftData (영구 보존 대상 미디어의 `localIdentifier` 저장)
- **AI/머신러닝:** CoreML, Vision Framework (온디바이스 이미지/프레임 분석)
- **미디어 라이브러리 제어:** PhotoKit (`PHAsset`, `PHImageManager`, `PHPhotoLibrary`)
- **동영상 처리:** `AVFoundation` (`AVAssetImageGenerator`를 활용한 썸네일 및 키프레임 추출)

## 3. 주요 기능 (Core Features)
### ① 갤러리 탭 (Grid View)
- iOS/iPadOS 18 이전 스타일의 `LazyVGrid` 기반 미디어 목록.
- `PHImageManager`를 활용한 사진/동영상 썸네일 로드 및 캐싱 최적화.
- **동영상 식별:** 동영상 에셋 하단에 재생 시간(Duration) 배지 표시.

### ② 정리 추천 탭 (AI Cleanup)
- **추천 카테고리:**
    - **흔들린 미디어:** 선명도(Sharpness)가 낮은 사진 및 초점이 맞지 않거나 흔들림이 심한 동영상.
    - **비슷한 미디어:** 연속 촬영 이미지 및 너무 짧게 끊어 찍힌 유사 동영상 그룹.
    - **스크린샷/화면 녹화본:** `PHAssetMediaSubtype.photoScreenshot` 및 `videoScreenRecording` 필터링.
    - **대용량 미디어:** 기기 저장 공간 확보를 위해 용량이 크고 재생 시간이 긴 비활성 동영상 우선 추천.
    - **다운로드 미디어:** EXIF 메타데이터가 없거나 특정 조건에 부합하는 이미지/동영상.
- **정렬 기준:** 생성일(Creation Date) 및 수정일(Modification Date) 기반 오래된 순.

### ③ 앨범 탭 (Album List)
- 시스템 및 사용자 생성 앨범 목록 나열 (동영상 전용 스마트 앨범 포함).

### ④ AI 검색 탭 (AI Search)
- 온디바이스 키워드 인덱싱을 통한 자연어 기반 검색.
- 동영상의 경우 핵심 프레임(Keyframe)을 추출하여 객체 인식 후 태그 부여.

## 4. AI 미디어 분석 및 채점 시스템
비슷한 사진/동영상 그룹 내에서 보존할 '베스트 컷'을 결정하기 위한 온디바이스 채점 로직:
1. **사진 분석 기준:**
    - **선명도 (Sharpness):** 초점이 뚜렷한 사진에 높은 가점.
    - **인물 분석 (Face Analysis):** 눈을 제대로 뜬 상태(최우선), 미소, 카메라 정면 응시 여부에 따른 가점.
    - **구도 분석 (Saliency):** 주요 피사체가 안정적인 위치에 있는 사진에 가점.
2. **동영상 분석 추가 기준:**
    - **키프레임 추출 (Keyframe Extraction):** `AVFoundation`을 이용해 동영상을 초당/특정 간격 단위로 프레임을 분할하여 위의 사진 분석 기준(선명도, 인물 표정)을 동일하게 적용 후 평균 점수 산출.
    - **카메라 모션 (Camera Shake):** `Vision` 프레임워크를 활용해 프레임 간의 픽셀 변화량(Translational Registration)을 계산, 과도하게 떨리거나 바닥을 찍은 영상에 감점 부여.

## 5. 사용자 경험 (UX) 및 인터랙션
### 스와이프 기반 정리 (Tinder-style)
- **좌측 스와이프:** 삭제 후보군으로 이동.
- **우측 스와이프:** 이번 정리에서 제외(보존).
- **별도 버튼:** '영구 보존(Keep Forever)' - SwiftData에 저장하여 향후 추천 알고리즘에서 제외.
- **미디어 프리뷰:** 사진은 '베스트 컷'을 함께 노출하며, **동영상은 카드가 최상단에 위치할 때 무음으로 자동 재생(Auto-play) 또는 꾹 누르기(Long Press)로 미리보기**를 제공하여 지울 영상을 쉽게 판단할 수 있도록 지원.

### 최종 확인 (Final Review)
- 정리 세션 종료 전, 삭제하기로 결정한 미디어들을 `Grid` 형태로 모아보기.
- 일괄 삭제 요청 전, 개별 미디어의 선택을 취소할 수 있는 안전장치 제공.

## 6. 기술적 고려 사항 및 해결 방안
- **메모리 최적화:** 동영상의 썸네일과 키프레임 추출 작업은 메모리 소모가 극심함. `AVAssetImageGenerator` 사용 시 해상도를 낮추고, `TaskGroup`과 `AsyncStream`을 활용해 메모리에 한 번에 많은 이미지가 올라가지 않도록 동시성 제어 및 메모리 스파이크 방지.
- **데이터 무결성:** TCA의 `Effect`를 통해 `PHPhotoLibraryChangeObserver`를 구독하고, 시스템 갤러리 변경 사항을 앱 상태에 즉시 동기화.
- **프라이버시:** 모든 AI 분석 및 데이터 처리를 서버 전송 없이 **온디바이스(On-device)**에서 수행하여 사용자 신뢰 확보.
- **비즈니스 로직 독립성:** 채점 알고리즘 및 AI 분석 로직을 Domain 계층의 UseCase로 분리하여 테스트 코드 작성이 용이한 구조 설계.

## 7. 향후 확장 가능성
- 동영상 압축 (Video Compression): 무조건 삭제하는 대신, 대용량 동영상의 해상도나 프레임레이트를 낮춰 화질을 약간 희생하고 용량을 극적으로 줄이는 기능 추가.
- 사용자 맞춤형 AI 모델 학습 (사용자가 선호하는 구도나 인물을 학습).
- 미디어 내 텍스트(OCR) 기반의 고도화된 정리 기능.
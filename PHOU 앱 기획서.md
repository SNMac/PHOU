## 1. 프로젝트 개요
- **프로젝트 명:** PHOU
- **개발 환경:** Swift 6, SwiftUI, iOS 17.0+
- **핵심 아키텍처:** SwiftUI Observation 기반 Feature 중심 구조 + Domain / Infrastructure 계층 분리
- **주요 목표:** iOS/iPadOS 17 이전의 클래식한 사진 앱 사용성을 제공함과 동시에, 온디바이스 AI를 활용하여 불필요한 사진을 효율적으로 정리하는 경험 제공.

## 2. 기술 스택 (Tech Stack)
- **UI 프레임워크:** SwiftUI
- **상태 관리:** SwiftUI Observation (`@Observable`) 기반 Feature Store
- **아키텍처:** Feature 중심 구조 + Domain / Infrastructure 계층 분리
- **데이터 지속성:** SwiftData (영구 보존 대상 사진의 `localIdentifier` 저장)
- **AI/머신러닝:** CoreML, Vision Framework (온디바이스 이미지 분석)
- **사진 라이브러리 제어:** PhotoKit (`PHAsset`, `PHImageManager`, `PHPhotoLibrary`)

## 3. 주요 기능 (Core Features)
### ① 갤러리 탭 (Grid View)
- iOS/iPadOS 17 이전 스타일의 `LazyVGrid` 기반 사진 목록.
- `PHImageManager`를 활용한 썸네일 로드 및 캐싱 최적화.
- 갤러리 화면의 로딩 상태, 선택 상태, 표시 데이터를 `GalleryStore`에서 관리.

### ② 정리 추천 탭 (AI Cleanup)
- **추천 카테고리:**
    - **흔들린 사진:** 선명도(Sharpness)가 낮은 사진.
    - **비슷한 사진:** 연속 촬영 등 유사한 이미지 그룹.
    - **스크린샷:** `PHAssetMediaSubtype.photoScreenshot` 필터링.
    - **다운로드 사진:** EXIF 메타데이터가 없거나 특정 조건에 부합하는 이미지.
- **정렬 기준:** 생성일(Creation Date) 및 수정일(Modification Date) 기반 오래된 순.
- 스와이프 진행 상태, 삭제 후보군, 보존 후보군, 최종 확인 목록을 `CleanupStore`에서 관리.

### ③ 앨범 탭 (Album List)
- 시스템 및 사용자 생성 앨범 목록 나열.
- PhotoKit 기반 앨범 데이터 로딩 및 변경 감지 처리.

### ④ AI 검색 탭 (AI Search)
- 온디바이스 키워드 인덱싱을 통한 자연어 기반 사진 검색.
- Vision / CoreML 기반 이미지 분석 결과를 활용한 검색 인덱싱.

## 4. AI 사진 분석 및 채점 시스템
비슷한 사진 그룹 내에서 보존할 '베스트 컷'을 결정하기 위한 온디바이스 채점 로직:
1. **선명도 (Sharpness):** 초점이 뚜렷한 사진에 높은 가점.
2. **인물 분석 (Face Analysis):**
    - 눈을 제대로 뜨고 있는가? (Blink Detection) - 최우선 순위.
    - 미소를 짓고 있는가? (Smile Detection) - 가점.
    - 카메라 정면을 응시하는가? (Face Orientation) - 가점.
3. **구도 분석 (Saliency):** 주요 피사체가 안정적인 위치에 있는 사진에 가점.

## 5. 사용자 경험 (UX) 및 인터랙션
### 스와이프 기반 정리 (Tinder-style)
- **좌측 스와이프:** 삭제 후보군으로 이동.
- **우측 스와이프:** 이번 정리에서 제외(보존).
- **별도 버튼:** '영구 보존(Keep Forever)' - SwiftData에 저장하여 향후 추천 알고리즘에서 제외.
- **맥락 제공:** 비슷한 사진 그룹에서 스와이프 시, 현재 사진과 대조되는 **'베스트 컷'을 함께 노출**하여 삭제 근거 제시.

### 최종 확인 (Final Review)
- 정리 세션 종료 전, 삭제하기로 결정한 사진들을 `Grid` 형태로 모아보기.
- 일괄 삭제 요청 전, 개별 사진의 선택을 취소할 수 있는 안전장치 제공.

## 6. 기술적 고려 사항 및 해결 방안
- **메모리 최적화:** Unified Memory Architecture를 고려하여 무거운 AI 연산과 이미지 렌더링 시 메모리 스파이크 관리 (Downsampling 활용).
- **데이터 무결성:** `PHPhotoLibraryChangeObserver`를 활용하여 시스템 사진첩 변경 사항을 앱 상태와 즉시 동기화.
- **프라이버시:** 모든 AI 분석 및 데이터 처리를 서버 전송 없이 **온디바이스(On-device)**에서 수행하여 사용자 신뢰 확보.
- **Feature 중심 상태 관리:** 화면과 상태를 Feature 단위로 구성하여 기능별 독립성과 개발 생산성을 향상.
- **비즈니스 로직 분리:** 사진 분석, 베스트 컷 채점, 추천 로직 등을 Domain 계층의 Service 및 Repository로 분리하여 유지보수성과 테스트 용이성 확보.
- **플랫폼 의존성 분리:** PhotoKit, Vision, CoreML, SwiftData 등 Apple 프레임워크 의존 구현체를 Infrastructure 계층에 분리.

## 7. 향후 확장 가능성
- 사용자 맞춤형 AI 모델 학습 (사용자가 선호하는 구도나 인물을 학습).
- 사진 내 텍스트(OCR) 기반의 고도화된 정리 기능.

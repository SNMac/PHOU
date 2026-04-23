# Media Detail Viewer — 작업 체크리스트

**GitHub Issue**: #6  
**Last Updated**: 2026-04-23

---

## Phase 1: 범위 및 데이터 계약 확정 (S)

- [ ] **1-1** `Gallery`도 mixed media를 보여줄지 결정
  - 수용 기준: Issue #6의 "앱 전역 재사용 가능한 사진/동영상 뷰어" 목표와 실제 첫 적용 범위가 문서상 일치함
- [ ] **1-2** `MediaDetailFeature.State` 입력 형식 확정 (`items + currentIndex` 또는 `selectedID`)
  - 수용 기준: `Gallery`와 `AlbumPhotoGrid`가 같은 상태 생성 방식 사용 가능
- [ ] **1-3** presentation 방식 확정 (`fullScreenCover` 우선 검토)
  - 수용 기준: dismiss 흐름과 TCA presentation 연결 방식이 명시됨

---

## Phase 2: 데이터/의존성 준비 (M)

- [ ] **2-1** 필요 시 `PhotoLibraryClient`에 mixed media fetch API 추가 또는 기존 API 확장
  - 후보: `fetchMedia()`, 또는 `fetchPhotos()`를 범용화
- [ ] **2-2** 고해상도 이미지 로딩 경로 설계
  - 수용 기준: 썸네일과 별도로 detail quality 이미지를 안정적으로 요청 가능
- [ ] **2-3** 동영상 재생용 asset -> player item 변환 책임 위치 결정
  - 수용 기준: Feature/View/헬퍼 중 한 곳으로 책임이 분명함

---

## Phase 3: MediaDetail Feature/View 구현 (L)

- [ ] **3-1** `PHOU/Presentation/MediaDetail/MediaDetailFeature.swift` 생성
- [ ] **3-2** `PHOU/Presentation/MediaDetail/MediaDetailView.swift` 생성
- [ ] **3-3** 사진 상세 콘텐츠 구현
  - 1차 범위: 고해상도 표시, pinch-to-zoom, 로딩/실패 처리
- [ ] **3-4** 동영상 상세 콘텐츠 구현
  - 1차 범위: 재생, 페이지 이탈 시 정지, 기본 loading 처리
- [ ] **3-5** 좌우 paging UX 구현
  - 수용 기준: 현재 선택한 미디어가 명확히 바뀌고 index 기반 상태와 동기화됨
- [ ] **3-6** dismiss UI 및 상단 chrome 구현

---

## Phase 4: 소비처 연결 (M)

- [ ] **4-1** `GalleryFeature` / `GalleryView`에 media detail presentation 연결
- [ ] **4-2** `AlbumPhotoGridFeature` / `AlbumPhotoGridView`에 같은 뷰어 연결
- [ ] **4-3** 그리드 셀을 탭 가능한 컴포넌트로 정리
  - 수용 기준: 히트 타깃이 자연스럽고 기존 정사각형 셀 레이아웃 유지

---

## Phase 5: 검증 (M)

- [ ] **5-1** `xcodebuild` 빌드 성공
- [ ] **5-2** 갤러리에서 사진 상세 진입 확인
- [ ] **5-3** 앨범 상세에서 사진/동영상 혼합 목록 진입 확인
- [ ] **5-4** 사진 pinch-to-zoom 확인
- [ ] **5-5** 동영상 재생 및 페이지 이동 시 정지 확인
- [ ] **5-6** iPad 레이아웃/회전에서 기본 동작 이상 없는지 확인

---

## 후속 후보 (Out of Scope Unless Needed)

- [ ] 비디오 배지 / 재생 시간 오버레이
- [ ] 동영상 pinch-to-zoom
- [ ] 라이브 포토/버스트 등 특수 자산 표시 개선
- [ ] 상세 뷰에서 삭제/즐겨찾기 등 액션 추가

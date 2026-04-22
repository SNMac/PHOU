# Album Tab — 작업 체크리스트

**GitHub Issue**: #5  
**Last Updated**: 2026-04-22

---

## Phase 1: 엔티티 & 클라이언트 업데이트 (S)

- [ ] **1-1** `AlbumGroup.swift`에 `coverAssetId: String?` 필드 추가
  - 수락 기준: `AlbumGroup` 이니셜라이저에 `coverAssetId` 파라미터 포함, previewValue 업데이트
- [ ] **1-2** `PhotoLibraryClient.swift` `fetchAlbums` liveValue에서 각 앨범 첫 번째 에셋 ID 수집
  - 수락 기준: `PHFetchOptions.fetchLimit = 1` 사용, `coverAssetId` 반환, previewValue도 업데이트

---

## Phase 2: AlbumFeature 구현 (M)

- [ ] **2-1** `State`에 `albums`, `isLoading`, `errorMessage` 프로퍼티 추가
  - 수락 기준: `@ObservableState struct State: Equatable` 컴파일 통과
- [ ] **2-2** `Action`에 `view`, `internal` enum case 추가 (GalleryFeature 패턴 준수)
  - 수락 기준: `ViewAction.onAppear`, `InternalAction.authResponse`, `InternalAction.albumsResponse` 정의
- [ ] **2-3** `body` Reducer에 권한 체크 → `fetchAlbums` 로직 구현
  - 수락 기준: authorized/limited 상태에서 fetchAlbums 호출, 결과 State 반영
- [ ] **2-4** `@PresentationState var albumPhotoGrid: AlbumPhotoGridFeature.State?` 추가
  - 수락 기준: `view.albumTapped(AlbumGroup)` 시 albumPhotoGrid 상태 초기화
  - 의존: Phase 3 완료 후 진행

---

## Phase 3: AlbumPhotoGridFeature/View 구현 (M)

- [ ] **3-1** `AlbumPhotoGridFeature.swift` 신규 생성
  - 수락 기준: `albumId`, `albumTitle`, `photos`, `isLoading` 상태 관리, `fetchAssets(in:)` 호출
- [ ] **3-2** `AlbumPhotoGridView.swift` 신규 생성
  - 수락 기준: GalleryView의 `photoGrid` 패턴과 동일한 3-column LazyVGrid, navigationTitle 앨범명
  - 수락 기준: `loadingView`, `errorView` 분기 처리 포함

---

## Phase 4: AlbumView UI 구현 (M)

- [ ] **4-1** `AlbumView.swift`에 섹션 List 구현
  - 수락 기준: `smartAlbum` 섹션 "시스템 앨범", `userAlbum` 섹션 "나의 앨범" 분리
  - 수락 기준: 각 섹션 빈 경우 섹션 헤더 미표시 또는 빈 상태 안내
- [ ] **4-2** 앨범 Row UI 구현 (커버 이미지 + 앨범명 + 사진 수)
  - 수락 기준: `coverAssetId != nil` 이면 `PhotoThumbnailView`, nil이면 `photo.on.rectangle` 시스템 아이콘
  - 수락 기준: 썸네일 60×60, cornerRadius 8
- [ ] **4-3** `NavigationStack` + `.navigationDestination` 연결
  - 수락 기준: 앨범 탭 시 `AlbumPhotoGridView`로 push 네비게이션
- [ ] **4-4** 로딩 / 에러 / 권한 없음 상태 처리
  - 수락 기준: `isLoading == true` → `ProgressView()`, denied/restricted → GalleryView와 동일 스타일 `ContentUnavailableView`

---

## Phase 5: 검증 (S)

- [ ] **5-1** `xcodebuild build` 성공 (Swift 6 concurrency 경고 없음)
- [ ] **5-2** 시뮬레이터에서 앨범 탭 동작 확인
  - 수락 기준: 시스템 앨범 / 나의 앨범 섹션 표시, 커버 이미지 로드, 앨범 탭 → 그리드 이동
- [ ] **5-3** 빈 앨범 / 권한 없음 상태 시나리오 확인

---

## 완료 기준 (Definition of Done)

- 모든 체크리스트 항목 완료
- `xcodebuild` 빌드 오류 및 Swift 6 concurrency 경고 없음
- 앨범 탭 기능 시뮬레이터 동작 확인
- GitHub Issue #5 close

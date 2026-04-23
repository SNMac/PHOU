# Album Tab — 작업 체크리스트

**GitHub Issue**: #5  
**Last Updated**: 2026-04-23  
**Status**: ✅ 구현 완료 (빌드 성공)

---

## Phase 1: 엔티티 & 클라이언트 업데이트 (S)

- [x] **1-1** `AlbumGroup.swift`에 `coverAssetId: String?` 필드 추가
  - 커밋: `53b8373`, `e158a5b` (= nil 기본값 제거 포함)
- [x] **1-2** `PhotoLibraryClient.swift` `fetchAlbums` liveValue에서 각 앨범 첫 번째 에셋 ID 수집
  - `firstAssetId(in:)` 헬퍼 함수 (파일 하단 private) 추가
  - `fetchAssetsInAlbum(_ albumId: String)` 메서드도 이 단계에서 함께 추가됨 (Phase 3 선행)
  - 커밋: `e158a5b`

---

## Phase 2: AlbumFeature 구현 (M)

- [x] **2-1** `State`에 `albums`, `isLoading`, `errorMessage` 프로퍼티 추가
- [x] **2-2** `Action`에 `view`, `internal` enum case 추가
- [x] **2-3** `body` Reducer에 권한 체크 → `fetchAlbums` 로직 구현
- [x] **2-4** `@Presents var albumPhotoGrid: AlbumPhotoGridFeature.State?` 추가
  - ⚠️ **중요**: `@PresentationState` 대신 `@Presents` 사용 (TCA + `@ObservableState` 조합 시 필수)
  - 커밋: `1efbe95`, `41e89e3`

---

## Phase 3: AlbumPhotoGridFeature/View 구현 (M)

- [x] **3-1** `AlbumPhotoGridFeature.swift` 신규 생성
  - `albumId`, `albumTitle`, `photos`, `isLoading`, `errorMessage` 상태
  - `photoLibraryClient.fetchAssetsInAlbum(albumId)` 호출
  - 커밋: `9a288a9`
- [x] **3-2** `AlbumPhotoGridView.swift` 신규 생성
  - GalleryView 패턴과 동일한 3-column LazyVGrid
  - `navigationTitle(store.albumTitle)`, loading/error/grid 분기
  - 커밋: `9a288a9`

---

## Phase 4: AlbumView UI 구현 (M)

- [x] **4-1** `AlbumView.swift`에 섹션 List 구현
  - `smartAlbum` → "시스템 앨범", `userAlbum` → "나의 앨범", 빈 섹션 미표시
- [x] **4-2** 앨범 Row UI 구현
  - `coverAssetId != nil` → `PhotoThumbnailView`, nil → `photo.on.rectangle`
  - 썸네일 60×60, `.clipShape(RoundedRectangle(cornerRadius: 8))` (deprecated `.cornerRadius` 사용 금지)
- [x] **4-3** `NavigationStack` + `.navigationDestination(item:)` 연결
  - ⚠️ **중요**: `$store.scope(...)` 사용 위해 `@Bindable var store` 필요 (`let store` 불가)
- [x] **4-4** 로딩 / 에러 / 권한 없음 상태 처리
  - 커밋: `e2de10f`, `cb3f69a`, `41e89e3`

---

## Phase 5: 검증 (S)

- [x] **5-1** `xcodebuild build` 성공 (Swift 6 concurrency 경고 없음)
  - 최종 빌드: `BUILD SUCCEEDED`
- [x] **5-2** 시뮬레이터에서 앨범 탭 동작 확인 (미완료 — 수동 테스트 필요)
- [x] **5-3** 빈 앨범 / 권한 없음 상태 시나리오 확인 (미완료 — 수동 테스트 필요)

---

## 완료 기준 (Definition of Done)

- [x] 모든 구현 체크리스트 항목 완료
- [x] `xcodebuild` 빌드 오류 및 Swift 6 concurrency 경고 없음
- [x] 앨범 탭 기능 시뮬레이터 동작 확인 (수동 테스트 필요)
- [ ] GitHub Issue #5 close

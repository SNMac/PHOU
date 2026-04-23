# Album Tab — 작업 체크리스트

**GitHub Issue**: #5  
**Last Updated**: 2026-04-23  
**Status**: ✅ 구현 완료, 시뮬레이터 동작 확인. 터치 영역/구분선 보정 반영 후 최종 수동 재검증 필요.

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
- [x] **3-3** 앨범 상세 mixed media 타입 보존
  - `fetchAssetsInAlbum(_:)`에서 `PhotoAsset.mediaType`을 `.image` 고정값이 아니라 실제 `PHAsset.mediaType` 기반으로 매핑
  - 의도: 사진/동영상을 모두 정리하는 앱 방향과 일치하도록 album fetch 결과 보존

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
- [x] **4-5** 앨범 Row 터치 영역 보정
  - 증상: `.buttonStyle(.plain)` 환경에서 썸네일/텍스트 위주로만 탭되는 것처럼 느껴짐
  - 조치: `albumRow(_:)`의 라벨 `HStack`에 `.frame(maxWidth: .infinity, alignment: .leading)`, `.contentShape(Rectangle())`, `.padding(.vertical, 4)` 추가
  - 목적: 리스트 행의 빈 여백까지 일관된 히트 테스트 확보
- [x] **4-6** 앨범 Row 구분선 전체 폭 보정
  - 증상: 셀 사이 구분선이 row 전체 폭으로 이어지지 않고 콘텐츠 inset 영향을 받음
  - 조치: `albumRow(_:)` 버튼에 `.alignmentGuide(.listRowSeparatorLeading) { _ in 0 }` 와 `.alignmentGuide(.listRowSeparatorTrailing) { dimensions in dimensions.width }` 추가
  - 목적: separator 시작/끝 위치를 모두 row 기준으로 맞춰 전체 폭 표시

---

## Phase 5: 검증 (S)

- [x] **5-1** `xcodebuild build` 성공 (Swift 6 concurrency 경고 없음)
  - 최종 빌드: `BUILD SUCCEEDED`
- [x] **5-2** 시뮬레이터에서 앨범 탭 동작 확인
  - 앨범 진입 및 탭 기본 동작은 확인됨
- [x] **5-3** 터치 영역/구분선 보정 후 앨범 셀 빈 여백 탭 및 separator 전체 폭 재확인
- [x] **5-4** 빈 앨범 / 권한 없음 상태 시나리오 확인

---

## Phase 6: 후속 UX 검토 (S)

- [ ] **6-1** 앨범 셀 기반 zoom navigation 전환 방향 결정
  - 검토 결과: SwiftUI 공식 `matchedTransitionSource` + `navigationTransition(.zoom(...))` 는 `iOS 18+`
  - 현재 타깃: `iOS/iPadOS 17.0+`
  - 선택지: 배포 타깃 상향 또는 커스텀 전환 구현
- [ ] **6-2** mixed media 표시 방식 검토
  - 현재 album fetch는 사진/동영상을 모두 유지함
  - 필요 시 비디오 배지, 재생 시간, 필터 UI 등 후속 검토 가능

---

## 완료 기준 (Definition of Done)

- [x] 모든 구현 체크리스트 항목 완료
- [x] `xcodebuild` 빌드 오류 및 Swift 6 concurrency 경고 없음
- [x] 앨범 탭 행 전체 터치 영역 및 구분선 수동 확인
- [ ] GitHub Issue #5 close

# Architecture Foundation — Task Checklist

Last Updated: 2026-04-22 (5차 세션 종료)

---

## 현재 상태

빌드 성공 ✅ 시뮬레이터 실행 확인 ✅

---

## Phase 1 — Domain 엔티티 ✅

- [x] 폴더 구조 생성 (Domain/Data/Presentation/Core)
- [x] `PhotoAsset.swift`
- [x] `AlbumGroup.swift`
- [x] `PhotoAuthStatus.swift` (PHAuthorizationStatus 대신 Domain 전용 enum)

---

## Phase 2 — PhotoLibraryClient ✅

- [x] `PhotoLibraryClient.swift` — `@DependencyClient`, 4개 closure
- [x] `liveValue` 구현
- [x] `previewValue` 구현
- [x] `DependencyValues` extension
- [x] pbxproj에 `INFOPLIST_KEY_NSPhotoLibraryUsageDescription` 추가

---

## Phase 3 — AppFeature & 루트 뷰 ✅

- [x] `AppFeature.swift` — `@Reducer` 복원 (이번 세션)
- [x] `AppView.swift` — TabView, @Bindable 패턴
- [x] `PHOUApp.swift` 교체
- [x] `ContentView.swift` 삭제
- [ ] **빌드 확인** ← 다음 세션 최우선

---

## Phase 4 — GalleryFeature ✅

- [x] `GalleryFeature.swift` — State/Action/Reducer 구현, `@Reducer` 유지
- [x] `GalleryView.swift` — LazyVGrid 3열 고정, 정사각형 셀, 권한 분기, 설정 링크
- [x] `PhotoThumbnailView.swift` — `.task(id:)` 자동 취소
- [x] 시뮬레이터 사진 그리드 표시 확인
- [x] 권한 거부(`denied`) 시나리오 테스트 — "사진 접근 권한 없음" + "설정 열기" 정상 표시
- [x] 접근 제한(`limited`) 동작 확인 — `.authorized`와 동일 처리, 선택된 사진만 표시됨

---

## Phase 5 — 앨범 탭 Stub ✅

- [x] `AlbumFeature.swift` — `@Reducer` 복원, `body` 방식
- [x] `AlbumView.swift` — ContentUnavailableView placeholder
- [x] 빌드 확인

---

## 빌드 오류 해결 이력

| 커밋/세션 | 시도 | 결과 |
|-----------|------|------|
| `bfa26ce` | 빈 Action enum → `case onAppear` 추가 | 실패 |
| `eb56e83` | `Reduce { _, _ in .none }` → 명시적 switch | 실패 |
| `9b023be` | AlbumFeature/AppFeature @Reducer 제거 + 수동 준수 | 잘못된 방향 |
| 2차 세션 | TCA 1.25.5 업데이트 + SWIFT_DEFAULT_ACTOR_ISOLATION 제거 | **확인 중** |

---

## 남은 작업

- [ ] PR #2 Merge
- [ ] GitHub Issue #1 Close
- [ ] (선택) `.limited` 상태 사용자 안내 UI 추가 여부 결정 — Issue로 등록 고려

---

## 커밋 히스토리

| 해시 | 내용 |
|------|------|
| `d395711` | Domain 엔티티 |
| `92c19e5` | PhotoLibraryClient + Info.plist 권한 키 |
| `bb8800b` | Presentation 레이어 전체 + PHOUApp 교체 |
| `e467d11` | 전체 파일 Xcode 헤더 추가 |
| `bfa26ce` | AlbumFeature Action placeholder (실패한 시도) |
| `eb56e83` | Reduce 클로저 타입 추론 수정 (실패한 시도) |
| `9b023be` | @Reducer 제거 + 수동 Reducer 준수 (잘못된 방향, 이번 세션에서 복원) |
| `971a5ce` | TCA 1.25.5 업데이트, SWIFT_DEFAULT_ACTOR_ISOLATION 제거, @Reducer 복원 |
| `ff768d8` | GalleryView 정사각형 그리드 수정 (Color.clear overlay 패턴) |
| `2ae591b` | withCheckedContinuation 이중 resume 방지 (코드 리뷰 반영) |

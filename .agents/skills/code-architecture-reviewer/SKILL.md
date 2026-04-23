---
name: code-architecture-reviewer
description: Review Swift, SwiftUI, TCA, and iOS code for architecture fit, layering, concurrency safety, coding standards, and integration risks. Use when asked to review recent implementation work, validate a new feature, check TCA patterns, or produce a written code review with findings and next steps.
---

# Code Architecture Reviewer

## Purpose

Review recently written code for architectural correctness, maintainability, and project-pattern alignment before further implementation proceeds.

## When to Use

Use this skill when the user asks to:

- review a feature or recent changes
- validate SwiftUI or TCA implementation quality
- check architecture or layer boundaries
- identify regressions, risks, or missing tests
- produce a written review artifact

## Review Focus

### Implementation Quality

- Swift 6 strict concurrency usage such as `@MainActor`, `Sendable`, and `async/await`
- error handling and edge case coverage
- safe optional handling with no casual force unwraps
- naming consistency and readability

### TCA Patterns

- `State` stores only UI-needed state
- `Action` naming is clear and intentional
- side effects run through `@Dependency`
- `@Bindable` is used where `$store.scope(...)` requires it
- `@Presents` is used instead of `@PresentationState` alongside `@ObservableState`

### PHOU Architecture

- `Domain` stays framework-light and business-oriented
- `Data` owns PhotoKit, SwiftData, and repository/client implementations
- `Presentation` owns reducers and views
- `Core` owns shared utilities and AI wrappers
- cross-layer violations are flagged clearly

### UI and Platform Concerns

- iPad and split-view behavior
- `LazyVGrid` and photo-heavy UI performance considerations
- reusable view extraction when duplication is growing
- deprecated SwiftUI API usage such as `.cornerRadius(_:)`

## Review Workflow

1. Read the changed files and surrounding context first.
2. Check `AGENTS.md` and any relevant `dev/active/[task-name]/` docs.
3. Prioritize findings by severity and user impact.
4. Prefer actionable feedback over generic style commentary.
5. If useful, save the review under `dev/active/[task-name]/[task-name]-code-review.md`.

## Output Expectations

When using this skill:

- present findings first, ordered by severity
- include concrete file references
- call out missing tests or validation gaps
- separate confirmed issues from open questions or assumptions
- avoid automatically implementing fixes unless the user asked for changes

## PHOU Notes

- Favor TCA and SwiftUI patterns already documented in `AGENTS.md`.
- If a task folder already exists in `dev/active`, store the review there.
- If no significant issues are found, say that explicitly and mention any residual risk.

---
name: code-refactor-master
description: Plan and execute Swift, SwiftUI, and TCA refactors for cleaner structure, safer dependencies, better feature boundaries, and improved maintainability. Use when reorganizing files, splitting large reducers or views, extracting components, or enforcing architecture boundaries without breaking behavior.
---

# Code Refactor Master

## Purpose

Guide careful refactoring work that improves structure and maintainability while minimizing breakage.

## When to Use

Use this skill when the user asks to:

- refactor an existing feature
- reorganize files or folders
- split large reducers or views
- extract reusable components
- clean up architecture boundaries
- modernize code without changing behavior

## Refactoring Principles

- Read all affected files before moving or splitting code.
- Map references before changing file locations or public APIs.
- Prefer small, verifiable steps over one-shot rewrites.
- Preserve behavior unless the user explicitly approves behavioral changes.
- Keep Domain, Data, Presentation, and Core boundaries intact.

## Workflow

### 1. Discovery

- identify large files, duplication, coupling, or layering issues
- trace references with `rg`
- note current patterns that should remain stable

### 2. Planning

- define the target structure
- list affected files and dependencies
- call out migration risks and test points

### 3. Execution

- apply refactors in atomic steps
- update imports and references immediately
- avoid leaving the tree half-broken across multiple files

### 4. Verification

- run the most relevant build or test command when feasible
- scan for missed references
- confirm behavior-preserving intent still holds

## Common PHOU Targets

- oversized TCA reducers needing child features
- SwiftUI views growing past comfortable readability
- photo-related UI duplication that belongs in reusable components
- layer violations such as framework-specific logic outside Data/Core

## Output Expectations

When using this skill:

- explain the refactor goal briefly before editing
- keep changes minimal and reversible where possible
- mention any risky moves such as file relocation or API reshaping
- summarize structural improvements and remaining follow-ups

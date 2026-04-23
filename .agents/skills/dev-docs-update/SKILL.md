---
name: dev-docs-update
description: Refresh existing dev/active task docs with current implementation state, decisions, changed files, discovered issues, unfinished work, handoff notes, and next steps. Use when asked to update dev docs, prepare handoff notes, capture session context, or refresh plan/context/tasks before stopping.
---

# Dev Docs Update

## Purpose

Refresh persistent task documentation so someone can resume the work without reconstructing hidden context from memory.

## When to Use

Use this skill when the user asks to:

- update `dev/active` docs
- capture session context before stopping
- write handoff notes
- document progress on a currently active task
- refresh `context` or `tasks` after implementation work

This skill is most valuable near the end of a long work session or before switching topics.

## Workflow

1. Find the relevant task directory under `dev/active/`.
2. Read the existing `plan`, `context`, and `tasks` files first.
3. Inspect the changed code and current git/worktree state as needed.
4. Update the docs instead of rewriting them from scratch.
5. Refresh the `Last Updated: YYYY-MM-DD` date in edited docs.

## Required Updates

### Context File

Update `[task-name]-context.md` with:

- current implementation state
- key technical decisions from this session
- files changed and why
- blockers, caveats, or follow-up risks
- next immediate steps

### Tasks File

Update `[task-name]-tasks.md` with:

- completed tasks marked done
- newly discovered tasks added
- in-progress tasks clarified
- priorities reordered when reality changed

### Plan File

Update `[task-name]-plan.md` only when the actual direction changed:

- revised scope
- changed implementation phases
- new risks or dependencies
- updated success criteria

## Handoff Focus

Prioritize information that is hard to reconstruct later, such as:

- subtle bugs already diagnosed
- non-obvious architectural decisions
- integration points
- commands still worth running
- temporary workarounds needing cleanup
- exact files currently in motion

## Quality Bar

- Preserve useful existing structure.
- Avoid noisy churn or date-only edits with no substance.
- Write for fast resumption by a future agent or human.
- Be specific about file paths and current status.

## Output Pattern

After updating the docs, briefly tell the user:

- which task docs were refreshed
- what changed materially
- any unfinished or risky items that remain

## PHOU Notes

For this repository:

- active work usually lives under `dev/active/[task-name]/`
- align notes with existing TCA, SwiftUI, and PhotoKit conventions
- if multiple task folders are active, update only the relevant one unless the user asks for a broad sweep

---
name: dev-docs
description: Create persistent development task docs under dev/active for implementation planning, task breakdown, handoff-ready context, execution checklists, phased plans, and active work tracking. Use when asked to create dev docs, plan a feature, set up dev/active, write plan/context/tasks files, or document a new implementation effort.
---

# Dev Docs

## Purpose

Create persistent task documentation under `dev/active/[task-name]/` so implementation context survives long sessions, model resets, and handoffs.

## When to Use

Use this skill when the user asks to:

- create `dev/active/...` documentation
- make a plan before implementation
- break work into phases or checklists
- document a feature, refactor, bugfix, or migration
- preserve implementation context for future sessions

This skill is especially useful for multi-file work, non-trivial refactors, and tasks likely to span multiple conversations.

## Workflow

1. Read the relevant code and existing docs first.
2. Infer a short, filesystem-safe task name in kebab-case.
3. Create `dev/active/[task-name]/`.
4. Create three files:
   - `[task-name]-plan.md`
   - `[task-name]-context.md`
   - `[task-name]-tasks.md`
5. Add `Last Updated: YYYY-MM-DD` near the top of each file.
6. Keep the docs practical and easy to resume from later.

## File Expectations

### 1. Plan

`[task-name]-plan.md` should include:

- brief summary of the goal
- current state analysis
- proposed future state
- implementation phases
- risks and mitigations
- success criteria

Prefer clear headings and concrete technical detail over generic project-management language.

### 2. Context

`[task-name]-context.md` should include:

- relevant file paths
- important architecture notes
- implementation decisions already made
- tricky constraints, gotchas, and dependencies
- known blockers or open questions
- next immediate steps

Capture information that would be annoying to rediscover from code alone.

### 3. Tasks

`[task-name]-tasks.md` should include:

- checkbox checklist grouped by phase
- task size hints like `S/M/L` when useful
- acceptance criteria where it clarifies intent
- current status markers such as `- [x]`, `- [ ]`

The task list should be execution-oriented, not a duplicate of the plan.

## Quality Bar

- Read before writing; do not invent repository structure blindly.
- Prefer project terminology already used in code or docs.
- Keep plans detailed enough to execute but compact enough to scan quickly.
- Include concrete file paths whenever possible.
- Bias toward minimal, maintainable implementation steps.

## Output Pattern

After writing the docs, briefly tell the user:

- which task directory was created
- the main scope captured
- any assumptions you made

## PHOU Notes

For this repository:

- write docs under `dev/active/`
- reflect existing TCA and SwiftUI patterns from `AGENTS.md`
- prefer task names like `album-tab`, `ai-search`, `delete-review-flow`
- if docs already exist for the same task, update them instead of creating duplicates

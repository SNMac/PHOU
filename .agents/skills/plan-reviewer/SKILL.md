---
name: plan-reviewer
description: Review implementation plans for completeness, feasibility, missing risks, dependency issues, testing gaps, rollback concerns, and better alternatives. Use when a plan exists and needs critique before coding begins, especially for integrations, migrations, larger features, or high-risk changes.
---

# Plan Reviewer

## Purpose

Stress-test an implementation plan before code is written so hidden risks and missing work are surfaced early.

## When to Use

Use this skill when the user asks to:

- review a plan before implementation
- sanity-check a migration or integration strategy
- look for missing edge cases or rollback steps
- compare alternatives to a proposed approach

## Review Areas

- current-state understanding
- missing dependencies or compatibility issues
- data flow and state-management implications
- testing strategy and validation gaps
- rollout, rollback, and failure handling
- performance, security, and maintainability tradeoffs

## Workflow

1. Read the actual plan and the relevant code context.
2. Decompose the plan into concrete steps.
3. Challenge assumptions and look for omitted work.
4. Distinguish blocking issues from optional improvements.
5. Suggest safer or simpler alternatives when they are genuinely better.

## Output Expectations

Structure the response around:

- executive summary
- critical issues
- missing considerations
- recommended changes
- residual risks

If the plan is solid, say so clearly instead of manufacturing problems.

## PHOU Notes

- Consider TCA integration details, PhotoKit authorization flow, SwiftData threading, and iPad UI implications where relevant.
- Prefer project-specific advice over generic architecture theory.

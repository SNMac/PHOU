---
name: refactor-planner
description: Analyze the current code structure and create a detailed, phased refactoring plan with risks, dependencies, acceptance criteria, and verification steps. Use when a refactor is being considered and the team wants a pragmatic plan before making code changes.
---

# Refactor Planner

## Purpose

Create a practical refactoring plan that balances code quality gains against migration risk and team effort.

## When to Use

Use this skill when the user asks to:

- plan a refactor
- improve code organization before editing
- assess technical debt in a feature or subsystem
- restructure a large reducer, view, or module

## Planning Workflow

1. Read the current implementation and adjacent dependencies.
2. Identify the main pain points:
   - oversized files
   - duplication
   - weak boundaries
   - poor testability
   - naming or structure drift
3. Define a target structure that matches existing project conventions.
4. Break the work into phases with low-risk sequencing.
5. Add validation steps and rollback considerations.

## Plan Contents

A good refactor plan should include:

- executive summary
- current state analysis
- identified issues and opportunities
- phased refactoring steps
- affected files and dependencies
- risk assessment and mitigations
- testing strategy
- success criteria

## Output Expectations

- favor incremental phases over large-bang rewrites
- include concrete file paths and examples where useful
- call out behavior-preserving assumptions
- align the plan with existing `dev/active` documentation if present

## PHOU Notes

- Respect the repository's Domain/Data/Presentation/Core split.
- Prefer TCA-native decomposition patterns for large features.
- Be explicit about Swift 6 concurrency and PhotoKit-related risks.

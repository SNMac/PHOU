---
name: skill-developer
description: Create and manage Codex project skills under .agents/skills. Use when creating new skills, converting Claude assets into Codex skills, improving skill descriptions, or understanding how local skill discovery works in this repository. Covers skill structure, YAML frontmatter, progressive disclosure, description quality, and project-specific migration guidance.
---

# Skill Developer Guide

## Purpose

Guide for creating and maintaining Codex-compatible local skills in this repository.

## When to Use

Use this skill when working on:

- creating or adding skills
- converting Claude commands or agents into Codex skills
- improving skill descriptions or structure
- understanding how local skill discovery works
- organizing reference material for a skill

## Skill Layout

Store project-local skills at:

`./.agents/skills/{skill-name}/SKILL.md`

Use one directory per skill. Add extra reference files only when they materially improve the skill and keep them near the skill.

## Required Frontmatter

Each skill should begin with:

```markdown
---
name: my-skill
description: Clear description with the terms users are likely to mention when this skill should apply.
---
```

The `description` matters because Codex uses the skill list and descriptions to match skills to tasks.

## Recommended Structure

A good `SKILL.md` usually contains:

1. Purpose
2. When to Use
3. Workflow or Key Information
4. Output Expectations
5. Project-specific notes when needed

## Best Practices

- Keep `SKILL.md` focused and usually under 500 lines.
- Put likely user wording into the description.
- Prefer concrete repository terms over generic jargon.
- Use progressive disclosure: keep the main skill short and move details to nearby references when needed.
- Write instructions that help execution, not just explanation.
- Keep local file paths accurate.

## Creating a New Skill

1. Choose a short kebab-case skill name.
2. Create `.agents/skills/{skill-name}/SKILL.md`.
3. Add frontmatter with a strong, discoverable description.
4. Add a concise workflow and project-specific guidance.
5. Mentally test the description against a few realistic prompts.

## Migrating From Claude

When converting `.claude/...` assets into Codex skills:

- Claude `/commands/*.md` usually become one focused `SKILL.md`
- Claude `/agents/*.md` usually become domain skills with a clear workflow
- replace `.claude/CLAUDE.md` references with `AGENTS.md` or local project docs
- remove Claude-only slash-command or hook assumptions
- do not copy unsupported `.Codex/hooks` or `skill-rules.json` instructions unless they actually exist in the current project

## What To Avoid

- references to nonexistent hook files
- instructions that depend on Claude-only command infrastructure
- repository-agnostic filler that does not help future execution
- overly long skills that hide the main workflow

## PHOU Notes

- This repository already uses `AGENTS.md` and `dev/active/...` as durable guidance layers.
- Skills here should reinforce those rules rather than replace them.
- For planning and handoff work, prefer the existing `dev-docs` and `dev-docs-update` skills.

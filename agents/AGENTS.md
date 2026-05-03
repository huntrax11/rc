# Instructions

This machine uses a Claude Code configuration structure as the single source of truth for AI coding agent instructions. Read and follow the files described below.

## Mandatory session initialization

Before performing any task, answering any question, or providing any summary, first read and internalize:

1. `~/.claude/CLAUDE.md`
2. All `CLAUDE.md` files in the current workspace/repository hierarchy, from broader scope to narrower scope

This is not lazy-loaded. Do not answer from conversation context alone until these files have been read. If a required file is missing or unreadable, say so briefly and continue with the files that are available.

## Global rules

Read `~/.claude/CLAUDE.md`. It contains universal coding rules, style preferences, and working-style guidelines that apply to all projects.

### Language and stack guides

`~/.claude/CLAUDE.md` references detailed guides stored in:

- `~/.claude/lang/*.md` — language-specific rules (e.g. Python)
- `~/.claude/stack/*.md` — stack/tool-specific rules (e.g. Kubernetes, Redis, MySQL)

These files are lazy-loaded. Read the relevant guide when:

- `~/.claude/CLAUDE.md` points to it and the current task touches that language or stack.
- The user asks about rules for that language or stack.
- You are about to edit, review, design, or debug code involving that language or stack.

Do not eagerly read unrelated language/stack guides.

## Workspace and project rules

In any git repository, look for `CLAUDE.md` files along the current repo hierarchy only. Determine the repo root with `git rev-parse --show-toplevel`, then read `CLAUDE.md` files from the workspace root down to the repo root and current subdirectory, if applicable. Each level may contain scope-specific rules:

- `~/Dev/<workspace>/CLAUDE.md` — workspace-level (shared across repos under one org)
- `~/Dev/<workspace>/<repo>/CLAUDE.md` — project-level (repo-specific)

Read all `CLAUDE.md` files found in the hierarchy. Narrower scope takes precedence over broader scope.

Do not scan sibling repositories or broad parent directories unless the user explicitly asks.

## Updating rules

`~/.claude/CLAUDE.md` contains a "Documentation" section that describes how to classify and persist new rules. Follow that process — update `~/.claude/CLAUDE.md`, `~/.claude/lang/`, `~/.claude/stack/`, or the appropriate workspace/project `CLAUDE.md` directly. All AI coding agents on this machine share these files as a single source of truth.

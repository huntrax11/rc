# RC Repo Rules

## Settings Management

- Do not commit employer-specific or environment-specific settings to this repo. These belong in the local machine only. Examples: MCP servers, plugins, API keys, internal artifact registries (pypi, npm, docker), VPN configs, proxy settings, employer-specific git config (already separated via `~/.gitconfig.local`).

## Scope Boundaries

- `claude/CLAUDE.md` is the universal CLAUDE.md (symlinked to `~/.claude/CLAUDE.md`). Only put rules that apply regardless of employer or domain. Never add project-specific or workspace-specific content there.
- `claude/lang/*.md` and `claude/stack/*.md` follow the same scope constraint — universal rules only, no employer-specific or project-specific content.

## Symlink Structure

- Files in this repo are symlinked to the home directory via `setup.sh`. When renaming or moving files, update the symlink mappings in `setup.sh` accordingly.

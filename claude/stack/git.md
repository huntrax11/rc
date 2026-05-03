# Git Branching Strategy

## Base Model — Git-Flow Variant

Follow git-flow (`main` ← `develop` ← `feature/*`, plus `hotfix/*` off `main`) as the default, with two sanctioned deviations:

1. **Skip `develop`** when the repo is small or the team merges features directly to `main` behind feature flags / short-lived branches. In this case `main` plays both roles.
2. **Mix in `deploy/YYMM` branches** for staged rollouts (see below). These coexist with, not replace, the normal flow.

Choose whichever combination fits the repo and document the choice in that repo's CLAUDE.md or README.

## Deploy Branches — `deploy/YYMM`

Temporary deployment branches for features that are not yet fully tested or need parameter finalization after a dry-run deploy.

- Create `deploy/YYMM` from the main integration branch (`develop` or `main`).
- Always pull the deploy branch before merging a feature into it.
- Merge feature branches into `deploy/YYMM` with `--no-ff` (preserve merge commits).
- When testing is complete, squash-merge or clean-merge the feature back to its origin branch — not from the deploy branch.
- The deploy branch is disposable; it never flows back into the main line.
- When the deploy period ends, diff the deploy branch against the base branch to verify no feature was left unmerged.

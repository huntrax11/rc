#!/usr/bin/env bash
set -euo pipefail

if ! command -v claude &>/dev/null; then
  echo "scope-check: claude CLI not found, skipping"
  exit 0
fi

repo_root=$(git rev-parse --show-toplevel)
rules=$(cat "$repo_root/CLAUDE.md" 2>/dev/null) || {
  echo "scope-check: CLAUDE.md not found, skipping"
  exit 0
}

review_range() {
  local range=$1
  local diff

  diff=$(git diff "$range" 2>/dev/null) || return 0

  if [ -z "$diff" ]; then
    echo "scope-check: no changes in $range"
    return 0
  fi

  echo "scope-check: reviewing changes ($range)..."

  local result
  result=$(git diff "$range" | claude -p "You are a pre-push review bot for a personal dotfiles repository.

Repository rules:
---
$rules
---

Check the diff on stdin for violations of these rules.

Respond with EXACTLY one line:
- No violations found: PASS
- Violations found: FAIL: <one-line description of violations>" --model haiku 2>/dev/null) || {
    echo "scope-check: claude CLI failed, skipping"
    return 0
  }

  if echo "$result" | grep -q "FAIL"; then
    echo ""
    echo "scope-check: VIOLATIONS FOUND"
    echo "$result"
    echo ""
    return 1
  fi

  echo "scope-check: $result"
}

# Standalone: ./hooks/scope-check.sh [range]
#   e.g. ./hooks/scope-check.sh main..HEAD
# Pre-push: receives refs on stdin from git
if [ $# -gt 0 ]; then
  review_range "$1"
  exit $?
fi

while read -r local_ref local_sha remote_ref remote_sha; do
  if [ "$local_sha" = "0000000000000000000000000000000000000000" ]; then
    continue
  fi

  if [ "$remote_sha" = "0000000000000000000000000000000000000000" ]; then
    range="main..$local_sha"
  else
    range="$remote_sha..$local_sha"
  fi

  review_range "$range" || exit 1
done

exit 0

#!/usr/bin/env bash
# PreToolUse (Bash): refuse `git commit` while on main/master. CLAUDE.md: never commit directly to main.
cmd=$(jq -r '.tool_input.command // empty')

if ! printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)'; then
  exit 0
fi

branch=$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" symbolic-ref --short HEAD 2>/dev/null) || exit 0

if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  echo "Blocked: never commit directly to '$branch'. Create a branch first (feat/<name>, fix/<name> or chore/<name>), then commit." >&2
  exit 2
fi
exit 0

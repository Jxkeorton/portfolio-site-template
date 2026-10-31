#!/usr/bin/env bash
# PreToolUse (Edit|Write): block edits to env files (secrets) and build output.
file=$(jq -r '.tool_input.file_path // empty')
[ -z "$file" ] && exit 0

root="${CLAUDE_PROJECT_DIR:-$PWD}"
base=$(basename "$file")

case "$base" in
  .env.example) exit 0 ;;
  .env | .env.*)
    echo "Blocked: $base may hold secrets. Edit env files yourself; ask Claude to describe the variables needed instead." >&2
    exit 2
    ;;
esac

case "$file" in
  "$root"/dist/* | dist/*)
    echo "Blocked: dist/ is build output. Change the source and run pnpm build instead." >&2
    exit 2
    ;;
esac
exit 0

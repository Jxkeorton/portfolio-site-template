#!/usr/bin/env bash
# PreToolUse (Bash): enforce pnpm-only and ask before adding dependencies that are not pre-approved.
# Pre-approved list mirrors CLAUDE.md (skill-recommended deps) plus the tooling named in SETUP.md.
APPROVED="@sanity/astro astro-portabletext @sanity/image-url groq vitest oxlint oxfmt"

cmd=$(jq -r '.tool_input.command // empty')

emit() {
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
}

# npm and yarn are not used in this project
if printf '%s' "$cmd" | grep -Eq '(^|[;&|(]|&&)[[:space:]]*(npm|yarn)([[:space:]]|$)'; then
  emit deny "This project uses pnpm only. Use the pnpm equivalent."
  exit 0
fi

# pnpm add / install <pkg> / i <pkg>
if printf '%s' "$cmd" | grep -Eq '(^|[;&|(]|&&)[[:space:]]*pnpm[[:space:]]+(add|install|i)([[:space:]]|$)'; then
  unapproved=""
  seg=$(printf '%s' "$cmd" | sed -E 's/.*pnpm[[:space:]]+(add|install|i)[[:space:]]*//; s/[;&|].*//')
  for tok in $seg; do
    case "$tok" in -*) continue ;; esac
    name=$(printf '%s' "$tok" | sed -E 's/^(@?[^@]+)@.*/\1/')
    case " $APPROVED " in *" $name "*) ;; *) unapproved="$unapproved $name" ;; esac
  done
  if [ -n "$unapproved" ]; then
    emit ask "Not on the pre-approved dependency list:$unapproved. CLAUDE.md says to ask before adding dependencies."
  fi
fi
exit 0

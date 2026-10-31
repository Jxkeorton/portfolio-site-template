---
name: pre-commit-validation
description: Run the full validation sequence (tests, lint, format check, type check, build, git diff review) before committing a finished feature or fix in the Astro + Sanity portfolio project. Use before every commit, when the user asks to validate, check, or review changes, or when another skill reaches its validation step.
---

# Pre-commit validation

Run this before every commit. The aim is evidence: each step is actually run, its result is read, and the report says exactly what happened. Never say a step passed without having run it in this session, and never skip a step because the change "looks small".

This project is Astro-only (no UI framework islands). Commands assume pnpm; if a script is missing from `package.json`, add it rather than running the tool ad hoc, and tell the user.

## Before you start

1. Confirm you are not on `main`. If you are, stop and create a feature branch (`feat/<name>`, `fix/<name>`, `chore/<name>`) before committing anything.
2. Run `git status` so you know which files are changed, staged and untracked. Untracked files that belong to the feature must be added; anything unrelated must be left out.
3. Restate the requirement being delivered in one or two sentences. The diff review in step 6 is checked against it.

## Steps

Run in this order. Fix problems as they appear, then re-run from the failing step onward (and re-run earlier steps if the fix touched code they cover).

### 1. Tests: `pnpm test`
- All tests pass, including the new ones.
- No `.only`, `.skip` or `.todo` left behind that you did not intend: search the changed test files.
- Every behaviour in the requirement has a test, with names that read as the requirement. If a stated behaviour has no test, write it (failing first) before continuing.
- Never delete or weaken a failing test to get green. If a test is wrong, say why and fix it deliberately.

### 2. Lint: `pnpm lint` (oxlint)
- Zero errors. Fix warnings in files you changed.
- Do not add blanket disable comments to silence a rule. A targeted disable needs a one-line reason.

### 3. Format: `pnpm format:check` (oxfmt)
- If it fails, run `pnpm format`, then re-run `pnpm format:check`. Check `git diff` afterwards: formatting must not touch unrelated files.
- If oxlint or oxfmt does not cover `.astro` files properly, say so in the report and ask the user how to proceed. Do not silently drop the check.

### 4. Types: `pnpm check` (astro check)
- Zero errors and no new warnings in changed files.
- No `any`, no `as` casts to silence errors, no `// @ts-ignore`. Use `unknown` and narrow, or the generated Sanity types.

### 5. Build: `pnpm build`
- The static build succeeds.
- If the change touched client-side JS, note the size of what ships to the browser and whether it is justified. Zero JS by default is the goal.
- If the change touched images, confirm explicit width and height and lazy loading below the fold.

### 6. Review the diff against the requirement
Run `git diff` and `git diff --staged` and read all of it. Check:

- **Scope:** every change relates to the requirement. Unrelated edits, drive-by refactors and stray formatting changes are removed or split into their own commit.
- **Leftovers:** no debug code, commented-out code, `console.log`, TODOs you created, or `.only` in tests.
- **Secrets:** no tokens, API keys, project IDs that should be env vars, `.env` contents, or credentials. Sanity tokens live in environment variables only.
- **Dependencies:** any change to `package.json` or the lockfile was approved by the user. If not, stop and ask.
- **Sanity changes:** no existing schema field was renamed or removed without a migration plan, since published content depends on it. New image fields have a required `alt`. New fields have plain-English titles.
- **Accessibility:** images have alt text, interactive elements have accessible names and work from the keyboard, heading order makes sense.
- **Requirement coverage:** each stated behaviour is delivered and tested.

Also check generated files: if the diff contains large generated output (types, build output, lockfile churn), confirm it is expected.

### 7. Commit
Only when steps 1 to 6 are clean.
- Conventional Commit message: `feat(blocks): add pull quote block`, `fix(image): set missing width and height`, `test(gallery): cover empty state`, `chore: update dependencies`.
- Small, focused commits. Tests and the implementation for one behaviour can share a commit.
- Do not push, open a pull request, or merge unless the user asks.

## If a step fails

- Read the actual error. Fix the cause, not the symptom.
- Do not retry the same command hoping for a different result. If a failure looks flaky, re-run once, say that it was flaky, and say what you saw.
- If you cannot fix it within the scope of the requirement, stop. Report what failed, what you tried, and the options. Do not commit with a failing step.

## Report

End with a short, honest summary:

| Step | Result |
|---|---|
| Tests | passed or failed, counts |
| Lint | clean or what remains |
| Format | clean or what was changed |
| Types | clean or what remains |
| Build | succeeded, plus any client JS added |
| Diff review | what you checked, anything removed or flagged |

Then state:
- The commit message used, or why nothing was committed
- Anything you could not verify (for example how the block looks in Studio or on a preview deploy, since these checks cannot judge appearance)
- Any decision the user should make

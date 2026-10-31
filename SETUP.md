# Project setup

Starting point: the folder holds only `CLAUDE.md`, `.claude/` (skills) and `skills-lock.json`. There is no `package.json` and no git repo yet. Node 24 and pnpm 10 are installed.

Tick each step off as you go.

## 1. Initialise git and protect `main`

- [ ] `git init`, then make a first commit with only `CLAUDE.md`, `SETUP.md`, `.claude/` and `skills-lock.json`. Run this one yourself in the terminal: the hook in `.claude/settings.json` blocks Claude from committing on `main`, and that includes this first commit.
- [ ] Create the GitHub repo and add it as `origin`.
- [ ] Do all further work on branches (`chore/scaffold` first). Never commit directly to `main`.

## 2. Scaffold Astro (static, TypeScript strict)

- [ ] `pnpm create astro@latest .` with the minimal template, TypeScript set to strict, and no git init.
- [ ] Confirm `output: 'static'` in `astro.config.mjs`.

## 3. Add tooling and scripts

- [ ] Dev dependencies: `vitest`, `oxlint`, `oxfmt`.
- [ ] Add these scripts to `package.json`: `dev`, `test`, `test:watch`, `lint`, `format`, `format:check`, `check`, `build`.
- [ ] Configure Vitest for the Astro Container API (`getViteConfig` from `astro/config`).
- [ ] Check whether oxlint and oxfmt cover `.astro` files. If there are gaps, say so and ask rather than dropping the check.

### Hooks to add once the scaffold exists

These need the `pnpm` scripts and `oxfmt`, so they can't go in yet. Add them to `.claude/settings.json` (ask Claude to use the `update-config` skill).

- [ ] **Validate before `git commit`.** PreToolUse hook on Bash. When the command is `git commit`, run `pnpm test`, `pnpm lint`, `pnpm format:check` and `pnpm check`, and block the commit (exit 2) if any fail. Leave `pnpm build` out of the gate because it's slow. The `pre-commit-validation` skill still runs it.
- [ ] **Auto-format after edits.** PostToolUse hook on Edit and Write. Run `oxfmt` on the changed file. First check that oxfmt handles `.astro` files properly. If it doesn't, restrict the hook to the file types it does cover and tell Claude so the gap is raised, as CLAUDE.md requires.

## 4. Add the pre-approved Sanity dependencies

- [ ] Install `@sanity/astro`, `astro-portabletext`, `@sanity/image-url`, `groq`. Anything else needs approval first.
- [ ] Create a Sanity project and dataset at sanity.io (needs your login).
- [ ] Add the Studio in `sanity/`.
- [ ] Put the project ID in `.env` and add `.env` to `.gitignore`.
- [ ] Create `src/utils/sanity.ts` for the client and GROQ queries, following `astro.md` in the `sanity-best-practices` skill.

## 5. Create the empty structure

- [ ] Folders: `src/blocks/`, `src/components/`, `src/layouts/`, `src/utils/`, `src/styles/`, `tests/e2e/`.
- [ ] `src/blocks/BlockRenderer.astro`.
- [ ] A base layout that imports `global.css` once.

## 6. Make design decisions before any visual work

- [ ] Run the `frontend-design` skill and agree a direction: the subject, the audience, and one aesthetic risk.
- [ ] Gather the client's work, brand and references first.
- [ ] Write `src/styles/tokens.css` (colour, type, space, layout, motion).
- [ ] Write `src/styles/global.css` (reset, base styles, font-face, imports tokens).

## 7. Build the first block

- [ ] Use the `add-sanity-block` skill: fixture, failing test, schema, component, renderer line. A simple text or image block is a good first one.
- [ ] Run the `pre-commit-validation` skill before every commit (test, lint, format:check, check, build, review the diff).

## 8. Deploy preview

- [ ] Connect the repo to Vercel so each PR gets a preview deploy.

## Hooks already in place

Configured in `.claude/settings.json`, scripts in `.claude/hooks/`. They apply to Claude only, not to commands you run yourself.

- Blocks `git commit` while on `main` or `master`.
- Blocks `npm` and `yarn`. Asks before `pnpm add` of anything not on the approved list. To approve a package for good, add it to `APPROVED` in `.claude/hooks/check-dependencies.sh`.
- Blocks edits to `.env` and `.env.*` (except `.env.example`) and to `dist/`.
- Denies `sanity dataset delete`, `sanity dataset import`, `sanity documents`, `sanity deploy`, `vercel deploy` and `vercel --prod`.

## Needed from you

- Whether the GitHub repo exists yet.
- Whether you already have a Sanity project ID.
- The client's work, brand and references for the design step.

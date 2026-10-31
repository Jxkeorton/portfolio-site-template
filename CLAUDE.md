# CLAUDE.md

Portfolio site built with Astro (static output). Content is managed in Sanity as an array of blocks per project; each block type has its own component. The goal is a lean, fast, accessible site that a non-technical client can edit through the CMS.

## Stack

- Astro (static output, `output: 'static'`), TypeScript strict
- Sanity for content (Studio + GROQ queries at build time)
- Vitest for tests
- oxlint (lint) and oxfmt (format)
- Package manager: pnpm (swap commands below if different)

## Principles

1. **Zero JS by default.** Use `.astro` components unless the block genuinely needs client-side behaviour (carousel, lightbox). Only then use a small `<script>` in the component, preferring native HTML and CSS (for example `<dialog>`, scroll-snap) first.
2. **Tests describe requirements.** Behaviour first, implementation second (see BDD below).
3. **One block, one folder.** Everything for a Sanity block lives together.
4. **Small, reviewable changes.** One feature per branch, small commits.
5. **Don't add dependencies casually.** Each one costs bundle size and maintenance. Dependencies recommended by an installed skill (for example `@sanity/astro`, `astro-portabletext`, `@sanity/image-url`, `groq`) are pre-approved; ask first for anything else.

## Project structure

```
src/
  blocks/
    <BlockName>/
      <BlockName>.astro                        # the component
      <blockName>.schema.ts                    # Sanity schema for this block
      <BlockName>.test.ts                      # behaviour tests
      <blockName>.fixture.ts                   # sample Sanity data used by tests
  components/        # shared UI that is not a Sanity block (Header, Footer, Image)
  layouts/
  pages/
  utils/
    sanity.ts        # Sanity client usage, GROQ queries and fetch helpers
  styles/
    tokens.css       # design tokens (custom properties): the single source of visual decisions
    global.css       # reset, base element styles, font-face, imports tokens.css
sanity/              # Studio config; imports each block's schema from src/blocks
tests/
  e2e/               # few, high-value page-level checks only
```

- `src/blocks/BlockRenderer.astro` is the single place that maps a Sanity `_type` to its component. Adding a block means: new folder, schema, tests, then one line in the renderer and the schema list.
- Block components receive Sanity data as typed props and contain no data fetching. Fetching lives in `src/utils/sanity.ts`, following the Sanity `astro.md` reference in the `sanity-best-practices` skill.
- Images go through Astro's image pipeline or Sanity's image URL builder with explicit width and height. Alt text is required in every image schema.

## Behaviour-driven workflow

Tests are written from the requirement, before the implementation.

1. State the requirement in plain language (from the user's request).
2. Write the test first, named as behaviour:

```ts
describe('Quote block', () => {
  describe('given a quote with an attribution', () => {
    it('shows the quote text and the attribution', () => { /* ... */ })
  })
  describe('given a quote without an attribution', () => {
    it('shows only the quote text', () => { /* ... */ })
  })
})
```

3. Run it and confirm it fails for the right reason.
4. Implement the minimum to pass, then refactor with tests green.

Rules:
- Use `describe('given ...')` and `it('shows/does/allows ...')` naming. Test names read as the requirement.
- Test what the visitor sees (roles, text, labels), not internal state or class names. Prefer queries by role, text and label.
- Use the block's `.fixture.ts` for data. Cover the empty, minimal and full cases.
- Every block has tests for: renders with full data, handles missing optional fields, and required accessibility attributes (alt text, labels).
- Astro components: test via the Astro Container API or by testing the built output.
- Keep end-to-end tests few. Use them for page-level flows such as a project page rendering its blocks in order.

## Commands

```
pnpm dev            # local dev server
pnpm test           # vitest run
pnpm test:watch     # vitest watch
pnpm lint           # oxlint
pnpm format         # oxfmt
pnpm format:check   # oxfmt in check mode
pnpm check          # astro check (types for .astro files)
pnpm build          # static build
```

If a script is missing from `package.json`, add it rather than running the tool ad hoc.

## Validation before every commit

After each completed feature, run these in order and fix problems before committing. Do not skip a step, and do not claim a step passed without running it.

1. `pnpm test` — all tests pass, including the new ones.
2. `pnpm lint` and `pnpm format:check` — no errors.
3. `pnpm check` — no type errors.
4. `pnpm build` — static build succeeds.
5. **Review `git diff` (and `git diff --staged`)** against the requirement:
   - Every change relates to the feature; nothing unrelated slipped in.
   - No debug code, commented-out code, stray `console.log`, or leftover `.only` in tests.
   - No secrets, tokens or `.env` contents.
   - New dependencies, if any, were approved (skill-recommended ones are pre-approved).
   - Tests cover each stated requirement.
6. Commit only when all of the above are clean.

If lint or format coverage for `.astro` files has gaps, say so and ask, rather than silently dropping the check.

## Git workflow

- Never commit directly to `main`. Create a branch per feature: `feat/<short-name>`, `fix/<short-name>`, `chore/<short-name>`.
- Use Conventional Commits: `feat(blocks): add Quote block`, `fix(image): set missing width and height`, `test(gallery): cover empty state`, `chore: update dependencies`.
- Keep commits small and focused; tests and implementation for one behaviour can share a commit.
- Open a pull request for each branch so a preview deploy can be checked before merging.
- Do not push, force-push or merge unless asked.

## Code style

- TypeScript strict. No `any`; use `unknown` and narrow, or generated Sanity types.
- Prefer semantic HTML and CSS over JS for layout and behaviour.
- Scoped component CSS, using shared design tokens from `src/styles`.
- Name block components in PascalCase matching the Sanity `_type` (for example `quote` maps to `Quote`).
- Keep components small. If a block needs more than one file of logic, extract helpers into the block's folder.

## Design

This is a portfolio. It must not look like a template. For any visual work (new block, page layout, restyle, colour or type change), invoke the `frontend-design` skill **before** writing markup or CSS.

Process:
1. Before building, state the design direction in a few lines: the subject, the audience, the one aesthetic risk being taken and why it suits this client's work. Get agreement if the direction is new.
2. Express every decision as a token first (see below), then use the token in components.
3. Avoid the defaults the skill warns against: system or Inter-by-default type, purple/blue gradients, centred hero plus three-card grid, uniform rounded cards with soft shadows, stock spacing. If a block looks like it could belong to any other site, rework it.
4. Design for the content, not around it. The portfolio's work (images, project titles, text) is the hero; the chrome supports it.

### Design tokens (`src/styles/tokens.css`)

All colour, type, spacing, radius, motion and layout values are CSS custom properties declared once in `tokens.css` on `:root`. Components never hard-code a colour, font, or spacing value.

Suggested structure:
- **Colour:** semantic names, not hues (`--color-bg`, `--color-surface`, `--color-text`, `--color-text-muted`, `--color-accent`, `--color-border`). Raw palette values live in a short primitive layer the semantic tokens point to. Dark mode, if wanted, redefines the semantic layer only (`light-dark()` or `prefers-color-scheme`). Every text/background pairing meets WCAG AA.
- **Type:** `--font-display`, `--font-body`, optionally `--font-mono`; a fluid scale built with `clamp()` (`--step--1` to `--step-5`); line-height, letter-spacing and weight tokens per role. Pick the faces for this client's work, not stack defaults.
- **Space:** one scale (`--space-3xs` to `--space-3xl`), fluid where it helps. Section rhythm comes from the scale, not ad hoc margins.
- **Layout:** `--content-width`, `--wide-width`, `--gutter`, plus named breakpoints documented as comments (custom properties cannot be used in media queries).
- **Shape and depth:** `--radius-*`, `--border-*`, and shadows only if the direction calls for them.
- **Motion:** `--ease-*`, `--duration-*`. Motion is opt-in and wrapped in `prefers-reduced-motion: no-preference`.

### Design practices for this stack

**Astro**
- Component CSS is scoped in the component's `<style>`. Use `:global()` sparingly and only in `global.css`. Import `global.css` once, in the base layout.
- Reach for CSS before JS: `scroll-snap`, `<dialog>`, `:has()`, `@container`, `animation-timeline`, the View Transition API. Do not add the Astro client router (`ClientRouter`) or an animation library without asking; they ship JS.
- Fonts: self-host (Astro's fonts API or `@fontsource`), subset to what is used, `font-display: swap` with a fallback tuned via `size-adjust` to limit layout shift, preload only the one or two critical files.
- No CSS framework or UI kit (Tailwind, component libraries). Tokens plus scoped CSS are the system.

**Sanity blocks**
- Editors choose content and a small set of **named options**, never raw values. Offer `layout: 'full' | 'wide' | 'inset'`, `spacing: 'tight' | 'normal' | 'loose'`, `tone: 'default' | 'inverse'`, each mapped to tokens in the component. No colour pickers, pixel values or free-form font choices.
- Blocks must hold up under any editor input: very long and very short titles, missing optional fields, one image or twenty, portrait and landscape. Design and test the extremes using the fixture's empty, minimal and full cases.
- Blocks sit in different widths, so lay them out with container queries (`container-type: inline-size`) rather than viewport media queries where practical. Vertical rhythm between blocks is owned by `BlockRenderer.astro` (one rule), not by each block's outer margin.
- Images: reserve space with `aspect-ratio` from the asset's `width`/`height`, honour the Sanity hotspot with `object-position`, and use the asset's LQIP/dominant colour as a placeholder background. Request sizes that match the rendered size via `srcset`/`sizes`.
- Portable Text: style it once through a shared `prose` wrapper (measure of roughly 60 to 70 characters, token-based type scale, link and list styling), not per block.

**Accessibility as part of the design**
- Visible `:focus-visible` styles that suit the design, not the browser default left unconsidered. Tap targets at least 44px.
- Do not rely on colour alone; keep contrast at AA for text and UI.
- Respect `prefers-reduced-motion` and `prefers-color-scheme`.
- Heading levels follow document structure, not size; style headings through tokens/classes, not by picking a different tag.

## Sanity conventions

- One schema file per block, exported from the block folder and registered in the Studio config.
- Keep the editor simple: aim for no more than 6–8 block types, with clear titles, descriptions and previews so editors can tell them apart.
- Validation in the schema: required alt text on images, sensible length limits on titles.
- Never change an existing field name without a migration plan; published content depends on it.
- Queries are GROQ, kept in `src/utils/sanity.ts` (the `sanity-best-practices` skill's `astro.md` is the source of truth for Sanity and Astro integration), and fetch only the fields the page uses.

## Performance and accessibility budgets

- Images are lazy-loaded below the fold, served as WebP or AVIF, with explicit dimensions to avoid layout shift.
- Check the JS shipped after `pnpm build`. If a page gains client-side JS, state why in the PR.
- All interactive elements are keyboard-operable and have accessible names. Colour contrast meets WCAG AA.

## Working with Claude

- Before building, restate the requirement and list the behaviours you will test. Ask if anything is ambiguous.
- For a new block, follow the order: fixture, failing test, schema, component, renderer registration, validation steps.
- Report results honestly: what you ran, what passed, and anything you could not verify.
- Do not edit `main`, the Sanity dataset, or deployment settings without being asked.

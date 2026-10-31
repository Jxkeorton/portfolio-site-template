---
name: add-sanity-block
description: Add a new Sanity content block to the Astro portfolio site using the BDD workflow (fixture, failing test, schema, Astro component, renderer registration, validation, commit). Use when the user asks for a new block type, section, or content layout that editors can add to a project page.
---

# Add a Sanity block

Follow this order every time. The block is complete only when behaviour tests pass and the validation steps are clean. This project uses Astro only: no UI framework islands. Components are `.astro` files, and any client-side behaviour is a small vanilla TypeScript module.

## Conventions

- Sanity `_type`: camelCase (`pullQuote`)
- Folder and component: PascalCase (`src/blocks/PullQuote/PullQuote.astro`)
- Files in the folder:
  - `PullQuote.astro` (component)
  - `pullQuote.schema.ts` (Sanity schema)
  - `PullQuote.test.ts` (behaviour tests)
  - `pullQuote.fixture.ts` (sample Sanity data)
  - `pullQuote.client.ts` (only if the block needs client-side JS)
- The only shared files touched: `src/blocks/BlockRenderer.astro`, the Studio schema list, and the GROQ projection in `src/lib/sanity`.

## Steps

### 1. Pin down the requirement
Restate what the block is for in one or two sentences. Confirm, asking the user only about what is unclear:
- What editors enter (fields, which are required, which are optional)
- What visitors see, including empty and minimal states
- Whether it needs interactivity (carousel, lightbox, toggle). Default to none: prefer semantic HTML and CSS. Use a small `.client.ts` script only if CSS cannot do it.
- Whether it duplicates an existing block. Keep the editor to roughly 6 to 8 block types, so prefer extending a block with an option over adding a near-duplicate.

List the behaviours as given/when/then lines and show them to the user before writing code if anything was ambiguous.

### 2. Branch
Create `feat/block-<name>` from an up-to-date `main`. Never work on `main`.

### 3. Fixture
Create `<blockName>.fixture.ts` exporting at least: `full` (every field), `minimal` (required fields only), and any special case (for example no attribution, no image). Fixtures are typed with the generated Sanity types where available, never `any`.

### 4. Failing tests first
Write `<BlockName>.test.ts` with behaviour-style names:

```ts
describe('PullQuote block', () => {
  describe('given a quote with an attribution', () => {
    it('shows the quote text and the attribution', async () => { /* ... */ })
  })
  describe('given a quote without an attribution', () => {
    it('shows only the quote text', async () => { /* ... */ })
  })
})
```

How to test an Astro component: render it with Astro's Container API (`astro/container`; the export may be `experimental_AstroContainer` in older Astro versions), put the HTML string into the test DOM (happy-dom or jsdom), and query with Testing Library (`getByRole`, `getByText`). Vitest needs `getViteConfig` from `astro/config` so `.astro` files compile.

Always cover:
- Full data renders correctly
- Optional fields missing: nothing broken, no empty wrappers or labels
- Accessibility: images have alt text, interactive controls have accessible names, headings are in a sensible order
- Interactive behaviour, if any, tested against the `.client.ts` module with user-event (keyboard as well as mouse)

Run the new tests and confirm they fail for the right reason (missing component, not a typo). Do not proceed on a test that passes before the implementation exists.

### 5. Schema
Create `<blockName>.schema.ts` using `defineType` and `defineField` from `sanity`:

```ts
import { defineType, defineField } from 'sanity'

export const pullQuote = defineType({
  name: 'pullQuote',
  title: 'Pull quote',
  type: 'object',
  fields: [
    defineField({
      name: 'text',
      title: 'Quote',
      type: 'text',
      rows: 3,
      validation: (rule) => rule.required().max(280),
    }),
    defineField({ name: 'attribution', title: 'Attribution', type: 'string' }),
  ],
  preview: {
    select: { title: 'text', subtitle: 'attribution' },
  },
})
```

Rules:
- Every image field has a required `alt` field.
- Every field has a plain-English `title`, and a `description` when it is not obvious to a non-technical editor.
- Add a `preview` so editors can tell blocks apart in the list.
- Set sensible length limits and required validation.
- Never rename an existing field without a migration plan. This only applies when changing an existing block.
- Register the schema in the Studio schema list and add it to the project's `content` array `of: [...]`.

### 6. Component
Create `<BlockName>.astro`:
- Typed `Props` interface from the generated Sanity types
- No data fetching inside the block; it only renders its props
- Semantic HTML, scoped CSS, design tokens from `src/styles`
- Images through the project's image helper with explicit width and height and lazy loading below the fold
- Render nothing for absent optional fields rather than empty elements
- If client JS is truly needed: put logic in `<blockName>.client.ts`, import it with a `<script>` in the component, keep it dependency-free, and progressively enhance so the content works without JS

If a new dependency seems necessary (for example a Portable Text renderer), stop and ask the user first.

### 7. Wire it up
- Add one case to `src/blocks/BlockRenderer.astro` mapping the `_type` to the component.
- Add the block's fields to the GROQ projection in `src/lib/sanity`, selecting only what the block uses.
- Regenerate Sanity types if the project uses TypeGen, and fix any type errors.

### 8. Make tests pass, then refactor
Implement the minimum to turn the tests green, then tidy with tests still green. Add a test for any behaviour discovered along the way.

### 9. Validate (do not skip steps, do not claim a step passed without running it)
1. `pnpm test`
2. `pnpm lint` and `pnpm format:check`
3. `pnpm check` (astro check)
4. `pnpm build`
5. Review `git diff` and `git diff --staged` against the requirement: only block-related changes, no debug code, no `.only` in tests, no secrets, no unapproved dependencies, every stated behaviour has a test.

Also check the built page: if this block added client-side JS, note how many KB, and justify it.

### 10. Commit
Use a Conventional Commit, for example `feat(blocks): add pull quote block`. Small follow-up commits are fine (`test(pullQuote): cover missing attribution`). Do not push, open a PR or merge unless asked.

### 11. Report
Finish with a short summary:
- The block's `_type`, fields, and what visitors see
- Which behaviours are tested
- Which validation steps ran and their results, including anything not verified
- Any decision the user should review (new dependency, schema trade-off, client JS)
- A reminder to check the block in Studio and on a preview deploy before merging, since the tests cannot judge how it looks to an editor

---
name: site-audit
description: Audit the built Astro portfolio site against its performance, image, SEO and accessibility budgets and produce a prioritised report. Checks JavaScript shipped per page, image sizes and dimensions, alt text, heading order, metadata and internal links from the static build, with optional Lighthouse and axe runs. Use when the user asks to audit, check performance, check accessibility, or prepare a site health report, and after adding blocks that ship client-side JS or many images.
---

# Site audit

Builds the site and checks the output against the project's budgets. The audit is **read-only**: it reports problems and suggests fixes, but does not change code, content or settings unless the user asks. It never commits, pushes or deploys.

The project is Astro-only with static output. Most of the audit is static analysis of the built HTML, which needs no new dependencies. Lighthouse and axe are optional extras that need the user's approval because they add tooling.

## Rules that always apply

- **Run things, don't assume.** Every number in the report comes from a command run in this session. If something could not be measured, say so.
- **Don't add dependencies without asking.** Prefer `npx` one-off runs for optional tools and say what is being fetched. Never add anything to `package.json` for an audit without approval.
- **Leave the project clean.** Write reports and scratch files to a temporary folder outside the repo. Copy a report into the project only if the user asks. Check `git status` at the end: the audit should leave no changes.
- **Don't audit sites you weren't pointed at.** Only the local build, or a live URL the user gave you.
- **No secrets in reports.** Don't print environment variables, tokens or project IDs beyond what the user already knows.

## Budgets

Read the budgets in `CLAUDE.md` first; they take priority. If none are set, use these defaults and say that you did:

| Area | Default budget |
|---|---|
| JavaScript on a content page | 0 KB. Pages with an interactive block may ship up to about 30 KB gzipped, with a stated reason |
| Single image file | 250 KB or less (slides with small text may justify more; flag, don't fail) |
| Total weight of a page's first view | 1.5 MB or less, excluding lazy-loaded images below the fold |
| Images | explicit width and height, lazy-loaded below the fold, WebP or AVIF |
| Accessibility | every image has alt text, valid heading order, keyboard-operable controls, WCAG AA contrast |
| Lighthouse (if run, mobile) | Performance 90 or more, Accessibility 100, SEO 95 or more; LCP 2.5 s or less, CLS 0.1 or less, TBT 200 ms or less |

## Steps

### 1. Prepare
- Confirm the working tree state with `git status` (note any uncommitted changes; the audit reflects the working tree).
- Install dependencies only if `node_modules` is missing (`pnpm install --frozen-lockfile`).
- Run `pnpm build`. If the build fails, stop: report the error. Don't audit stale output.
- Locate the output folder (normally `dist/`) and list the pages built.

### 2. JavaScript shipped
For every built HTML page:
- List `<script>` tags, inline and external, and modulepreloads.
- Measure the size of each referenced JS file, raw and gzipped (`gzip -c file | wc -c`).
- Report per-page total JS. Flag any content page with JS, and any page over 30 KB gzipped.
- For flagged pages, identify which block or component adds the JS (look at the script file contents or the component source) and say whether CSS or plain HTML could do the same job.

### 3. Images
- List every `<img>` and `<picture>` source per page, with file size where the file is local or the URL is reachable.
- Check each image for: `alt` present (empty `alt=""` is fine only for purely decorative images, so flag them for review), explicit `width` and `height`, `loading="lazy"` for images below the fold (the first image or cover image should **not** be lazy and ideally has `fetchpriority="high"`), modern format.
- Flag images above the size budget and show the biggest ten across the site.
- Flag images where the delivered dimensions are much larger than the display size, if you can tell.

### 4. HTML quality and accessibility (static)
Per page, check:
- `<html lang>`, a unique `<title>`, a meta description, a canonical URL, Open Graph title and image
- Exactly one `<h1>`, and heading levels that don't skip
- Landmarks (`header`, `nav`, `main`, `footer`), a skip link
- Links and buttons with accessible names; no links that just say "click here"
- Form fields with labels, if any forms exist
- Duplicate IDs
- Internal links: every internal `href` resolves to a built page or file. List broken links and missing anchors
- `robots.txt` and a sitemap exist, if the project is meant to be indexed

Static checks can't judge colour contrast, focus order or screen-reader behaviour. Say so in the report.

### 5. Optional deeper runs (ask first)
Offer these in one short question and run only what the user approves. Mention that each downloads tooling with `npx`:
- **Lighthouse:** serve the built site locally with `pnpm preview` and run Lighthouse for a representative sample of pages (home, a project page with many slides, a text-heavy page) on a mobile profile. Report scores and the metrics against the budget table. Treat single runs as indicative: run each page at least three times and report the median, since results vary.
- **axe-core:** run against the same pages for automated accessibility issues including colour contrast. Report violations by impact, with the selector and the rule.
- **Live URL:** only if the user provides one, and only if it is reachable from here. Compare with the local build and mention differences (CDN, headers, caching).

Stop any preview server you started when finished.

### 6. Compile the report
Write the report as a Markdown file in the temporary folder. Structure:

1. **Summary:** pass, needs attention, or failing, with the three most important findings.
2. **Scorecard:** a table of each budget area with measured value, budget and result.
3. **Findings, prioritised:** each with severity (high, medium, low), where it is (page and element or file), the evidence (the measured value), and a concrete suggested fix. Group repeated problems (for example the same missing alt text across a block) into one finding.
4. **What was not checked:** manual accessibility testing, real-device performance, anything that needed approval and was declined.
5. **Method:** the commands run, the date, the commit hash, and whether the working tree had uncommitted changes.

Severity guide: high = users or search engines are materially affected (missing alt text on content images, a content page shipping unnecessary JS, broken internal links, layout shift from images without dimensions); medium = budgets exceeded by a modest margin; low = polish.

### 7. Finish
- Run `git status` and confirm the audit changed nothing in the repo.
- Report back briefly: overall result, top findings, where the full report is, and the suggested next step. Offer to fix the findings as a separate task on a feature branch, using `pre-commit-validation` before committing.

## Client-facing version
If the user asks for something to send to the client, produce a second, shorter summary in plain English: an overall health rating, three or four sentences on what is good, a short prioritised list of recommended improvements, and no technical jargon or raw file paths. Only include findings that were measured.

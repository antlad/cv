# Posts Section Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a production-ready, paginated `/posts/` section with a realistic draft article that can be inspected locally without publishing it.

**Architecture:** Model posts as an isolated Hugo section containing leaf page bundles. Section-specific list and single templates reuse the existing base layout, while small partials own article metadata and paginator markup; the shared head and header become page-aware without changing the homepage's content flow.

**Tech Stack:** Hugo 0.139.0+ templates and content bundles, Markdown, HTML, CSS, SVG, Bash verification, GitHub Pages

**Spec:** `docs/superpowers/specs/2026-09-26-posts-section-design.md`

## Global Constraints

- Preserve the existing CV homepage and generated CV output.
- Set Hugo pagination to exactly ten articles per page.
- Keep `disableKinds = ["taxonomy", "term"]`; do not add search, tags, categories, comments, or client-side pagination.
- Keep the example article at `draft: true`; `hugo server -D` shows it and a production build excludes it.
- Support both CI Hugo 0.139.0 and local Hugo 0.155.0 without adding dependencies or changing `.github/workflows/deploy.yml`.
- Keep permanent article URLs date-free at `/posts/<slug>/`.
- Reuse the current paper, ink, teal, sans-serif, and monospaced design tokens.

## Review Focus

- An archive with no published articles renders a useful empty state instead of blank markup; Task 1 verifies the production archive copy.
- Eleven or more articles produce `/posts/page/2/index.html`, and that page links back to page one; Task 1 generates temporary fixtures and verifies both outputs.
- An article without `description` receives a usable archive summary from its Markdown; Task 1 includes a temporary fixture without that field.
- Draft visibility differs correctly between preview and production builds; Tasks 1 and 2 verify archive and article output in both modes.
- Long code and narrow viewports do not widen or break the page; Task 3 verifies the overflow rule and inspects desktop and mobile renders.

---

### Task 1: Posts content model and paginated archive

**Files:**
- Modify: `hugo.toml:1-8`
- Create: `content/posts/_index.md`
- Create: `content/posts/self-hosted-llm-nats-rust/index.md`
- Create: `content/posts/self-hosted-llm-nats-rust/optimisation_2.png`
- Create: `layouts/posts/list.html`
- Create: `layouts/partials/article-meta.html`
- Create: `layouts/partials/pagination.html`
- Modify: `scripts/verify-site.sh:1-125`

**Interfaces:**
- Consumes: Existing `layouts/_default/baseof.html` block named `main`, site parameters from `hugo.toml`, and the existing CSS class vocabulary.
- Produces: `.Paginate (.RegularPages.ByDate.Reverse)` with ten items per pager; partial `article-meta.html` accepting a Hugo Page context; partial `pagination.html` accepting a Hugo Pager context; draft article bundle at `/posts/self-hosted-llm-nats-rust/`.

- [ ] **Step 1: Add failing archive and pagination verification**

Extend `scripts/verify-site.sh` with separate draft-preview and production temporary destinations. Assert that the draft build contains `/posts/index.html`, links to `/posts/self-hosted-llm-nats-rust/`, and shows the article title, while the production archive contains `Posts are on the way` and no link to the draft article. Add a temporary copied content tree with enough generated draft fixtures to total at least eleven articles; one fixture omits `description` and begins with `Fallback summary from article body.` Assert `/posts/page/2/index.html` exists, links back to `/posts/`, and the fallback summary appears in an archive page. Assert `hugo config` reports `pagersize = 10`.

- [ ] **Step 2: Run the verifier to confirm the archive checks fail**

Run: `./scripts/verify-site.sh`

Expected: FAIL because `/posts/index.html` does not exist.

- [ ] **Step 3: Add the posts section content model**

Add `[pagination] pagerSize = 10` to `hugo.toml`. Create `content/posts/_index.md` with title `Posts` and a concise introduction. Add the draft `self-hosted-llm-nats-rust` leaf bundle with front matter fields `title`, `date`, `description`, and `draft: true`; retain its technical prose, fenced code blocks, and bundled `optimisation_2.png` image.

- [ ] **Step 4: Implement the paginated archive and shared partials**

Create `layouts/posts/list.html` with `{{ define "main" }}`, paginate `.RegularPages.ByDate.Reverse`, render archive rows using the article-meta partial, prefer `.Description` and fall back to `.Summary`, show the specified empty-state copy when the pager is empty, and call the pagination partial. `article-meta.html` renders `January 2, 2006` plus `· N min read`; `pagination.html` renders previous, numbered, current (`aria-current="page"`), and next links only when more than one pager exists.

- [ ] **Step 5: Run the verifier and inspect generated route files**

Run: `./scripts/verify-site.sh`

Expected: PASS for all existing portal/CV checks plus archive, empty-state, summary-fallback, draft-visibility, and page-two checks.

Run: `hugo --buildDrafts --destination "$(mktemp -d /tmp/cv-posts-task1.XXXXXX)"`

Expected: Exit 0 and Hugo reports one posts page plus the section outputs.

- [ ] **Step 6: Commit the content and archive slice**

```bash
git add hugo.toml content/posts layouts/posts/list.html layouts/partials/article-meta.html layouts/partials/pagination.html scripts/verify-site.sh
git commit -m "Add paginated posts archive"
```

### Task 2: Article page, navigation, metadata, and RSS

**Files:**
- Create: `layouts/posts/single.html`
- Modify: `layouts/partials/header.html:1-15`
- Modify: `layouts/partials/head.html:1-53`
- Modify: `scripts/verify-site.sh`

**Interfaces:**
- Consumes: Draft bundle and `article-meta.html` from Task 1; existing site params and `baseof.html` main block.
- Produces: Article markup rooted at `.article-page`; root-safe header links; per-page title/description/Open Graph/canonical metadata; `Article` JSON-LD for posts pages while preserving homepage `Person` JSON-LD; discoverable section RSS.

- [ ] **Step 1: Add failing article, navigation, metadata, and feed checks**

Extend `scripts/verify-site.sh` to assert that the draft article output exists and contains the title, description, a second-level heading, highlighted Go code, `optimisation_2.png`, a link to `/posts/`, and a homepage link. Assert its `<title>` combines article and site names, `og:type` is `article`, the canonical URL is the permanent article URL, `datePublished` is present, and JSON-LD declares `Article`. Assert the homepage still declares `Person`, retains its existing title/description, and links to `/posts/`. Assert `/posts/index.xml` exists and contains the draft article only in the draft build. Assert the production destination has neither the draft article directory nor a draft item in the section feed.

- [ ] **Step 2: Run the verifier to confirm article checks fail**

Run: `./scripts/verify-site.sh`

Expected: FAIL because the draft article has no single-page template and the shared header has no posts link.

- [ ] **Step 3: Implement the article page**

Create `layouts/posts/single.html` with `{{ define "main" }}`. Render a back link to `/posts/`, article title, front-matter description, the Task 1 metadata partial, and `.Content` inside `.article-body`.

- [ ] **Step 4: Make shared navigation root-safe**

Update `layouts/partials/header.html`: brand links to `/`, Experience to `/#experience`, add Posts at `/posts/`, retain Contact, and set `aria-current="page"` on Posts for the posts section. Do not alter the homepage section layout or contact behavior.

- [ ] **Step 5: Make head metadata page-aware**

Update `layouts/partials/head.html` so non-home pages use `<page title> — <site name>` and page description with summary/site fallbacks. Posts regular pages emit `og:type=article`, published time, and `Article` JSON-LD with headline, description, publication date, canonical URL, and author; the homepage continues to emit its current `Person` JSON-LD. Use the page's `image` resource/parameter when present and otherwise use the existing site social image. Add an alternate link for the current page's RSS output when available, and preload the avatar only on the homepage.

- [ ] **Step 6: Run all rendering checks**

Run: `./scripts/verify-site.sh`

Expected: PASS, including all pre-existing homepage and CV assertions.

Run: `hugo --gc --minify --destination "$(mktemp -d /tmp/cv-posts-prod.XXXXXX)"`

Expected: Exit 0; the build includes the empty posts archive and excludes the draft article.

- [ ] **Step 7: Commit the article and metadata slice**

```bash
git add layouts/posts/single.html layouts/partials/header.html layouts/partials/head.html scripts/verify-site.sh
git commit -m "Add posts article pages and metadata"
```

### Task 3: Editorial styling and responsive validation

**Files:**
- Modify: `assets/css/main.css:1-1076`
- Modify: `scripts/verify-site.sh`

**Interfaces:**
- Consumes: `.posts-archive`, `.posts-list`, `.post-entry`, `.article-page`, `.article-header`, `.article-body`, `.article-meta`, and `.pagination` markup from Tasks 1 and 2.
- Produces: Responsive editorial archive and article presentation using existing CSS custom properties; horizontally scrollable preformatted blocks; mobile-safe header and pagination.

- [ ] **Step 1: Add failing structural style checks**

Extend `scripts/verify-site.sh` to locate the generated fingerprinted main stylesheet and assert it includes rules for `.posts-archive`, `.article-body`, `.pagination`, `max-width` on the reading column, and `overflow-x:auto` for article preformatted code.

- [ ] **Step 2: Run the verifier to confirm style checks fail**

Run: `./scripts/verify-site.sh`

Expected: FAIL because posts-specific selectors are absent from the compiled stylesheet.

- [ ] **Step 3: Add archive, article, and pagination styles**

Extend `assets/css/main.css` with an editorial archive header and ruled list, approximately `70ch` article measure, readable heading/list/blockquote/code/table/image treatments, muted article metadata, accessible pagination controls and current-page state, and breakpoints that keep the expanded nav, article media, code blocks, and paginator inside a 320px viewport. Reuse existing variables; add no fonts, scripts, or dependencies.

- [ ] **Step 4: Run automated verification**

Run: `./scripts/verify-site.sh`

Expected: `Portal, CV, and posts verification passed` with exit 0.

Run: `hugo --gc --minify --destination "$(mktemp -d /tmp/cv-posts-final.XXXXXX)"`

Expected: Exit 0 with no template warnings or errors.

- [ ] **Step 5: Inspect local desktop and mobile renders**

Run: `hugo server -D --bind 127.0.0.1`

Inspect `/`, `/posts/`, and `/posts/self-hosted-llm-nats-rust/` at approximately 1440px and 320px widths. Confirm the homepage is visually unchanged apart from the Posts link, archive hierarchy is clear, prose is comfortable to read, the bundled image scales down, long code scrolls without widening the page, header items fit, focus states remain visible, and there is no horizontal page overflow.

- [ ] **Step 6: Review the full diff and commit the styling slice**

Run: `git diff --check && git status --short && git diff --stat HEAD~2`

Expected: No whitespace errors; only the planned posts files, shared partials, configuration, stylesheet, verifier, spec, and plan are changed.

```bash
git add assets/css/main.css scripts/verify-site.sh docs/superpowers/plans/2026-09-26-posts-section.md
git commit -m "Style and verify posts section"
```

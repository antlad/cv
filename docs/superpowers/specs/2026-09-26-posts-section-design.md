# Posts Section — Design

Date: 2026-09-26

## Purpose

Add a separate long-form posts area to the existing personal portal. It must
support posts of roughly 10,000 characters plus a small number of images, remain
comfortable to read, and continue to work as the collection grows. Hugo owns
all routing and pagination; GitHub Pages only serves the generated static files.

## Goals

- A posts archive at `/posts/`, ordered newest first.
- Permanent article URLs at `/posts/<slug>/`.
- Hugo-generated archive pagination with ten articles per page.
- Markdown articles with headings, lists, quotes, code blocks, links, and
  page-relative images.
- Visual continuity with the existing portal, with a narrower measure for
  long-form reading.
- Article-specific browser, search, and social metadata.
- A posts-section RSS feed.
- A realistic draft article for local visual review with `hugo server -D`.
- Automated checks for the archive, article, navigation, metadata, and
  pagination configuration.

## Non-goals

- Search.
- Tags, categories, topic indexes, or other taxonomies.
- Comments, reactions, accounts, or a content-management UI.
- Client-side routing or JavaScript pagination.
- A recent-posts block on the CV homepage.
- Publishing the example article to production.

## Content model and routes

The posts area is a Hugo section. Each article is a leaf page bundle so its
images and other resources live beside the Markdown source:

```text
content/posts/
├── _index.md
└── self-hosted-llm-nats-rust/
    ├── index.md
    └── optimisation_2.png
```

`content/posts/_index.md` supplies the archive title and introduction.
Article front matter contains only the fields needed by the templates:

```yaml
title: "What can an offline LLM running on a single DGX Spark actually do?"
date: 2026-09-25
description: "A short archive and social-card summary."
draft: true
```

The bundle above renders at `/posts/self-hosted-llm-nats-rust/` during a
draft-enabled local preview. Relative Markdown references such as
`![optimise session](optimisation_2.png)` resolve within the bundle.

Article URLs do not include dates. Dates may change during editing, while a
slug should remain a stable external link.

## Archive and pagination

The archive template paginates the posts section's regular pages with Hugo's
`.Paginate` method. Configuration explicitly sets `pagerSize = 10` rather than
depending on Hugo's default.

For 27 published articles Hugo generates:

```text
/posts/
/posts/page/2/
/posts/page/3/
```

Each archive item shows publication date, title, description, and a link to the
full article. Pagination controls provide previous/next navigation and numbered
pages. Draft articles are included only when Hugo is invoked with `-D`.

The archive must handle an empty production collection gracefully. While the
example article remains a draft, `/posts/` displays a short "Posts are on
the way" message instead of an empty list.

## Templates and components

Section-specific templates isolate the feature from the CV homepage:

- `layouts/posts/list.html` renders the archive and pagination.
- `layouts/posts/single.html` renders one article.
- `layouts/partials/article-meta.html` renders the shared publication date and
  estimated reading time used on archive and article pages.

Both page templates use the existing `layouts/_default/baseof.html`, header,
footer, and stylesheet. The homepage keeps its dedicated `layouts/index.html`
and existing content flow.

The article page contains a link back to the posts archive, title,
description, publication metadata, and rendered Markdown. The content column is
limited to approximately 70 characters for readable long-form text. Wide code
blocks scroll horizontally instead of widening the page. Images are responsive
and retain their intrinsic aspect ratio.

## Navigation

The shared header gains a `Posts` link. Existing fragment links become
root-relative so they also work from posts pages:

- Brand: `/`
- Experience: `/#experience`
- Posts: `/posts/`
- Contact: existing email action

The header remains compact on mobile using the existing responsive rules,
extended only as needed for the additional link.

## Metadata and feeds

The shared head partial becomes page-aware:

- The homepage preserves its current site title, description, social image,
  Twitter card, and `Person` structured data.
- The posts archive uses its own title and description.
- An article uses `<article title> — <site name>`, its front-matter description,
  canonical URL, `article` Open Graph type, publication date, and `Article`
  JSON-LD while retaining the author identity.

The section uses Hugo's RSS output. The head includes an alternate RSS link
when the current page has an RSS output format.

No taxonomy kinds are enabled; the existing `disableKinds = ["taxonomy",
"term"]` setting remains unchanged.

## Styling

Posts styles extend `assets/css/main.css` and reuse the established paper,
ink, teal, spacing, sans-serif, and monospaced design tokens. The archive uses a
simple editorial list rather than cards with heavy decoration. Article pages
prioritize typography and whitespace while retaining the portal's header and
footer, making the area feel related but distinct from the CV landing page.

The first draft article contains realistic technical prose and a bundled image
resource. It has no external image dependency.

## Compatibility and failure behavior

Templates and configuration must build under the repository's CI Hugo version,
0.139.0, and the current local Hugo version, 0.155.0. The deployment workflow is
not changed as part of this feature.

Missing optional descriptions fall back to Hugo's generated page summary in
the archive. Invalid Markdown or template syntax fails the Hugo build rather
than producing a partial deployment. Missing article resources are caught by
the visual preview and by explicit verification for the bundled image.

## Verification

`scripts/verify-site.sh` continues to protect the existing homepage and CV and
adds checks against a temporary Hugo build:

- `/posts/index.html` exists and contains the archive heading.
- The draft example article is built by running the verification build with
  drafts enabled.
- The archive links to the example article.
- The article contains its title, description, body content, and bundled image.
- The article emits its canonical URL, Open Graph article type, and Article
  structured data.
- The posts pages link back to the homepage and posts archive.
- The configuration explicitly sets the page size to ten.
- The normal production build succeeds and does not publish the draft article.

The implementation is complete when both the verification script and a direct
production Hugo build pass with both supported Hugo versions where available.

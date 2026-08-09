# Portal CV PDF — Design

Date: 2026-08-09

## Problem

The portal gives visitors nothing to take away. A prospective client or recruiter
who wants to keep or forward Vladislav's details has to bookmark a URL.

Printing the existing homepage does not solve this. Verified by generating a PDF
from the built site with headless Chrome:

- The output runs to 10 pages.
- Page 1 is roughly half empty — the hero is sized to fill a browser viewport,
  not a sheet of A4.
- The "Skip to content" accessibility link renders as a visible black button.
- `assets/css/main.css:1023-1027` hides `.contact-section` and `.footer` in
  print. Those partials are the only place the email, LinkedIn, GitHub, Upwork,
  and Telegram links appear, so the printed document has no contact details at
  all.

The 30-line `@media print` block in `main.css` is an afterthought. No amount of
patching turns a viewport-scaled landing page into a CV.

## Goals

- A downloadable PDF CV, visually consistent with the portal.
- Content sourced entirely from `data/home.yaml` — no second copy to maintain.
- Regenerates automatically when content changes.
- Parses correctly in applicant-tracking systems.

## Non-goals

- A capability brief or service one-pager. This is a conventional CV.
- Per-role achievement bullets written for the CV. Decided against; see below.
- Changes to the portal's own `@media print` block. Vestigial once the CV page
  exists, but out of scope.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Document type | Classic CV / resume | Chronological history is what recipients expect to receive and forward. |
| Visual treatment | Branded single-column | Portal typography and accent, but linear reading order and selectable text. Two-column layouts are frequently scrambled by ATS parsers, which interleave sidebar text into job descriptions. |
| Per-role content | Reuse portal prose verbatim | Single source of truth, zero drift. Trade-off accepted: reads closer to marketing copy than to achievement bullets. Enriching later is a `data/home.yaml` content edit, not a rebuild. |
| Generation | Headless Chrome in CI | The PDF cannot disagree with the site. A locally-generated committed PDF goes stale silently; a `window.print()` button surrenders control of filename and margins to the visitor. |
| Degree field | Information Systems | Confirmed against WES verification. `data/home.yaml:155-156` is correct; the brief is wrong at lines 115-116 and 722. |

## Content mapping

| CV section | Source |
|---|---|
| Header — name, title, location | `hugo.toml` `[params]` |
| Header — contact links | `hugo.toml` `[[params.contacts]]` |
| Professional summary | `hero.summary` |
| Core strengths | `capabilities.items` (6) — title + description |
| Experience | `experience.items` (5) — role, company, period, description |
| Technical depth | `expertise.groups` (3) |
| Independent R&D | `expertise.research` |
| Education | `expertise.education` |

Excluded: the `approach` five-step section and the `contact` section's
call-to-action copy ("Have a difficult backend or data-platform problem?" and
its button). Both are portal-narrative devices that read as pitch copy in a CV,
and cutting them is what holds the document to two pages. This does not affect
the contact *links* themselves, which move into the CV header.

Excluded on policy grounds: the confidential financial-platform role. The brief
gates it on NDA confirmation, and `scripts/verify-site.sh:62-66` fails the build
if that wording appears.

## Visual design

Dedicated stylesheet at `assets/css/cv.css`. Not an extension of `main.css` —
the two have incompatible sizing models.

- `@page { size: A4; margin: 14mm }`
- Body type ~10pt with fixed sizes, replacing the viewport-relative `clamp()`
  scale the site uses.
- `print-color-adjust: exact` so the teal accent survives Chrome's PDF export.
- Retained from the portal: typeface stack, teal accent on section headings and
  rules, uppercase mono treatment for labels.
- Dropped: decorative arc, full-viewport hero, dark inverted panels.
- `break-inside: avoid` on each experience entry so a role never splits across
  pages.

No page numbers. Chrome's `--no-pdf-header-footer` removes them, and CSS `@page`
margin-box counters are not supported by its print pipeline. Acceptable for a
two-page document.

## Architecture

### Hugo output format

```toml
[outputFormats.CV]
  mediaType = "text/html"
  baseName  = "cv"
  isHTML    = true

[outputs]
  home = ["HTML", "RSS", "CV"]
```

`RSS` must be retained — the current build emits `index.xml` and dropping it
from the list would silently remove the feed.

This renders `layouts/index.cv.html` to `/cv.html`.

Verified during design against a scratch copy of the repo: `cv.html` is emitted,
`index.html` and `index.xml` are preserved, all five contacts resolve from
`hugo.toml` params, all five roles resolve from `data/home.yaml`, and the output
contains no skip-link, header, or footer markup.

`index.cv.html` is a **standalone document** — a complete `<html>` document with
no `{{ define "main" }}` block, so Hugo applies no base template. This is what
structurally eliminates the skip link, site nav, and footer, rather than hiding
them individually. It also avoids depending on Hugo's `baseof.cv.html` lookup
resolving as expected.

### Build pipeline

```
deploy.yml
  ├─ hugo --gc --minify              → public/
  ├─ browser-actions/setup-chrome
  ├─ python3 -m http.server 8080 --directory public   (background)
  ├─ poll until :8080 responds
  ├─ chrome --headless=new --no-sandbox --disable-gpu \
  │    --no-pdf-header-footer --virtual-time-budget=10000 \
  │    --print-to-pdf=public/cv.pdf http://127.0.0.1:8080/cv.html
  ├─ kill server
  └─ upload-pages-artifact
```

Two constraints, both established by testing during design:

1. **The export must run against HTTP, not `file://`.** Hugo emits
   root-absolute fingerprinted asset paths (`/css/main.min.<hash>.css`). Under
   `file://` Chrome resolves these against the filesystem root, they 404, and
   the PDF renders as unstyled Times New Roman. This was observed, not
   theorised.
2. **`--no-sandbox` is required** for Chrome under the CI container.

The PDF step carries `continue-on-error: true`. A Chrome failure in CI must not
block the site deploy. Accepted trade-off: if the step fails, the site ships
without a `cv.pdf` and the download link 404s until the next successful build.
The failure is visible as a red step in the Actions run.

### Download entry point

`layouts/partials/contact.html` gains a secondary link to `/cv.pdf` alongside
the existing mailto button.

### Local preview

`scripts/build-cv.sh` — runs the same hugo → serve → Chrome sequence locally so
the PDF can be inspected before pushing. Resolves Chrome at the macOS path
`/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`.

## Verification

`scripts/verify-site.sh` is extended to build and assert against
`$portal_out_dir/cv.html` in addition to `index.html`:

- Contact details are present — email, LinkedIn, GitHub. This is the regression
  that made the naive print output useless, so it is asserted explicitly.
- Each content section renders: summary, core strengths, all five experience
  entries, technical depth, R&D, education.
- The existing prohibited-content checks (confidential exchange wording,
  marketplace metrics, availability language) apply to `cv.html` as well as
  `index.html`.
- No skip link, site nav, or footer markup in `cv.html`.

## Follow-ups

- `vladislav-positioning-and-portal-brief.md:115-116` and `:722` state Computer
  Science. WES verification confirms Information Systems. The brief should be
  corrected so the error does not resurface in future profile updates.
- The `@media print` block in `main.css:1015-1045` becomes vestigial. Leaving it
  means printing the homepage still produces a contact-less 10-page document.
  Worth removing or repointing at some later date.

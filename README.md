# Vladislav Troinich — personal portal and CV

The Hugo portal and PDF CV are separate documents with separate content sources:

- `data/home.yaml`: concise portal profile, selected achievements, skills, and contact copy.
- `hugo.toml`: site title, metadata, contact links, and public role positioning.
- `Vladislav_Troinich_CV.yaml`: complete standalone CV, including experience, skills, education, and contacts. It does not depend on Hugo.

The career conversation and positioning Markdown files are private working notes, not publishing inputs. Public copy omits the private project, its duration, its scale figures, and compensation. Relevant technical skills remain in the profile. Litmus employment begins in November 2017.

## Local preview

```sh
hugo server
```

The PDF link needs a generated PDF. To preview it with `hugo server`, copy a locally rendered PDF to `static/vladislav-troinich-cv.pdf` temporarily and remove it before committing; CI generates its own PDF. For a complete production preview, build both outputs into `public/` and serve that directory:

```sh
hugo --gc --minify
bash scripts/build-cv.sh ./public
python3 -m http.server 8080 --directory public
```

## Standalone CV

Use Python 3.12 or newer. CI uses Python 3.13 and the pinned RenderCV version in `requirements-cv.txt`.

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-cv.txt
bash scripts/build-cv.sh
```

The script prefers the repository's `.venv/bin/rendercv` and writes `rendercv_output/vladislav-troinich-cv.pdf`. Set `RENDERCV_BIN` to use another executable. RenderCV/Typst may need network access for its initial package download.

To render directly while adjusting content and layout:

```sh
.venv/bin/rendercv render Vladislav_Troinich_CV.yaml
```

Inspect page breaks, link targets, and extracted text after rendering. The CV retains substantive career detail rather than forcing a fixed page count. Keep actual employment titles in experience entries; the headline describes target positioning.

## Verification and deployment

```sh
bash scripts/verify-site.sh
```

This checks Hugo output, public profile content, published posts, draft exclusion, pagination, metadata, and feed behavior. PDF rendering is a separate step.

GitHub Actions builds on pushes to `master` and manual runs. It builds Hugo, installs RenderCV, generates the independent CV, verifies the site, and deploys `public/` to GitHub Pages. PDF generation is required: a failure stops deployment before the Pages artifact is uploaded. Only the finished PDF is copied into the site at `/vladislav-troinich-cv.pdf`; YAML and intermediate files are not deployed.

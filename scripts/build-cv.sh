#!/usr/bin/env bash
# Generate the independent CV. Does not build or read the Hugo portal.
# Default output is rendercv_output/; CI passes public/ after building Hugo.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_dir="${1:-$repo_root/rendercv_output}"
mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"

rendercv_bin="${RENDERCV_BIN:-}"
if [[ -z "$rendercv_bin" ]]; then
  if [[ -x "$repo_root/.venv/bin/rendercv" ]]; then
    rendercv_bin="$repo_root/.venv/bin/rendercv"
  else
    rendercv_bin="$(command -v rendercv || true)"
  fi
fi
if [[ -z "$rendercv_bin" ]]; then
  printf 'RenderCV not found. Install requirements-cv.txt in a virtual environment.\n' >&2
  exit 1
fi

# Render away from the published directory so only the finished PDF is shipped.
cv_build_dir="$(mktemp -d "${TMPDIR:-/tmp}/rendercv-build.XXXXXX")"
trap 'rm -rf "$cv_build_dir"' EXIT
"$rendercv_bin" render "$repo_root/Vladislav_Troinich_CV.yaml" \
  --output-folder "$cv_build_dir" \
  --pdf-path "$cv_build_dir/vladislav-troinich-cv.pdf" \
  --dont-generate-png --dont-generate-html --dont-generate-markdown

test -s "$cv_build_dir/vladislav-troinich-cv.pdf"
cp "$cv_build_dir/vladislav-troinich-cv.pdf" "$out_dir/vladislav-troinich-cv.pdf"
printf 'Wrote %s/vladislav-troinich-cv.pdf\n' "$out_dir"

#!/usr/bin/env bash
#
# Builds the site and exports /cv.html to public/vladislav-troinich-cv.pdf.
# The filename is what lands on the recipient's disk, so it carries the name.
#
# The export runs against a local HTTP server rather than file://. Hugo emits
# root-absolute fingerprinted asset paths, which file:// resolves against the
# filesystem root, producing a completely unstyled PDF.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_dir="${1:-$repo_root/public}"
port="${CV_PDF_PORT:-8741}"

chrome_bin="${CHROME_BIN:-}"
if [[ -z "$chrome_bin" ]]; then
  for candidate in \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium" \
    "$(command -v google-chrome || true)" \
    "$(command -v chromium || true)"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      chrome_bin="$candidate"
      break
    fi
  done
fi

if [[ -z "$chrome_bin" ]]; then
  printf 'No Chrome or Chromium found. Set CHROME_BIN to its path.\n' >&2
  exit 1
fi

hugo --gc --minify --destination "$out_dir" >/dev/null

if [[ ! -f "$out_dir/cv.html" ]]; then
  printf 'Build did not produce cv.html. Check the CV output format in hugo.toml.\n' >&2
  exit 1
fi

python3 -m http.server "$port" --bind 127.0.0.1 --directory "$out_dir" >/dev/null 2>&1 &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true' EXIT

for _ in $(seq 1 50); do
  if curl -fsS -o /dev/null "http://127.0.0.1:$port/cv.html" 2>/dev/null; then
    break
  fi
  sleep 0.1
done

if ! curl -fsS -o /dev/null "http://127.0.0.1:$port/cv.html"; then
  printf 'Local server did not come up on port %s.\n' "$port" >&2
  exit 1
fi

"$chrome_bin" \
  --headless=new \
  --disable-gpu \
  --no-sandbox \
  --no-pdf-header-footer \
  --virtual-time-budget=10000 \
  --print-to-pdf="$out_dir/vladislav-troinich-cv.pdf" \
  "http://127.0.0.1:$port/cv.html" >/dev/null 2>&1

if [[ ! -s "$out_dir/vladislav-troinich-cv.pdf" ]]; then
  printf 'Chrome did not produce a PDF.\n' >&2
  exit 1
fi

printf 'Wrote %s (%s bytes)\n' "$out_dir/vladislav-troinich-cv.pdf" "$(wc -c < "$out_dir/vladislav-troinich-cv.pdf" | tr -d ' ')"

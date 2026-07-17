#!/usr/bin/env bash

set -euo pipefail

portal_out_dir="$(mktemp -d "${TMPDIR:-/tmp}/cv-portal.XXXXXX")"
trap 'rm -rf "$portal_out_dir"' EXIT

hugo \
  --gc \
  --minify \
  --cacheDir "${TMPDIR:-/tmp}/cv-hugo-cache" \
  --destination "$portal_out_dir" >/dev/null

portal_index="$portal_out_dir/index.html"

assert_contains() {
  local expected="$1"
  if ! rg --quiet --fixed-strings "$expected" "$portal_index"; then
    printf 'Missing required output: %s\n' "$expected" >&2
    return 1
  fi
}

assert_contains 'I design and stabilize distributed systems that move critical data reliably.'
assert_contains 'id=capabilities'
assert_contains 'id=approach'
assert_contains 'id=experience'
assert_contains 'id=expertise'
assert_contains 'id=contact'
assert_contains 'Discuss an engineering challenge'
assert_contains 'alt="Vladislav Troinich"'
assert_contains 'rel=canonical'
assert_contains 'property="og:title"'
assert_contains 'name=twitter:card'
assert_contains 'application/ld+json'
assert_contains 'PyTorch'
assert_contains 'large financial datasets'
assert_contains 'crypto'

if rg --ignore-case --quiet \
  'billed (upwork )?hours|hours[ /-]*per[ /-]*week|weekly availability|\$[0-9]+[ /-]*(hour|hr)|\$100k|4,20[01].*hours' \
  "$portal_index"; then
  printf 'Marketplace metrics or availability language found in generated page.\n' >&2
  exit 1
fi

if rg --quiet '01 / 04|class=data-flow|do not generalize' "$portal_index"; then
  printf 'Removed decorative or ML-results language found in generated page.\n' >&2
  exit 1
fi

printf 'Portal verification passed\n'

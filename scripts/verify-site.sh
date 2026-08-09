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

assert_contains 'Lead Go Engineer & Software Architect'
assert_contains 'Distributed · Edge · Data Systems'
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
assert_contains 'Building production software since 2008'
assert_contains 'MQTT'
assert_contains 'NATS'
assert_contains 'Kafka'
assert_contains 'PostgreSQL'
assert_contains 'InfluxDB'
assert_contains 'Redis'
assert_contains 'gRPC'
assert_contains 'GraphQL'
assert_contains 'Prometheus'
assert_contains 'Independent R&amp;D'
assert_contains 'PyTorch'
assert_contains 'large financial datasets'
assert_contains 'crypto'

if rg --ignore-case --quiet \
  'billed (upwork )?hours|hours[ /-]*per[ /-]*week|weekly availability|\$[0-9]+[ /-]*(hour|hr)|\$100k|4,20[01].*hours' \
  "$portal_index"; then
  printf 'Marketplace metrics or availability language found in generated page.\n' >&2
  exit 1
fi

if rg --quiet '01 / 04|class=data-flow|do not generalize|I design and stabilize distributed systems' "$portal_index"; then
  printf 'Removed decorative or ML-results language found in generated page.\n' >&2
  exit 1
fi

if rg --ignore-case --quiet \
  'clickhouse|confidential (crypto )?exchange|production exchange platform' \
  "$portal_index"; then
  printf 'Prohibited technology or confidential engagement language found in generated page.\n' >&2
  exit 1
fi

printf 'Portal verification passed\n'

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
portal_cv="$portal_out_dir/cv.html"

assert_contains() {
  local expected="$1"
  if ! rg --quiet --fixed-strings "$expected" "$portal_index"; then
    printf 'Missing required output: %s\n' "$expected" >&2
    return 1
  fi
}

assert_cv_contains() {
  local expected="$1"
  if ! rg --quiet --fixed-strings "$expected" "$portal_cv"; then
    printf 'Missing required CV output: %s\n' "$expected" >&2
    return 1
  fi
}

assert_contains 'Lead Go Engineer & Software Architect'
assert_contains 'Distributed · Edge · Data Systems'
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

if [[ ! -f "$portal_cv" ]]; then
  printf 'CV page was not generated. Check the CV output format in hugo.toml.\n' >&2
  exit 1
fi

# Contact details are the regression that made the naive print output useless,
# so assert them explicitly rather than relying on section checks.
assert_cv_contains 'vladislav@troinich.pro'
assert_cv_contains 'linkedin.com/in/vladtr'
assert_cv_contains 'github.com/antlad'
assert_cv_contains 'Tbilisi, Georgia'

# The minifier leaves a bare & here, unlike the portal page which keeps &amp;.
assert_cv_contains 'Lead Go Engineer & Software Architect'
assert_cv_contains 'Building production software since 2008'
assert_cv_contains 'Experience'
assert_cv_contains 'Technical depth'
assert_cv_contains 'Education'
assert_cv_contains 'Information Systems'

# Every role must reach the CV.
for company in 'Litmus Automation' 'Sberbank Technology' 'NIPK Electron' 'Bank Otkritie'; do
  assert_cv_contains "$company"
done

# Site chrome must not leak into the CV; it has no base template by design.
if rg --quiet 'skip-link|site-header|class="footer"' "$portal_cv"; then
  printf 'Site chrome (skip link, header, or footer) leaked into the CV page.\n' >&2
  exit 1
fi

# The prohibited-content rules apply to the CV as well as the portal.
if rg --ignore-case --quiet \
  'billed (upwork )?hours|hours[ /-]*per[ /-]*week|weekly availability|\$[0-9]+[ /-]*(hour|hr)|\$100k|4,20[01].*hours' \
  "$portal_cv"; then
  printf 'Marketplace metrics or availability language found in the CV page.\n' >&2
  exit 1
fi

if rg --ignore-case --quiet \
  'clickhouse|confidential (crypto )?exchange|production exchange platform' \
  "$portal_cv"; then
  printf 'Prohibited technology or confidential engagement language found in the CV page.\n' >&2
  exit 1
fi

assert_contains 'href=/vladislav-troinich-cv.pdf'

printf 'Portal and CV verification passed\n'

#!/usr/bin/env bash

set -euo pipefail

portal_out_dir="$(mktemp -d "${TMPDIR:-/tmp}/cv-portal.XXXXXX")"
portal_prod_out_dir="$(mktemp -d "${TMPDIR:-/tmp}/cv-portal-prod.XXXXXX")"
portal_pagination_out_dir="$(mktemp -d "${TMPDIR:-/tmp}/cv-portal-pages.XXXXXX")"
portal_pagination_content_dir="$(mktemp -d "${TMPDIR:-/tmp}/cv-portal-content.XXXXXX")"
trap 'rm -rf "$portal_out_dir" "$portal_prod_out_dir" "$portal_pagination_out_dir" "$portal_pagination_content_dir"' EXIT

hugo \
  --buildDrafts \
  --gc \
  --minify \
  --cacheDir "${TMPDIR:-/tmp}/cv-hugo-cache" \
  --destination "$portal_out_dir" >/dev/null

cp -R content/. "$portal_pagination_content_dir/"
for post_number in $(seq -w 1 11); do
  fixture_dir="$portal_pagination_content_dir/posts/pagination-fixture-$post_number"
  mkdir -p "$fixture_dir"
  if [[ "$post_number" == "01" ]]; then
    printf -- '---\ntitle: "Pagination fixture %s"\ndate: 2026-08-%s\ndraft: true\n---\n\nFallback summary from article body.\n' \
      "$post_number" "$post_number" >"$fixture_dir/index.md"
  else
    printf -- '---\ntitle: "Pagination fixture %s"\ndate: 2026-08-%s\ndescription: "Generated pagination fixture %s."\ndraft: true\n---\n\nFixture body.\n' \
      "$post_number" "$post_number" "$post_number" >"$fixture_dir/index.md"
  fi
done

hugo \
  --gc \
  --minify \
  --cacheDir "${TMPDIR:-/tmp}/cv-hugo-cache" \
  --contentDir "$portal_pagination_content_dir" \
  --destination "$portal_prod_out_dir" >/dev/null

hugo \
  --buildDrafts \
  --gc \
  --minify \
  --cacheDir "${TMPDIR:-/tmp}/cv-hugo-cache" \
  --contentDir "$portal_pagination_content_dir" \
  --destination "$portal_pagination_out_dir" >/dev/null

portal_index="$portal_out_dir/index.html"
portal_llms="$portal_out_dir/llms.txt"
portal_posts="$portal_out_dir/posts/index.html"
portal_prod_posts="$portal_prod_out_dir/posts/index.html"
portal_pagination_page_two="$portal_pagination_out_dir/posts/page/2/index.html"
portal_article="$portal_out_dir/posts/self-hosted-llm-nats-rust/index.html"
portal_posts_feed="$portal_out_dir/posts/index.xml"
portal_prod_article="$portal_prod_out_dir/posts/self-hosted-llm-nats-rust/index.html"
portal_prod_posts_feed="$portal_prod_out_dir/posts/index.xml"
portal_old_writing="$portal_out_dir/writing/index.html"
portal_stylesheet="$(find "$portal_out_dir/css" -maxdepth 1 -type f -name 'main.min.*.css' -print -quit)"

assert_contains() {
  local expected="$1"
  if ! rg --quiet --fixed-strings "$expected" "$portal_index"; then
    printf 'Missing required output: %s\n' "$expected" >&2
    return 1
  fi
}

assert_file_contains() {
  local file="$1"
  local expected="$2"
  if [[ ! -f "$file" ]] || ! rg --quiet --fixed-strings "$expected" "$file"; then
    printf 'Missing required output in %s: %s\n' "$file" "$expected" >&2
    return 1
  fi
}

assert_file_not_contains() {
  local file="$1"
  local unexpected="$2"
  if [[ -f "$file" ]] && rg --quiet --fixed-strings "$unexpected" "$file"; then
    printf 'Unexpected output in %s: %s\n' "$file" "$unexpected" >&2
    return 1
  fi
}

assert_file_absent() {
  local file="$1"
  if [[ -e "$file" ]]; then
    printf 'Unexpected generated file: %s\n' "$file" >&2
    return 1
  fi
}

assert_contains 'Staff / Lead Software Engineer'
assert_contains 'Distributed systems · Data platforms'
assert_contains 'id=experience'
assert_contains 'id=expertise'
assert_contains 'id=contact'
assert_contains 'Discuss a role or project'
assert_contains 'alt="Vladislav Troinich"'
assert_contains 'rel=canonical'
assert_contains 'property="og:title"'
assert_contains 'name=twitter:card'
assert_contains 'application/ld+json'
assert_contains '18+ years'
assert_contains 'MQTT'
assert_contains 'NATS'
assert_contains 'Kafka'
assert_contains 'PostgreSQL'
assert_contains 'InfluxDB'
assert_contains 'Redis'
assert_contains 'gRPC'
assert_contains 'GraphQL'
assert_contains 'Prometheus'
assert_contains 'Remote worldwide'
assert_contains '250+'
assert_contains 'Nov 2017'

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

# The standalone PDF has its own RenderCV source; Hugo must not emit the old CV.
assert_file_absent "$portal_out_dir/cv.html"
assert_file_contains "$portal_llms" 'vladislav-troinich-cv.pdf'
assert_file_contains "$portal_llms" 'Nov 2017'
for profile_file in "$portal_index" "$portal_llms"; do
  if rg --ignore-case --quiet 'crypto|private team|private project|50k|500k|150k|10[,.]?300' "$profile_file"; then
    printf 'Private career details found in %s.\n' "$profile_file" >&2
    exit 1
  fi
done

assert_contains 'href=/vladislav-troinich-cv.pdf'

assert_file_contains "$portal_posts" 'Posts'
assert_file_contains "$portal_posts" '/posts/self-hosted-llm-nats-rust/'
assert_file_contains "$portal_posts" 'What can an offline LLM running on a single DGX Spark actually do?'
assert_file_contains "$portal_prod_posts" '/posts/self-hosted-llm-nats-rust/'
assert_file_contains "$portal_pagination_page_two" 'href=/posts/'
assert_file_contains "$portal_article" 'What can an offline LLM running on a single DGX Spark actually do?'
assert_file_contains "$portal_article" 'I wanted to test it with something bigger than a toy project.'
assert_file_contains "$portal_article" 'Intro'
assert_file_contains "$portal_article" 'class=highlight'
assert_file_contains "$portal_article" 'optimisation_2.png'
assert_file_contains "$portal_article" 'href=/posts/'
assert_file_contains "$portal_article" 'href=/'
assert_file_contains "$portal_article" '<title>What can an offline LLM running on a single DGX Spark actually do? — Vladislav Troinich</title>'
assert_file_contains "$portal_article" 'property="og:type" content="article"'
assert_file_contains "$portal_article" 'href=https://troinich.pro/posts/self-hosted-llm-nats-rust/'
assert_file_contains "$portal_article" 'datePublished'
assert_file_contains "$portal_article" '"@type":"Article"'
assert_contains '"@type":"Person"'
assert_contains 'href=/posts/'
assert_file_contains "$portal_posts_feed" 'What can an offline LLM running on a single DGX Spark actually do?'
assert_file_contains "$portal_prod_article" 'What can an offline LLM'
assert_file_contains "$portal_prod_posts_feed" 'What can an offline LLM running on a single DGX Spark actually do?'
assert_file_absent "$portal_old_writing"
assert_file_absent "$portal_prod_out_dir/posts/pagination-fixture-01/index.html"
assert_file_not_contains "$portal_prod_posts" 'Pagination fixture'
assert_file_not_contains "$portal_prod_posts_feed" 'Pagination fixture'

if ! rg --quiet --fixed-strings 'Fallback summary from article body.' \
  "$portal_pagination_out_dir/posts/index.html" \
  "$portal_pagination_page_two"; then
  printf 'Generated article summary did not reach either posts archive page.\n' >&2
  exit 1
fi

if ! hugo config | rg --quiet '^pagersize = 10$|^  pagersize = 10$'; then
  printf 'Hugo pagination is not configured for ten articles per page.\n' >&2
  exit 1
fi

assert_file_contains "$portal_stylesheet" '.posts-archive'
assert_file_contains "$portal_stylesheet" '.article-body'
assert_file_contains "$portal_stylesheet" '.pagination'
assert_file_contains "$portal_stylesheet" 'max-width:70ch'
assert_file_contains "$portal_stylesheet" '.article-body pre{overflow-x:auto'

printf 'Portal and posts verification passed (PDF rendering is separate)\n'

#!/usr/bin/env bash
# Lists what /verify must check, relative to a base ref.
# Usage: changed.sh [base-ref]   (default: the remote's default branch, e.g. origin/main)
# Output: "## FILES" (changed files that still exist) and "## TESTS" (tests to run).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

default_base() {
  local ref
  ref="$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  [ -n "$ref" ] && { echo "$ref"; return; }
  for b in origin/main origin/master main master; do
    git rev-parse -q --verify "$b" >/dev/null && { echo "$b"; return; }
  done
  echo HEAD
}

BASE_REF="${1:-$(default_base)}"
BASE="$(git merge-base HEAD "$BASE_REF")"

FILES="$( { git diff --name-only "$BASE" HEAD; git diff --name-only HEAD; git ls-files --others --exclude-standard; } | sort -u )"

echo "BASE $BASE_REF ($BASE)"
echo "## FILES"
while IFS= read -r f; do if [ -n "$f" ] && [ -f "$f" ]; then echo "$f"; fi; done <<< "$FILES"

is_test() { [[ "$1" =~ \.(spec|test)\.[cm]?[jt]sx?$ || "$1" =~ (^|/)test_[^/]+\.py$ || "$1" =~ _test\.(py|go)$ ]]; }

echo "## TESTS"
while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  if is_test "$f"; then echo "$f"; continue; fi
  dir="$(dirname "$f")"; base="$(basename "$f")"; stem="${base%.*}"; ext="${base##*.}"
  for c in "$dir/$stem.spec.$ext" "$dir/$stem.test.$ext" "$dir/__tests__/$stem.spec.$ext" "$dir/__tests__/$stem.test.$ext" \
           "$dir/test_$stem.py" "$dir/${stem}_test.$ext"; do
    if [ -f "$c" ]; then echo "$c"; fi
  done
done <<< "$FILES" | sort -u

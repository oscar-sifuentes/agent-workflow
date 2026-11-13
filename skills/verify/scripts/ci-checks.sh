#!/usr/bin/env bash
# Runs the checks of /verify on the files a branch changed, with the commands in
# .agents/project.json. Used by the pr-checks CI workflow; runs locally too.
#
#   bash .agents/skills/verify/scripts/ci-checks.sh [base-ref]
#
# Steps: formatCheck, lint, typecheck (output filtered to changed files), test.
# A command that is empty or missing in project.json is skipped.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cfg=".agents/project.json"

project_cfg() {
  [ -f "$cfg" ] || return 0
  if command -v node >/dev/null 2>&1; then
    node -e 'const c=require(require("path").resolve(process.argv[1]));const v=process.argv[2].split(".").reduce((o,k)=>o&&o[k],c);if(v!=null)console.log(v)' "$cfg" "$1"
  else
    python3 -c 'import json,sys;v=json.load(open(sys.argv[1]))
for k in sys.argv[2].split("."):
    v=v.get(k) if isinstance(v,dict) else None
print(v if v is not None else "")' "$cfg" "$1"
  fi
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

bash "$here/../changed.sh" "${1:-}" > "$tmp/changed.txt"
pattern="$(project_cfg sourceFilePattern)"
pattern="${pattern:-\.(ts|tsx|js|jsx|mjs|cjs|py|go)$}"
# The kit's own files (.agents/, .claude/) are not project code.
awk '/^## FILES/{f=1;next} /^## TESTS/{f=0} f' "$tmp/changed.txt" | grep -vE '^\.(agents|claude)/' | grep -E "$pattern" > "$tmp/files.txt" || true
awk '/^## TESTS/{f=1;next} f' "$tmp/changed.txt" | grep -vE '^\.(agents|claude)/' > "$tmp/tests.txt" || true

echo "Changed source files:"; cat "$tmp/files.txt"
echo "Tests to run:"; cat "$tmp/tests.txt"

# Replace {files} in a command with the list in $2 (one path per line).
run_on() {
  local cmd="$1" list="$2" files
  files="$(tr '\n' ' ' < "$list")"
  sh -c "${cmd//\{files\}/$files}"
}

status=0

for step in formatCheck lint; do
  cmd="$(project_cfg "commands.$step")"
  if [ -z "$cmd" ] || [ ! -s "$tmp/files.txt" ]; then echo "== $step: skipped"; continue; fi
  echo "== $step"
  run_on "$cmd" "$tmp/files.txt" || status=1
done

cmd="$(project_cfg commands.typecheck)"
if [ -n "$cmd" ] && [ -s "$tmp/files.txt" ]; then
  echo "== typecheck (errors in changed files only)"
  sh -c "$cmd" > "$tmp/types.txt" 2>&1 || true
  if grep -F -f "$tmp/files.txt" "$tmp/types.txt"; then
    echo "Type errors in files this branch changes"
    status=1
  fi
else
  echo "== typecheck: skipped"
fi

cmd="$(project_cfg commands.test)"
if [ -n "$cmd" ] && [ -s "$tmp/tests.txt" ]; then
  echo "== test"
  run_on "$cmd" "$tmp/tests.txt" || status=1
else
  echo "== test: skipped"
fi

exit "$status"

#!/usr/bin/env bash
# Self-test for the kit. Catches the bugs the pilots found, so they can't come back.
#
#   bash scripts/check-kit.sh
#
# 1. Every skill parses for the skills CLI (no skipped SKILL.md).
# 2. Every shell script has valid syntax.
# 3. changed.sh and ci-checks.sh exit 0 in a repo where a changed file has no test,
#    under `set -e` (as CI runs them).
# 4. ci-checks.sh ignores the kit's own files and substitutes {files}.
# 5. No private names (project, company, people) anywhere in the kit.
# 6. Templates: valid JSON, and every {{PLACEHOLDER}} is documented in setup-workflow.
# 7. link-skills.mjs repairs a Windows-style checkout (symlink as a text file).
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fail=1; }

# 1. Skills parse
out="$(cd "$root" && npx -y skills@latest add "$root" --list 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true)"
if echo "$out" | grep -q "SKILLS_SKILL_SKIPPED\|parse error"; then
  bad "skills parse"; echo "$out" | grep -A2 "SKIPPED\|parse error"
else
  found="$(echo "$out" | grep -oE 'Found [0-9]+ skills' || true)"
  expected="$(find "$root/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
  [ "$found" = "Found $expected skills" ] && ok "skills parse ($found)" || bad "skills parse: $found, expected $expected"
fi

# 2. Shell syntax
for f in $(find "$root/skills" "$root/scripts" -name '*.sh'); do
  bash -n "$f" || bad "syntax $f"
done
ok "shell syntax"

# 3-4. Scripts in a throwaway repo
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
(
  cd "$tmp"
  git init -q -b main && git config user.email t@t && git config user.name t
  mkdir -p .agents/skills src
  cp -R "$root/skills/verify" .agents/skills/verify
  cat > .agents/project.json <<'JSON'
{ "defaultBranch": "main", "sourceFilePattern": "\\.js$",
  "commands": { "lint": "echo LINT {files}", "formatCheck": "", "typecheck": "", "test": "echo TEST {files}" } }
JSON
  echo "a" > src/a.js && git add -A && git commit -qm base
  git branch -q base
  echo "b" > src/b.js && echo "x" > .agents/skills/verify/extra.js
  echo "// t" > src/a.test.js
  git add -A && git commit -qm change
  bash -c 'set -euo pipefail; bash .agents/skills/verify/changed.sh base > changed.txt'
) && ok "changed.sh exits 0 under set -e" || bad "changed.sh exit code"
out="$(cd "$tmp" && bash -c 'set -e; bash .agents/skills/verify/scripts/ci-checks.sh base' 2>&1)" && ok "ci-checks.sh exits 0" || bad "ci-checks.sh exit code"
echo "$out" | grep -q "LINT src/a.test.js src/b.js\|LINT src/b.js" && ok "ci-checks substitutes {files}" || bad "ci-checks {files}: $out"
echo "$out" | grep -q "extra.js" && bad "ci-checks checked kit files" || ok "ci-checks skips .agents/"
echo "$out" | grep -q "TEST src/a.test.js" && ok "ci-checks runs changed tests" || bad "ci-checks tests: $out"

# 5. No private names. The list is never committed: put a regex in
#    .private-names (git-ignored) or in the PRIVATE_NAMES env var / CI secret.
names="${PRIVATE_NAMES:-}"
[ -z "$names" ] && [ -f "$root/.private-names" ] && names="$(tr -d '\n' < "$root/.private-names")"
if [ -z "$names" ]; then
  echo "skip no private names (set PRIVATE_NAMES or .private-names)"
elif grep -rniE "$names" "$root" --exclude-dir=.git --exclude=.private-names | grep -v "recommended-skills.md"; then
  bad "private names in the kit"
else
  ok "no private names"
fi

# 6. Templates
t="$root/skills/setup-workflow/templates"
for j in "$t"/*.json; do node -e 'JSON.parse(require("fs").readFileSync(process.argv[1]))' "$j" || bad "json $j"; done
ok "template JSON"
missing=0
for p in $(grep -rhoE '\{\{[A-Z_]+\}\}' "$t" | sort -u); do
  grep -qF "$p" "$root/skills/setup-workflow/SKILL.md" || { bad "placeholder $p not documented in setup-workflow"; missing=1; }
done
[ "$missing" = 0 ] && ok "placeholders documented"

# 7. link-skills on a checkout without symlinks (as on Windows)
w="$tmp/win"; mkdir -p "$w"
(
  cd "$w"
  git init -q && git config user.email t@t && git config user.name t
  mkdir -p .agents/skills .claude && cp -R "$root/skills/." .agents/skills/
  ln -s ../.agents/skills .claude/skills && git add -A && git commit -qm base
  git config core.symlinks false && rm .claude/skills && git checkout -- .claude/skills
  [ -f .claude/skills ] || exit 1
  node .agents/skills/setup-workflow/scripts/link-skills.mjs > /dev/null
  [ -f .claude/skills/deliver/SKILL.md ] && [ -z "$(git status --porcelain)" ]
) && ok "link-skills repairs a symlink-less checkout" || bad "link-skills"

exit "$fail"

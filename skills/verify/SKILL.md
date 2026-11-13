---
name: verify
description: Check the current branch's changes before a commit or PR, in any repo. Runs format, lint, typecheck (filtered to changed files) and only the tests of the changed files, one step at a time with a single worker. Use after implementing a change, before a code review, or when asked to verify, check, or validate the work.
---

# Verify

Check only what changed, one step at a time, so the machine stays responsive. Never run a full test suite, and never run heavy commands in parallel.

## 1. Find what changed

Run the `changed.sh` script that sits next to this `SKILL.md` (wherever this skill is installed):

```bash
bash <this skill's folder>/changed.sh [base-ref]
```

The default base is the remote's default branch. When this branch started from another one, pass that branch instead (e.g. `origin/feat/x`). The script prints:
- `## FILES`: the changed files.
- `## TESTS`: the tests to run. These are the changed test files, plus the sibling `*.spec.*`, `*.test.*`, `__tests__/`, `test_*.py` and `*_test.*` files of each changed file.

If nothing changed, say so and stop.

## 2. Learn this repo's commands

Look for commands in this order, and use the first source that defines them:
1. `commands` in `.agents/project.json` (`format`, `lint`, `typecheck`, `test`; `{files}` stands for the file list).
2. `AGENTS.md` / `CLAUDE.md` at the repo root: a "Commands" or "Testing" section.
3. `package.json` scripts (`lint`, `typecheck`, `test`). The lockfile tells you the runner: `yarn.lock` → yarn, `pnpm-lock.yaml` → pnpm, `bun.lock*` → bun, otherwise npm.
4. Tool configs: prettier, eslint, `tsconfig.json`, `ruff`/`pyproject.toml`, `go.mod`.

Skip a step the repo has no tool for, and say it was skipped.

## 3. Run the checks in this order, one at a time

Run each check only on the changed files that apply to it. When the repo has `.agents/skills/verify/scripts/heavy.sh`, run the typecheck and the tests through it (`bash .agents/skills/verify/scripts/heavy.sh <cmd>`), so parallel agents don't run them at the same time.

1. **Format.** For example `npx prettier --check <files>` or `ruff format --check <files>`. If it fails, run the write/fix form on those same files, then note that you did.
2. **Lint.** For example `npx eslint <files>`, `ruff check <files>` or `go vet ./<pkgs>`. Fix errors in changed code. List warnings without fixing them.
3. **Types.** TypeScript: `npx tsc -p tsconfig.json --noEmit 2>&1 | grep -F -f <(printf '%s\n' <files>)`. Python: mypy on the changed files when the repo uses it. Only errors in changed files count. Pre-existing errors elsewhere are not yours.
4. **Tests.** Run only the `## TESTS` list, with one worker:
   - jest: `-w 1`
   - vitest: `--maxWorkers=1`
   - pytest: no `-n`
   - go: `go test -p 1 ./<pkgs>`

   Pass full paths. A short pattern can match a folder name and run everything.

A failure in code this branch changed: fix it before moving on. A failure in an untouched file is pre-existing: report it, don't fix it.

## 4. Report

1. A short table, one row per step: ✅ / ❌ / skipped, plus a count (files, errors, tests passed/failed).
2. Under the table, each failure: `file:line` and one line on the cause.
3. Changed source files that have no test. Call these out loudly when they handle money, auth or data access.
4. The risk zone of the change. Use the project's own definition when `AGENTS.md` has one; otherwise use the defaults in the `risk-review` skill. If the zone is red, suggest running the `risk-review` skill next.

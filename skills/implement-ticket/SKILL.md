---
name: implement-ticket
description: Build one ticket from docs/specs/<slug>/tickets/ test-first on its own ticket branch, verify it, commit it locally, write the report file and signal the /deliver orchestrator, which reviews and merges it. Run by each worker, whatever the agent (Claude, Codex, Grok, Antigravity) and whatever the runner (Orca, Herdr, sub-agent). Never pushes, merges or opens a PR.
---

You build exactly one ticket, as a worker of the `/deliver` orchestrator. Your brief gives you:

- the spec path and the ticket path
- the integration branch (`feat/<slug>`) and your ticket branch (`feat/<slug>--NN`)
- your worktree (you are already in it)
- the **report file** (an absolute path) and **how to signal** the orchestrator (the runner)

You never merge into `feat/<slug>`: you finish, report, and the orchestrator reviews and merges.

## A ticket in another repo

When your brief names a **repo** other than the one the spec lives in, your worktree is in that repo, and the spec, the ticket and these skills stay in the spec's repo (your brief gives their absolute paths).

- Read that repo's `AGENTS.md`, `CLAUDE.md` or `README.md`, whichever exist, for code style. If it has none, copy how its code is already written. The spec repo's domain and security rules still apply to anything that touches them.
- Its commands come from its own `.agents/project.json` if it has one, else its `package.json` (or build files) and its lockfile's package manager. Run only the checks of the files you changed, through the `heavy.sh` path in your brief.
- Don't edit the ticket file: the orchestrator sets its status. Docs upkeep applies only if that repo has a `CHANGELOG.md` or a README for what you changed.
- Everything else (branch, report file, signal, never push) is the same.

## Asking the orchestrator

Ask only when the answer can move money, change auth or access, or expose data, and the spec, the ticket, the code and `AGENTS.md` don't settle it. For anything else, pick the option the codebase already follows (or the simplest one), note it under "Decisions not in the spec" in your report, and keep going: the run is unattended. Use the runner's channel from your brief:

| Runner | How to ask |
|---|---|
| Orca | `orca orchestration ask --question "<question + your recommended answer>"`, then end your turn; Orca wakes you with the answer |
| Herdr | `hc send <orchestrator> "QUESTION NN: <question + your recommended answer>"`, then end your turn; the answer arrives as your next message |
| Sub-agent | write the report file with `RESULT: question`, then stop |

## Before writing code

1. Check that your worktree is on your ticket branch, created from the tip of the integration branch. If not, stop and report it; don't create worktrees yourself.
2. Read `AGENTS.md`, the spec (including its "Docs checked" table), your ticket, and the README of every module you will touch.
3. Set the ticket's status to `in-progress`.

## Build

- Run the `tdd` skill (`.agents/skills/tdd/SKILL.md`). Start with the ticket's invariant tests, then its acceptance criteria.
- Follow `AGENTS.md`: the domain rules, the code style, the module layout. For structure, copy how the touched module (or a similar one) already does it, and check framework and library APIs with Context7.
- **Library APIs come from the docs.** Before you use an external library API that this repo doesn't already use the same way (a new decorator, query builder method, validator, config option), look it up with Context7 for the version in `package.json`, as `AGENTS.md` describes. Copying a usage that already exists in the repo needs no lookup.
- Stay inside the ticket and inside your worktree. Don't start other agents.
- Run heavy commands through `bash .agents/skills/verify/scripts/heavy.sh <cmd>`, so only one runs at a time on the machine.

## Finish

1. Docs upkeep from `AGENTS.md`: one `CHANGELOG.md` bullet, plus the README of each module whose behaviour changed.
2. Run the `verify` skill (`.agents/skills/verify/SKILL.md`), using the integration branch as the base. Fix what fails in your code. Stop after 3 failed attempts and report `failed`.
3. Commit on your ticket branch (local only): `<type>(<module>): <ticket title>`. Running under /deliver authorizes these local commits; never push.
4. Merge the integration branch tip into your branch, so the orchestrator's merge is clean. Re-run the tests of your files if the merge brought changes.
5. Set the ticket's status to `done` and tick its criteria.

## Write the report file

Write it to the exact path in your brief: `.review/worker-report.md` inside your worktree (git-ignored, never committed). It is the source of truth: the orchestrator reads it, not your screen.

```markdown
# NN <ticket title>

- Branch: feat/<slug>--NN
- Commit: <full SHA of HEAD>
- Agent: <your agent and model>

## Files
- path — zone

## Invariant tests
- Invariant <n> → `file:line` → passing

## Decisions not in the spec
## Context7 lookups
- library @ version → what for
## Open questions / not tested

RESULT: done | failed | question
```

The last line must be exactly `RESULT: done`, `RESULT: failed` (say why above) or `RESULT: question` (the question above).

## Signal the orchestrator

| Runner | Signal |
|---|---|
| Orca | `orca orchestration send --type worker_done --outcome succeeded --subject "NN <title>: ready to merge" --body "<report file path>"` (`--outcome failed` when `RESULT: failed`). Omit `--to`; use the `--from`, `--task-id` and `--dispatch-id` values from Orca's injected preamble when it gives them |
| Herdr | `hc send <orchestrator> "DONE NN: <report file path>"` (or `FAILED NN: ...`) |
| Sub-agent | your final message: the report file path and its `RESULT` line |

Then stop. Don't start another ticket, and don't merge.

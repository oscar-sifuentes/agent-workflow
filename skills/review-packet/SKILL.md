---
name: review-packet
description: Write the review packet for a branch, .review/<branch>/REVIEW.md, which tells a human reviewer exactly which lines to read, which invariants are proven by which tests, what the agent decided on its own, and the e2e evidence. The same text becomes the PR description. Use at the end of /deliver, before the developer's review, or when asked to summarise a branch for review.
---

# Review packet

The reviewer should spend their time on the lines that can lose money, and trust the rest because it is proven. This packet tells them which is which.

Folder: `.review/<branch>/`, with `/` in the branch name replaced by `-`. `.review/` is git-ignored.

## Gather

0. The repos of the delivery: the `REPO` lines of `deliver-log.md`. Gather everything below **per repo** (`git -C <integration worktree>`) and write one packet, with a `## <repo>: feat/<slug>` block (base, files, zone, Must read) for each related repo after this repo's.
1. The diff against the delivery's base (the branch `/deliver` started from; usually `origin/<defaultBranch>`): `git diff --stat` and the per-file diffs. Use `git diff --color-moved=zebra` to separate pure moves from real changes.
2. The spec and tickets in `docs/specs/<slug>/`.
3. The latest `risk-review` output for the whole branch. Run it if there is none, or if the branch changed since. Its "Human review list" is the source for "Must read".
4. The test file and line for each spec invariant: find them, don't assume.
5. The e2e evidence in the same folder (`e2e-local.md`, `e2e-<environment>.md`).
6. The decisions the implementers reported that the spec didn't state (`deliver-log.md`).

## Write `REVIEW.md`

Write it in the `docsLanguage` of `.agents/project.json` (English when unset). Keep the headings below in English: other skills and the PR template look for them.

```markdown
## <Spec title> · Zone 🔴 · <N> files (<r> red, <y> yellow, <g> green/tests/docs)
Spec: docs/specs/<slug>/spec.md · Tickets: 01–05

## 👀 Must read (≈<lines> lines, ~<minutes> min)
Most dangerous first. Each entry: what to check, not just where.
1. `path/to/guard.ts:12-58`: HMAC over the raw body, fails closed when the key is missing
2. `path/to/service.ts:40-95`: idempotency key per txId; amount compared with the recorded bet

## Can skip
- Tests: covered by the table below
- Pure moves (`git diff --color-moved=zebra` shows no changed lines): <files>
- DTO declarations, module wiring, README, CHANGELOG

## Invariants → tests
| # | Invariant | Test | Result |
|---|---|---|---|
| 1 | Bad or missing signature → 403, nothing changes | `guard.spec.ts:20` | ✅ |

## Decisions the agent made (not in the spec)
- ...

## Review findings
Fixed: <count, one line each for blocker/major>. Still open: <list or "none">.

## Decisions the orchestrator made
Every `DECISION:` line from `deliver-log.md` (agent switches, answered questions, conflict resolutions, skipped steps), or "none". The developer reviews these here instead of being asked live.

## Who built it
Runner, agent and model per ticket, and effort or model changes from `deliver-log.md` (`03: high/standard → xhigh/standard, verify failed twice`), or "none".

## Not tested
What has no test and why. A concurrency invariant has no unit test (they mock the database); point to its parallel e2e scenario instead, or say it wasn't run.

## E2E
- Local: ✅ 7/7 scenarios (API) · UI: ✅ 3 screenshots · `.review/<branch>/e2e-local.md`
- Sandbox: ⏳ pending | ✅ <date>

## Deploy notes
Migrations (order, `down`, locks), flags to turn on, who gets it.
```

Keep "Must read" honest: every red line that changed belongs there. The `risk-review` list is the floor, not the ceiling. When the branch is yellow or green, "Must read" can be short, but say why.

## Then

Run the `render-html` skill in `review <branch>` mode (in Claude Code, the `html-renderer` sub-agent). Tell the developer the page path (`.review/<branch>/review.html`), the packet path and the total "Must read" size. After they review, `/open-pr` uses this file as the PR description.

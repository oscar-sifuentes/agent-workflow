<!--
Agents: fill this from .review/<branch>/REVIEW.md (the review-packet skill).
People: fill what applies. Keep it short; link instead of pasting.
-->

## Zone
🔴 red | 🟡 yellow | 🟢 green: <one line on why>

Spec: `docs/specs/<slug>/spec.md` · Tickets: <list> | none

## What changes
<2–4 lines>

## 👀 Must read
Most dangerous first, with what to check.
1. `path:lines`: <what to check>

## Can skip
<tests covered below, pure moves, wiring, docs>

## Invariants → tests
| # | Invariant | Test | Result |
|---|---|---|---|

## Decisions not in the spec
-

## E2E
- Local: <result + evidence>
- Shared environment: <name, result + date> | n/a

## Deploy notes
Migrations (with `down`), flags, who gets it, order of steps.

## Checklist
- [ ] `/verify` passes
- [ ] `risk-review` has no open blocker/major
- [ ] Every red change has an invariant test
- [ ] `CHANGELOG.md` and the affected READMEs are updated

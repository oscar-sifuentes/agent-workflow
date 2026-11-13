---
name: to-tickets
description: Break an approved spec (docs/specs/<slug>/spec.md) into tracer-bullet tickets, one file per ticket under docs/specs/<slug>/tickets/, each with its risk zone, blocking edges, acceptance criteria and the invariant tests it must add. Use after /to-spec, when the developer asks to split the work.
disable-model-invocation: true
---

# To tickets

Split the spec into tickets that an agent can build one at a time in a fresh context, and that a reviewer can read one PR-sized piece at a time.

## Rules for a ticket

- **Vertical slice.** A narrow but complete path through every layer it needs (DTO, guard, service, migration, tests), verifiable on its own. Not "all the DTOs", then "all the services".
- **One zone.** A ticket is red, yellow or green, never mixed. Move the README, CHANGELOG and docs into a green ticket only when they don't belong to a slice.
- **Prefactor first.** If the change is easier after a refactor, that refactor is its own ticket, a pure move, verifiable with `git diff --color-moved=zebra`.
- **Small.** It fits in one agent context. A red ticket should stay around a few hundred changed lines.
- **Blocking edges.** Each ticket lists the tickets that must land first. A ticket with none can start now.
- **Wide refactors** (a rename across the codebase) are expand → migrate in batches → contract, each step its own ticket.

## Steps

1. Read the spec. Stop if its status is not `approved`.
2. Draft the tickets. Show them as a numbered list: title, zone, blocked by, what it delivers.
3. Ask: is the size right, are the edges right, should any be merged or split? Iterate until the developer approves.
4. Write one file per ticket: `docs/specs/<slug>/tickets/NN-<short-title>.md`, numbered in dependency order, from `01`. Write them in the `docsLanguage` of `.agents/project.json` (English when unset), keeping the template's field names (`Zone`, `Blocked by`, `Status`) so `/deliver` can parse them.

## Ticket template

```markdown
# NN: <Title>

- **Zone:** 🔴 | 🟡 | 🟢
- **Blocked by:** 01, 02 | none
- **Status:** ready | in-progress | done

## What it delivers
The end-to-end behaviour, from the user's side.

## Acceptance criteria
- [ ] ...

## Invariant tests (red tickets)
The spec invariants this ticket must prove, by number, each written as the test it becomes:
- [ ] Invariant 2: "same txId twice credits once" → a test that sends it twice and asserts one credit

## Notes
Prior art in the codebase, seams to use.
```

5. Run the `render-html` skill in `spec <slug>` mode (in Claude Code, the `html-renderer` sub-agent) and give the developer the page path, `.review/specs/<slug>/index.html`. It shows the spec and the tickets on one page, for the final read before approving.

Once the developer approves the tickets, the next step is `/deliver <slug>`.

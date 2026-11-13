---
name: tdd
description: Test-driven development for this repo. Builds a ticket or fix as red → green cycles, starting with the invariant tests the spec or ticket names. Use when building a ticket, fixing a bug test-first, or when the developer mentions TDD or red-green.
---

# TDD

Build in red → green cycles. Each cycle: one failing test, then only the code that makes it pass.

## Where the tests come from

1. **The ticket's invariant tests come first.** For a red ticket, write each listed invariant as a failing test before any production code. Name the test after the invariant ("same txId twice credits once").
2. **Then the acceptance criteria**, one cycle each.
3. **Test at the agreed seams.** Use the seams in the spec (`docs/specs/<slug>/spec.md`). When there is no spec, propose the seams to the developer before writing tests, with one line on what each catches and misses.

## What a good test is

It checks behaviour through a public interface, so a refactor that keeps the behaviour keeps the test green. Examples: [tests.md](tests.md). When to mock: [mocking.md](mocking.md).

- **Expected values are independent literals** from the spec or a worked example, never recomputed the way the code computes them.
- **Mock only system boundaries:** external HTTP clients, queues, time. Not our own services.
- **Money and other exact values use exact literals** and the repo's own rounding helper, if `AGENTS.md` names one.

## Tests for red-zone paths

Use the domain rules in `AGENTS.md`; these shapes cover the usual ones:

| Invariant | Test shape |
|---|---|
| Bad input never reaches the state change | negative, zero, NaN and string amounts (or other invalid values) are rejected before the write |
| Idempotency | the same request twice → one balance change |
| Concurrency | N identical requests at once → exactly one wins. The database decides, so unit tests with mocks can't prove it: cover it with a parallel-request e2e scenario (see the `e2e` skill), or an integration test when the repo has a test database |
| Callback trust | bad signature → rejected; missing key → rejected (fail closed); confirmed amount ≠ recorded amount → rejected |
| Reversal | a rollback or refund restores exactly what the original operation changed |
| Access | user A cannot act on user B's ids; a user cannot set privileged fields (roles, verification flags) through their own endpoints |

## Running tests

Use the `test` command in `.agents/project.json` with the full test path and one worker. Never run the full suite. Run one heavy command at a time on the machine.

## Rules of the loop

- **Red before green.** See the test fail for the right reason before writing the code.
- **One slice at a time.** One test, the minimum code, repeat.
- **No speculative code.** Nothing the current test doesn't need.
- **Refactor after green**, in a separate step, keeping the tests green. Larger cleanups belong to review, not the loop.

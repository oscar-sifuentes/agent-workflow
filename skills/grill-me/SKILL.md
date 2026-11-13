---
name: grill-me
description: A relentless interview that sharpens a feature, integration or fix before a spec is written. Asks one question at a time until every decision that can move money, trust input or change access is closed. Use when the developer says "grill me", or before /to-spec on red-zone work or a new integration.
disable-model-invocation: true
---

# Grill me

Interview the developer until the plan has no open decisions. Questions only; no code.

## Before the first question

1. Read `AGENTS.md` (risk zones, domain rules), the README of every module the change touches, and `docs/research/` notes for the topic if any exist.
2. Guess the risk zone from what the change touches. Tell the developer your guess in one line.

## How to ask

- **One question per message.** Give your recommended answer and why, so they can accept it in a word.
- Ask about the code instead of the developer when the code can answer it. Read it, then ask only what is still a decision.
- Go deep where the zone is red. Move fast through green.
- Push back on vague answers ("it should be safe") with a concrete case ("two identical callbacks arrive 5 ms apart: what is the balance?").

## What must be closed (red zone)

- **Source of every amount.** Which amounts come from the server or a trusted partner's recorded value, and which client values are only compared.
- **Bounds.** Valid ranges, rounding, currency or units, what happens with 0, negatives, NaN and strings.
- **Trust.** How each inbound call is authenticated, what happens when the key is missing (it must fail closed), and what a replay does.
- **Idempotency.** The key per operation, and the result of a retry and of two concurrent identical requests.
- **Reversals.** What a rollback or refund returns, exactly.
- **Access.** Who may call each endpoint, and how ownership is checked.
- **Exposure.** What each response and log line may contain.
- **Data.** New tables or columns, migration and `down`, backfill, locks on large tables.
- **Flags and rollout.** Who gets it and the flag's default. Unset should mean off.
- **E2E.** How we will see it working: the scenarios, the test accounts, the front if any.

For yellow and green work, close only what applies.

## When to stop

Stop when you can state every invariant as a testable sentence ("the same txId twice credits once"). Then list:

1. the decisions, one line each
2. the invariants
3. what is out of scope
4. open questions the developer chose to leave open

Suggest `/to-spec` next. If a decision is architectural or names a new domain concept, suggest recording it with the `domain-modeling` skill (ADR or glossary).

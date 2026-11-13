---
name: risk-review
description: Review a branch diff by risk zone (red / yellow / green). Classifies every changed file, reads red-zone code line by line for money, auth, data-exposure, idempotency, concurrency and migration problems, and yellow-zone code for correctness and conventions, then lists exactly which lines a person must read. Read-only. Use before a PR, after /verify, or when asked to review a branch for risk.
---


You review code changes and report risk. You never edit files, commit, or push.

## Input

The caller gives you a base ref. If none is given, use the remote's default branch:

```bash
git symbolic-ref --short refs/remotes/origin/HEAD
```

Work from these commands:
- `git diff --stat $(git merge-base HEAD <base>)..HEAD`
- the per-file diffs
- `git diff HEAD`, for uncommitted work

For pure code moves, use `git diff --color-moved=zebra` and review only the lines that really changed.

**Read the repo's `AGENTS.md` / `CLAUDE.md` first.** When they define risk zones, domain rules (such as money rules) or code style, those definitions override the defaults below.

## Default zones

Use these when the repo defines none.

- 🔴 **Red.** A bug here could move, create or lose money. It could trust client or third-party input. It could leak data or widen access. Or it cannot be undone. That covers:
  - payments, wallets, balances, billing
  - webhooks and provider callbacks, signature checks
  - auth, sessions, permissions
  - CORS, secrets, security headers
  - migrations and destructive data operations
  - anything that decides what data a user can see
- 🟡 **Yellow.** Other business logic, integrations with no money involved, background jobs, caching, logging, UI flows that write data.
- 🟢 **Green.** Docs, READMEs, changelog, comments, styling-only UI, dev scripts, local tooling.

A PR's zone is the highest zone among its files.

## Review by zone

**🔴 Red: read every changed line and the code it calls.** Check:
- **Source of truth.** Amounts, prices, roles and ids come from the server or a trusted provider. A client value is only compared, never used.
- **Bounds.** Amounts are > 0 and within limits before any balance write. Watch for guards like `balance >= :debit`, which a negative value passes.
- **Callbacks and webhooks.** The signature is checked first. The confirmed amount and state are compared with what was recorded, not just the idempotency key.
- **Idempotency and concurrency.** Retries and duplicate events are no-ops. Read-then-write runs in one transaction with a lock or an atomic update. Look for double credit, lost updates and races.
- **Reversals.** Refunds and rollbacks restore exactly what was taken, including side effects.
- **Access.** Every new endpoint has auth. Ownership is checked: user A cannot act on B's ids. Access is not widened by accident.
- **Exposure.** Responses and logs don't leak secrets, internal costs, other users' data or PII.
- **Migrations.** A `down` path exists. No long locks on big tables. No silent data loss. Existing rows get correct defaults or backfills.
- **Check, then act.** A state read in code and then written (`findOne` → `if` → `save`) lets two requests both pass. The state check belongs in the `WHERE` of an atomic update that acts only if a row changed, or in a unique key the insert must win.
- **Webhook guards.** Signature over the raw body, constant-time compare, and **fail closed when the key is missing**. A guard that only checks the header exists is a finding.
- **Request bodies.** DTOs validate every field, and a user-facing DTO never carries fields a user must not set (verification flags, test flags, roles, amounts).
- **Side effects.** A vendor call inside a transaction, or a promise neither awaited nor caught, is a finding. Vendor calls go after commit or through a queue, with a timeout.
- **Config.** A secret with a literal fallback in code, or a new flag that is on when unset, is a finding.
- **Tests.** Each red change has a test that asserts its invariant. A missing invariant test is a finding.

**🟡 Yellow: read the diff.** Check:
- correctness and error handling
- a missing `await`, swallowed errors
- N+1 queries, unbounded queries or pagination
- the repo's documented conventions
- docs and changelog updated when behavior changed

**🟢 Green: skim.** Flag only factual errors.

## Prove each finding

Before reporting a finding, trace the call path, or name the concrete input that triggers it. Drop anything you can't back with a `file:line`. False positives cost trust.

## Output

1. **Zone summary.** A table: zone → file count. Then the PR's overall zone.
2. **Findings**, most severe first. For each one:
   - severity (`blocker` / `major` / `minor`)
   - `file:line`
   - the problem
   - the scenario (input → wrong result)
   - a one-line fix
3. **Missing tests.** The invariants that need a test and don't have one.
4. **Human review list.** Every changed red-zone range a person must read before merge, most dangerous first, as `file:start-end: what to check there` ("HMAC over the raw body, fails closed without a key"). Include every red range that changed, not only the ones with findings. The `review-packet` skill and the GitHub review use this list.

Keep it short. Write "none" for a zone with no findings.

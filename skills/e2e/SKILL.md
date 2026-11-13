---
name: e2e
description: Run end-to-end tests of a change against a running environment, through the API and through the browser like a QA tester, and save the evidence. Use after /verify and the reviews pass, when asked to test a feature end to end, or with "--target <environment>" after the branch is deployed to a shared test environment.
---

# E2E

Prove the change works in a running app, not just in unit tests. Two layers: the API, then the UI.

## 0. Environment

- Local (default): run the `dev-env` skill first and use what it reports.
- `--target <name>`: use that entry of `environments.shared` in `.agents/project.json` (its URLs); ask the developer for anything missing. Confirm that the branch under test is the one deployed there.

Follow the database rules in the `dev-env` skill. Never target production.

## 1. Scenarios

Scenarios come from the spec, not from the code: its user stories and its **invariants**. Look for `docs/specs/<slug>/e2e.md`. If it doesn't exist, write it from `docs/specs/<slug>/spec.md` and keep it in the repo, so the same scenarios run again locally, on the shared environment and in the next change.

Each scenario: the starting state, the steps, and the expected result, with exact numbers.

```markdown
## Duplicate charge is a no-op
- Start: user e2e-charge-1 with 100.00 credit
- POST /partner/charge (signed, txId=A, amount 10.00) → 200, balance 90.00
- Same request again → 200, balance still 90.00
- Stored rows: one debit for txId A
```

Cover at least: the happy path, every invariant in the spec, and one rejected input (bad signature, negative amount, another user's id).

When an invariant is about concurrency (credit once, refund once, cancel once, claim once), add a scenario that sends the same request at the same time, and check that money moved exactly once:

```markdown
## Two refunds of the same charge credit once
- Start: user e2e-refund-1 with 90.00 credit after charge txId=B (10.00)
- Send POST /partner/refund (txId=B) twice in parallel → both 200
- Balance 100.00, not 110.00; one refund row for txId B
```

Fire the requests together (`curl … & curl … & wait`, or `Promise.all` in a short script), and repeat the scenario a few times, since a race doesn't show up on every run. Unless the repo has integration tests on a real database, these are its only proof of concurrency, so never skip them.

## 2. API layer

Use `curl` or a short script against the API URL. For each scenario:
- record the request, the status and the response body (redact tokens and personal data)
- check the state the change affects through the API (balances, statuses, counts), before and after
- when the spec involves money or other critical state, also check the stored rows, read-only

Inbound webhooks need a valid signature. Use the partner's test key from the local env and sign the body the way the app's guard checks it. If you can't sign, say so; don't disable the guard.

## 3. UI layer

When the change is visible in a front end, test it like a QA tester.

### Pick the browser tool

Use the first one available, and write which one you used in the evidence file:

| # | Tool | Check | Session |
|---|---|---|---|
| 1 | `agent-browser` | `command -v agent-browser` | `agent-browser --session e2e-<slug> …`, headless; `agent-browser --session e2e-<slug> close` at the end. Never `--auto-connect`. |
| 2 | Playwright CLI | `command -v playwright-cli`, or `npx --no-install playwright --version` (then use `npx playwright cli`) | `playwright-cli -s=e2e-<slug> open <url>` (headless by default), `snapshot`, `click <ref>`, `screenshot`; `-s=e2e-<slug> close` at the end |
| 3 | Claude in Chrome | only when the agent is Claude Code and the `mcp__claude-in-chrome__*` tools exist | its own new tab, never one of the developer's tabs; close it at the end. It runs in the developer's real Chrome, so log in only with test accounts |

If none is available, don't install anything on your own and don't stop the run:
- run the API layer anyway;
- mark the UI layer `⏳ pending: no browser tool` in the evidence and in the review packet;
- tell the developer the install command, so they can run it and call `/e2e` again:
  `npm install -g agent-browser && agent-browser install` or `npm install -g @playwright/cli@latest`.

When the developer runs `/e2e` by hand (not inside `/deliver`), you may ask once whether to install one instead.

### Test

- Never drive the developer's open browser or tabs.
- Log in with a test account from the file named by `paths.testAccounts` in `.agents/project.json`, on a local or shared test host only.
- Walk the user stories in the spec. Take a screenshot at each key state, plus any error you hit. Save them in `.review/<branch>/screenshots/` as `NN-<what-it-shows>.png`, so the review page can show them.
- Check what the API layer already proved, from the user's side: the balance shown, the messages, the disabled buttons.
- Close the session when done.

Skip this layer when the change has no screen. Say that you skipped it and why.

## 4. Evidence

Write `.review/<branch>/e2e-<target>.md`, with `/` in the branch name replaced by `-` (`.review/` is git-ignored):

| Scenario | Layer | Result | Evidence |
|---|---|---|---|
| Duplicate bet is a no-op | API | ✅ | requests + balances |
| Balance updates after a bet | UI | ✅ | screenshot |

Then the failures in full: the step, the expected and actual result, and the request or screenshot. A failing scenario is a finding for the developer, not something to work around.

# AGENTS.md

Instructions for any coding agent (Claude Code, Codex, Gemini, Grok, Antigravity, Cursor, Copilot) and for people working in this repo. Keep it short. When an agent makes a mistake that a rule would have prevented, add the rule here.

<!-- PROJECT: what this is. Replace with 3-6 lines: what the product does, the stack, where the main code lives, which docs to read first. -->
## What this is

{{WHAT_THIS_IS}}

## Commands

The commands agents and CI run are in `.agents/project.json` (`commands`). The ones a person types:

```bash
{{COMMANDS}}
```

Run only the tests of the files you changed, with one worker. Never run the full suite locally.

When several agents work at once, run heavy commands (tests, typecheck, builds, Docker) through `bash .agents/skills/verify/scripts/heavy.sh <cmd>` so only one runs at a time on the machine.

## Library docs: Context7

Check library and framework APIs against their official docs with the Context7 CLI, never from memory. Recent major versions change APIs that are easy to recall from an older version.

```bash
npx ctx7@latest library "<Official name>" "<what you need>"   # → /org/project, with versions
npx ctx7@latest docs /org/project[/version] "<one concept>"
```

- Use the version the project's manifest pins (`/org/project/<version>` when the library lists versions).
- External libraries, frameworks and SDKs only, not this repo's own code.
- At most 3 commands per question. Never put secrets, tokens or personal data in a query.
- Each developer runs `npx ctx7@latest login` once; CI uses the `CONTEXT7_API_KEY` secret. On a quota or auth error, tell the developer; don't fall back to memory silently.

## Workflow

1. Plan: `/research` (new integration or API) → `/grill-me` (or `/grill-with-docs` for new domain terms) → `/to-spec` → `/to-tickets`. Specs and tickets live in `docs/specs/<slug>/`. The developer approves them.
2. Build: `/deliver <slug>` builds each ticket test-first in its own worktree, runs `/verify`, `/risk-review` and (red) `/code-review`, then `/dev-env` + `/e2e` locally, then `/review-packet`.
3. The developer reviews the packet, then `/open-pr`: draft PR, shared-environment e2e when there is one, ready for review.
4. The lead reviewer gives the final review before merge.

Green-zone changes skip the spec and tickets: implement → `/verify` → `/risk-review` → PR. Review evidence goes in `.review/<branch>/` (git-ignored), never in commits. Documents people read are written in the `docsLanguage` of `.agents/project.json`.

### Orchestrator and workers

`/deliver` makes the agent that runs it the **orchestrator**. Three things are independent:

- **Agent** (who builds a ticket): any of `claude`, `codex`, `gemini`, `grok`, `agy`, … With no answer, every worker is the same agent as the orchestrator; nothing defaults to a vendor.
- **Runner** (where workers run): Orca (`orca orchestration`), Herdr (`hc`), the tool's own sub-agents, or one at a time. Default: where the orchestrator runs.
- **Contract** (same for all): the orchestrator creates each ticket's worktree and writes its brief; the worker writes `.review/worker-report.md` in its worktree, ending in `RESULT: done | failed | question`, and signals through the runner.

When you are a worker:
- Build only your ticket, only in your worktree and on your ticket branch, following the `implement-ticket` skill. Don't start other agents.
- Never push, open a PR, or merge into the integration branch. Commit locally, write the report file and signal; the orchestrator reviews and merges.
- Ask the orchestrator instead of guessing on anything in the red zone.

The skills live in `.agents/skills/` and come from the agent-workflow kit: never edit them here (`npx skills update` overwrites them). Put project rules in this file and settings in `.agents/project.json`. If an agent doesn't see the skills (common on Windows, where git checks symlinks out as text files), run `node .agents/skills/setup-workflow/scripts/link-skills.mjs`.

<!-- PROJECT: proposed by /setup-workflow from the code, confirmed by the developer. -->
## Risk zones

The zone comes from **what the change touches, not who wrote it**. A PR takes the highest zone among its files.

| Zone | Paths / topics | Required before merge |
|---|---|---|
| 🔴 Red | {{RED}} | Invariant tests + agent review + **a person reads the whole diff** |
| 🟡 Yellow | {{YELLOW}} | Agent review + green tests; a person skims |
| 🟢 Green | {{GREEN}} | Agent review |

When unsure about a file: if a bug there could **move, create or lose money or other critical state**, **trust client or partner input**, **leak data or widen access**, or **cannot be undone**, it is red.

Keep a PR to one zone when you can. Split a pure code move (verifiable with `git diff --color-moved=zebra`) from logic changes.

<!-- PROJECT: rules for the red zone of this domain (money, health data, permissions, …). Delete if none. -->
## Domain rules (red zone)

{{DOMAIN_RULES}}

<!-- PROJECT: the team's code conventions; keep generic advice out, the code already shows it. -->
## Code style

{{CODE_STYLE}}

## E2E and test environments

- Use the environment already running on the developer's machine (`/dev-env`). If none is running, ask which one to use; don't start one on your own.
- Never point a test at a production database or URL.
- A shared test database is used by others: use the test accounts file or new `e2e-` accounts, never run migrations on it without asking, and never run destructive SQL.
- Test UIs in a headless browser session (`agent-browser` or the Playwright CLI), never in the developer's open browser.

## Docs upkeep (every change)

1. Add one bullet under `## Unreleased` in `CHANGELOG.md` saying what changed and why.
2. When behaviour, API, config or flow changes, update the README or `docs/` page that describes it{{README_LOCATIONS}}. Edit only the affected sections.

## Don't

- Don't run heavy commands in parallel (full test suite, full builds, Docker builds).
- Don't touch `.env*` values or commit secrets.
- Don't push to the default branch or a protected branch ({{PROTECTED_BRANCHES}}), don't force-push, and don't merge PRs.{{GUARD_NOTE}}
- Don't deploy. People deploy.

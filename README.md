# agent-workflow

A reusable, agent-agnostic workflow for building software with AI coding agents (Claude Code, Codex, Gemini, Grok, Antigravity, Cursor, Copilot). Agents plan, build, test and review; people decide at three checkpoints:

1. **The plan:** the developer approves the spec and the tickets.
2. **The branch:** the developer reads what the review packet flags.
3. **The PR:** the lead reviewer gives the final review.

How much a person reads depends on the **risk zone** of what changed (red, yellow, green), not on who wrote it.

## Install in a project

```bash
npx skills add oscar-sifuentes/agent-workflow
```

Pick the agents you use when the CLI asks. The skills land in `.agents/skills/` (and are linked for each agent). Then, in your agent:

```
/setup-workflow
```

It detects the stack, the commands, your agents and runners, asks the language for documents (English by default), proposes the risk zones from the code, and writes:

- `.agents/project.json`: commands, branches, environments, documents' language, model tiers ([schema](skills/setup-workflow/project-json.md))
- `AGENTS.md`: what the project is, zones, domain rules, code conventions (`CLAUDE.md` imports it)
- `.github/pull_request_template.md`, `.github/workflows/pr-checks.yml` (and `claude-review.yml` if you want the GitHub review)
- `.claude/skills` link, `.gemini/settings.json`, `.gitignore` lines

It also suggests official skills for your stack (see [recommended-skills.md](skills/setup-workflow/recommended-skills.md)). Review the result and commit it yourself.

## Update

```bash
npx skills update
```

Kit skills are never edited inside a project: an update overwrites them. A project's own rules go in `AGENTS.md`, its settings in `.agents/project.json`, and anything else in skills with their own names. When a kit skill needs to change for every project, change it here.

## The flow

| Step | Skill | Output |
|---|---|---|
| Research | `/research` | `docs/research/<topic>.md` |
| Sharpen the plan | `/grill-me`, or `/grill-with-docs` (adds `GLOSSARY.md` and ADRs via `domain-modeling`) | Decisions and invariants |
| Spec | `/to-spec` | `docs/specs/<slug>/spec.md` |
| Tickets | `/to-tickets`, then `render-html` | `docs/specs/<slug>/tickets/`, a readable page in `.review/specs/<slug>/` |
| ✋ 1 | Developer approves | |
| Build | `/deliver <slug>`: one worker per ticket (`implement-ticket`, `tdd`) through Orca, Herdr, the tool's sub-agents or one at a time | `feat/<slug>` |
| Review | `/verify`, `/risk-review`, `/code-review`, `/simplify` when the agent has it | Findings fixed in at most two rounds |
| E2E | `/dev-env`, `/e2e` (API and browser) | `.review/<branch>/e2e-local.md` |
| Packet | `/review-packet`, then `render-html` | `REVIEW.md` and `review.html` |
| ✋ 2 | Developer reviews the branch | |
| PR | `/open-pr` | Draft PR, shared-environment e2e, ready for review |
| ✋ 3 | Lead reviewer | Merge |

Green-zone changes skip the plan: change → `/verify` → `/risk-review` → PR.

## What's inside

- `skills/`: the workflow skills, plus `setup-workflow` with the templates.
- `skills/deliver/scripts/worktree.sh`: worktrees for the orchestrator and its workers.
- `skills/verify/`: `changed.sh` (what changed), `scripts/heavy.sh` (one heavy command at a time per machine), `scripts/ci-checks.sh` (the CI checks, from `project.json`).
- `skills/render-html/`: fixed design and build script for the readable pages.

## Changing the kit

Run `bash scripts/check-kit.sh` before pushing; CI runs it on every push. It checks that every skill parses for the skills CLI, the scripts' syntax and exit codes (in a throwaway repo, under `set -e`), that no project names leak into the kit, and that every template placeholder is documented.

Third-party notices: [THIRD_PARTY.md](THIRD_PARTY.md).

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

### Windows

Claude Code reads skills from `.claude/skills`, which are symlinks to `.agents/skills`. Git on Windows checks symlinks out as small text files unless Developer Mode is on and `core.symlinks` is true, so Claude Code sees no skills. Fix it in the clone:

```bash
node .agents/skills/setup-workflow/scripts/link-skills.mjs
```

It links each skill (symlink, else a junction, which needs no admin, else a copy) and tells git to ignore the local change. Run it again after `npx skills update` if it had to copy.

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
| Spec | `/to-spec`, then `render-html` | `docs/specs/<slug>/spec.md` and a readable page, which the developer reads to approve |
| Tickets | `/to-tickets`, then `render-html` | `docs/specs/<slug>/tickets/` (one repo each), a readable page in `.review/specs/<slug>/` |
| ✋ 1 | Developer approves | |
| Build | `/deliver <slug>`: one worker per ticket (`implement-ticket`, `tdd`) through Orca, Herdr, the tool's sub-agents or one at a time | `feat/<slug>` |
| Review | `/verify`, `/risk-review`, `/code-review`, `/simplify` when the agent has it | Findings fixed in at most two rounds |
| E2E | `/dev-env`, `/e2e` (API and browser) | `.review/<branch>/e2e-local.md` |
| Packet | `/review-packet`, then `render-html` | `REVIEW.md` and `review.html` |
| ✋ 2 | Developer reviews the branch | |
| PR | `/open-pr` | Draft PR, shared-environment e2e, ready for review |
| ✋ 3 | Lead reviewer | Merge |

### Where to start

| The change | Start with |
|---|---|
| New provider, or an external API or library we don't know yet | `/research` → `/grill-me` → `/to-spec` → `/to-tickets` → `/deliver` |
| Internal feature in the red zone (money, auth, data) | `/grill-me` → `/to-spec` → `/to-tickets` → `/deliver` |
| Small internal yellow feature | a short `/grill-me` → `/to-spec` (few tickets, sometimes one) |
| Green: docs, scripts, small tweaks | no plan: change → `/verify` → `/risk-review` → PR |

`/research` only pays off for something external we don't know. For internal changes `/grill-me` reads the code itself, going deep in red and fast in green. A one-off library question during the grill is a Context7 lookup, not a research run; what can't be settled stays in the spec as an external fact, with the value assumed meanwhile.


### Several repos, one delivery

A feature that needs the API and a front stays in **one spec**: each ticket names its `Repo:`. `/deliver` finds each related repo next to this one (by folder or `origin` name), creates `feat/<slug>` there from its default branch, builds its tickets in its own worktrees, and for the e2e starts the API and the fronts **from the integration worktrees** on free ports (`servers.sh`, recipes in `AGENTS.md`), so the browser tests the branch's code. One review packet covers every repo; `/open-pr` opens one linked PR per repo.

## What's inside

- `skills/`: the workflow skills, plus `setup-workflow` with the templates.
- `skills/deliver/scripts/worktree.sh`: worktrees for the orchestrator and its workers, in this repo and related ones (`repo <name>`, `--repo <path>`).
- `skills/deliver/scripts/servers.sh`: starts and stops the apps for the e2e from the integration worktrees, on free ports.
- `skills/verify/`: `changed.sh` (what changed), `scripts/heavy.sh` (one heavy command at a time per machine), `scripts/ci-checks.sh` (the CI checks, from `project.json`).
- `skills/setup-workflow/scripts/link-skills.mjs`: links the skills into `.claude/skills` where symlinks don't work (Windows).
- `skills/render-html/`: fixed design and build script for the readable pages.

## Changing the kit

Run `bash scripts/check-kit.sh` before pushing; CI runs it on every push. It checks that every skill parses for the skills CLI, the scripts' syntax and exit codes (in a throwaway repo, under `set -e`), that no project names leak into the kit, and that every template placeholder is documented.

Third-party notices: [THIRD_PARTY.md](THIRD_PARTY.md).

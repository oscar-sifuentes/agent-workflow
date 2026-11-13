---
name: deliver
argument-hint: '<slug> [agents, e.g. "agy grok" or "red: codex, rest: grok"] [base: <branch>]'
description: Orchestrate the whole build of an approved spec, from the tickets to a branch ready for the developer's review, across every repo its tickets name (related fronts or services, found next to this repo). Detects the runner (Orca, Herdr, or sub-agents), asks which agents build the tickets (default the same agent running this skill), creates one worktree per ticket, starts the workers, answers their questions, reviews each finished ticket and merges it into feat/<slug>, then checks the whole branch, runs the local e2e and writes the review packet. Use when the developer runs /deliver <slug> after approving the tickets.
disable-model-invocation: true
---

# Deliver

You are the **orchestrator**. Take `docs/specs/<slug>/` from approved tickets to a reviewed, tested branch. Workers build the tickets; you assign them, answer their questions, review each result and merge it into `feat/<slug>`, the branch everything starts from and returns to. The developer's next touch point is the review packet. Don't wait for them between tickets unless a stop rule below fires.

Running `/deliver` authorizes local commits on `feat/<slug>` and its ticket branches, and creating and removing the ticket worktrees. It never authorizes a push, a PR, a merge to the default branch or a deploy.

Three things are separate here, so any agent can orchestrate and any agent can build:

- **Agent:** who writes a ticket's code (`claude`, `codex`, `grok`, `agy`/Antigravity, …).
- **Runner:** where workers run (Orca, Herdr, your own sub-agents, or you, one at a time).
- **Contract:** what every worker receives and returns. The same for every agent and runner.

Keep a running log in `.review/feat-<slug>/deliver-log.md`: one line per step, with the result.

## Run unattended

After the one question at the start (section 1), **finish the delivery on your own**. The developer may be away; a question or a permission prompt that nobody answers stalls everything.

- **Decide, log, continue.** Anything in "Decide on your own" below: pick the option you would recommend, write it in the log as `DECISION: <what> because <why>`, list it in the review packet, and keep going. The developer reviews your decisions in the packet, not live.
- **Ask only for a stop rule** (end of this skill). Those are the cases where a wrong guess can move money, widen access, leak data, add a dependency or migration, or where nothing you can do unblocks the work.
- **Never trigger a permission prompt you can avoid.** Use `.agents/skills/deliver/scripts/worktree.sh` for every worktree and `node_modules` link (never hand-written `rm`/`ln` with shell variables, which safety checks block), `unlink` for symlinks, literal absolute paths, and one command per purpose. Don't pipe into interpreters (`python3 -`, `node -e`) when a plain command or a file edit does the job.

## 0. Check the start

- `docs/specs/<slug>/spec.md` exists with status `approved`, and `tickets/` has at least one `ready` ticket. If not, stop and say which step is missing (`/to-spec`, `/to-tickets`).
- The working tree is clean.
- The **base** is the branch the developer names; **with no answer, the branch you are on now** (`git branch --show-current`). If you are on the default branch or a protected one (`defaultBranch`, `protectedBranches` in `.agents/project.json`), use `origin/<defaultBranch>` (fetch first) instead of the local branch.
- Create (or reuse) the integration branch and its worktree, with dependencies installed once: `bash .agents/skills/deliver/scripts/worktree.sh integration <slug> <base>`. It prints the integration worktree path; **work from there for the rest of the delivery** (log, briefs, merges). Never work on the default branch.
- The base must contain `.agents/` and `AGENTS.md`, or the workers won't find their instructions. If it doesn't, stop and say so.
- **Related repos.** Read the `Repo:` line of every ticket (none means this repo). A ticket without the line that clearly belongs to another repo (its title or notes name another app, or files that aren't here) takes that repo: log it as a DECISION. For each other repo:
  1. Find it: `bash .agents/skills/deliver/scripts/worktree.sh repo <name>` (a sibling folder whose name or `origin` is `<name>`). If it isn't found, that is one more thing to ask in section 1; with no answer, skip that repo's tickets and say so in the hand-over.
  2. Its base is its default branch, fresh: `git -C <repo> fetch origin`, then `origin/<default>` (`git -C <repo> symbolic-ref --short refs/remotes/origin/HEAD`). Never the branch the developer has checked out there, and never touch that checkout.
  3. Create its integration worktree: `bash .agents/skills/deliver/scripts/worktree.sh --repo <repo path> integration <slug> origin/<default>`. It prints `<repo parent>/<repo>--<slug>` on `feat/<slug>`, installs it, and links its untracked `.env*` files from the main checkout, so a server can start there.
  4. Log `REPO <name>: <repo path> → <integration worktree>`.
  A related repo doesn't need `.agents/` or `AGENTS.md`: its workers read the skills from this repo by absolute path.

## 1. Detect the runner, ask for the agents

**Runner.** Default: where you are running.

| You are in | Detected by | Default runner |
|---|---|---|
| Orca | `ORCA_TERMINAL_HANDLE` is set and `orca` is on the PATH | Orca |
| Herdr | `HC_TERMINAL_ID` is set and `hc` is on the PATH | Herdr (`hc`) |
| Neither | | your own sub-agents if your tool has them, otherwise one at a time |

A Herdr runner needs you inside a Herdr terminal (`HC_TERMINAL_ID`), so workers can report to you. Don't mix runners in one delivery.

**Agents.** If the developer already gave the agents (and optionally the base or runner) in the command arguments (`/deliver <slug> agy grok`, `/deliver <slug> base: main, red: codex, rest: grok`) or said them right before running it, use that and **don't ask**: show the assignment and start. Otherwise ask once, showing the detected runner:

> Base: **<current branch>**. Runner: **<detected>**. Which agents should build the N tickets? Press enter for **<your own agent>** (the agent running this orchestrator) and this base.
> Options: `<your own agent>`, `claude`, `codex`, `grok`, `agy`, or a mix such as `red: codex, rest: grok,agy` (round-robin within each group). Add a model with `agent:model` (otherwise the tiers in `.agents/project.json` decide). You can also change the base or the runner.

- **No answer: every worker is your own agent.** Nothing defaults to a particular vendor.
- Sub-agents can only be your own agent. If the developer picks another agent and the runner is sub-agents or none, use your own agent and log it as a decision.
- Write the assignment (ticket → agent) and the runner in the log, show it, and start right away; this is the only question of the run.
- **Fold into that same question, only when they apply:** a related repo that wasn't found (its path), and, when a ticket adds a migration, "may I run it on the **local** database for the e2e?" (no answer: no; the e2e of what needs it stays pending).

Reviews, merges, the e2e and the review packet stay with you, whatever agents build the tickets.

## 2. The worker contract

For each ticket you start:

1. **Worktree.** From the integration worktree **of the ticket's repo**, for every runner: `bash <this repo's integration worktree>/.agents/skills/deliver/scripts/worktree.sh add NN` (in this repo, `bash .agents/skills/deliver/scripts/worktree.sh add NN`). It creates `feat/<slug>--NN` from the tip of `feat/<slug>` in `<integration worktree>--NN`, links `node_modules` from the integration worktree, prints the path, and reuses the worktree when you retry the same ticket. A ticket that changes `package.json` or `yarn.lock` replaces the link with its own install, through `heavy.sh`.
2. **Brief.** Write `.review/feat-<slug>/workers/NN-brief.md` from the template below, then pass its absolute path (or its text, when the runner needs it inline).
3. **Report file.** The worker writes `<worktree>/.review/worker-report.md` (inside its own worktree, so sandboxed agents can write it; `.review/` is git-ignored) ending in `RESULT: done | failed | question`. **That file is the source of truth**; the runner's signal only wakes you.

### Brief template

```text
You are the worker for ticket docs/specs/<slug>/tickets/NN-<title>.md.
Read AGENTS.md, then follow .agents/skills/implement-ticket/SKILL.md exactly.
Spec: docs/specs/<slug>/spec.md. Integration branch: feat/<slug>. Your branch: feat/<slug>--NN.
Your worktree (stay in it): <absolute worktree path>.
Report file: <absolute worktree path>/.review/worker-report.md.
Runner: <Orca | Herdr | sub-agent>. Orchestrator: <Herdr: your HC_TERMINAL_ID; Orca: your coordinator, Orca routes it>.
Repo: <this repo | related repo name>. Skills, spec and ticket: <absolute path of this repo's integration worktree>/ (read .agents/skills/implement-ticket/SKILL.md from there when you are in another repo).
Run tests, tsc and Docker through <absolute path>/.agents/skills/verify/scripts/heavy.sh. Never push, open a PR, merge into feat/<slug>, start other agents or touch another ticket.
Ask before guessing on money, auth, access or data exposure. When done, write the report file and signal as the skill says.
```

## 3. Runner commands

| Step | Orca | Herdr (`hc`) | Your sub-agents |
|---|---|---|---|
| Setup | `orca orchestration run-create --objective "deliver <slug>"`; one `task-create --spec-file <brief> --task-title "<slug> NN" --deps '[<blocker task ids>]'` per ticket | none | none |
| Start | `orca orchestration worker-start --task <id> --worktree path:<worktree> --agent <agent> [--model <m>] [--effort <e>] --json`. On an existing worktree Orca rejects `--setup`, `--name` and `--display-name`; put the label in `task-create --display-name` instead. Antigravity's Orca id is `antigravity` | `hc run --bg --name <slug>-NN --cwd <worktree> <agent command> "<brief text>"` | spawn one per ticket in its worktree (Claude Code: the `ticket-implementer` agent) |
| Wait | `orca orchestration check --wait --types worker_done,question,escalation --timeout-ms 600000 --json` | `hc wait --children any` (a timeout is a check-in: wait again) | the tool returns the result |
| Read | the report file; `orca orchestration worker-read --dispatch <id>` for context | the report file; `hc read --lines 100 <slug>-NN` for context | the report file |
| Answer / send fixes | `orca orchestration reply --id <msg>`; `orca orchestration send --to dispatch:<id> --type dispatch --subject ... --body ...` | `hc send <slug>-NN "<answer or findings>"` | the tool's message to the sub-agent (Claude Code: SendMessage) |
| Retry | `worker-start --task <id> --retry-of <dispatch_id> --worktree path:<same worktree> --agent <agent>`; it resends the original brief, so send the "continue from the previous worker's work" note right after as `send --to dispatch:<new id> --type dispatch` | kill the old terminal, `hc run` again in the same worktree with the brief plus that note | spawn again with the brief plus that note |
| Stop / clean up | `orca orchestration worker-stop --dispatch <id>` (still running) or `worker-release --dispatch <id>` (finished), then `bash .agents/skills/deliver/scripts/worktree.sh remove NN` | `hc kill <slug>-NN; hc rm <slug>-NN`, then `worktree.sh remove NN` | `worktree.sh remove NN` |
| Wait in the background | run the Wait command as a background task when your tool has them, so you can review one worker while the others build | | |

Agent commands for Herdr: `claude`, `codex --no-daemon` (required, or its commands run outside hc), `grok`, `agy`, plus `--model`/`-m` as each CLI takes it. If an agent doesn't take the first task as an argument, start it without one, `hc wait` until it is ready, then `hc send` the brief. Check `first_message.sent` in the launch result; if false, `hc read` before resending.

Don't trust an agent's idle status or screen text as "finished": finished means a report file with a `RESULT` line and, for `done`, a commit on its branch.

## 4. Effort and model

Set the reasoning effort **and** the model tier of every worker and reviewer you start; don't leave them to the agent's defaults. Your own model and effort can't change mid-session; you only choose for what you delegate, and that can be cheaper or stronger than you.

**Base, by role and the ticket's zone** (effort / model tier):

| Role | 🟢 Green | 🟡 Yellow | 🔴 Red |
|---|---|---|---|
| Worker (`implement-ticket`) | low / fast | medium / standard | high / deep |
| `risk-review` | low / fast | medium / standard | xhigh / deep |
| `code-review`, Standards and Spec axes | low / fast | medium / standard | high / deep |
| `code-review`, Docs axis | low / fast | low / fast | medium / standard |
| `e2e`, `review-packet` | low / fast | medium / standard | medium / standard |

Mechanical work (README, CHANGELOG, pure moves, renames) is low / fast whatever the zone. For checks on the whole branch, use the branch's highest zone.

**Tier → model** comes from `models` in `.agents/project.json`, overridden key by key by `models` in `.agents/project.local.json` (git-ignored) when it exists. An empty value means: pass no model and let the agent use its default. If the developer gave a model in the agent list (`codex:<model>`), it wins for that agent's workers.

**Your own session.** At the start, recommend once, and carry on with whatever the developer decides:
- red spec and your effort below high: "I recommend `/effort high` for the orchestrator."
- you run on the deep tier: "Orchestrating is mostly coordination; the standard tier is enough for me (`/model <standard model>`). Red reviews still go to the deep tier."

**Escalate** the next attempt on the same ticket, one step at a time, in this order:
1. **effort +1** (low → medium → high → xhigh), when `verify` fails twice in a row on the same thing, a `blocker` or `major` finding survives the first fix round, or a worker reports `RESULT: failed` or is stuck
2. **model tier +1** (fast → standard → deep), same agent, when the effort step didn't help
3. **another agent** from the developer's list, in the same worktree
Merge conflicts you couldn't resolve go to a worker at least at high / deep.

**Limits:** effort never above `xhigh` on your own (`max` only when the developer asks) and at most two levels above the base; model never above deep. When the ladder is used up, it is a stop rule. Write every change in the log (`03: high/standard → xhigh/standard, verify failed twice`) and list them in the review packet.

**How to pass them:**

| Agent / runner | Effort | Model |
|---|---|---|
| Claude Code sub-agent | the `effort` of the agent call | the `model` of the agent call (`haiku`, `sonnet`, `opus`) |
| `claude` CLI (Herdr) | `--effort <level>` (low … max) | `--model <model>` |
| `codex` CLI (Herdr) | `-c model_reasoning_effort=<level>` (minimal … xhigh) | `-m <model>` |
| `grok` CLI (Herdr) | `--reasoning-effort <level>` | `-m <model>` |
| `agy` CLI (Herdr) | `--effort <level>` (low … max) | `--model <model>` |
| Orca | `worker-start --effort <level>` | `worker-start --model <id>`; Orca takes `--effort` only with `--model`, so with no mapped model, start without either |

If an agent rejects a level or a model, use the nearest one it accepts, or none (Orca rejects every `--effort` for Claude `haiku`), and log it. Never stop for this.

## 5. Build the tickets

Work the **frontier**: the tickets whose blockers are all `done`, whatever their repo. Tickets in different repos never conflict, so they can build at the same time within the limits below.

- **Red tickets run one at a time.** Yellow and green tickets run at most three workers at once, so the machine stays usable.
- Heavy commands (tests, tsc, Docker) go through `.agents/skills/verify/scripts/heavy.sh`, so parallel workers never run two at once.

When a worker signals, read its report file:

- **`RESULT: question`**: answer it yourself from the spec, the code and `AGENTS.md`, choosing what you would recommend, and log it as a decision. Only a question on money, auth, access or data exposure that the spec doesn't answer is a stop rule.
- **`RESULT: failed`**: send what to fix, or retry (below).
- **The agent can't go on** (usage or rate limit, login expired, crashed, stuck on a prompt only a person can answer such as an upgrade, payment or login screen): don't answer that screen and don't ask the developer. Stop that worker and **retry the ticket with the next agent from the developer's list, then with your own agent**, in the same worktree, with the "continue from the previous worker's work" note. Log it.
- **`RESULT: done`**:
  1. Check: the commit in the report is the tip of `feat/<slug>--NN`, the worker touched only its worktree, and nothing was pushed (`git ls-remote origin feat/<slug>--NN` is empty).
  2. Run the `risk-review` skill on the ticket branch against `feat/<slug>` **of its repo** (in another repo, run its git commands with `git -C <that integration worktree>`; its conventions come from that repo's `AGENTS.md` or README, the domain and security rules from this one). For a red ticket, also the `code-review` skill.
  3. On a `blocker` or `major` finding, send the findings to the same worker. Escalate as section 4 says: effort, then model tier, then **another agent from the developer's list in the same worktree**, so it continues from the existing work. After that, stop and ask.
  4. **Merge the ticket branch into `feat/<slug>` of its repo** (in that repo's integration worktree) with `--no-ff`. You do every merge, one at a time, and **resolve conflicts yourself**: the tickets come from the same spec, so keep both sides' intent (for example, both CHANGELOG bullets). Only a conflict inside red-zone logic whose right result you can't tell goes back to the worker that built the ticket, at least high / deep. Mark the ticket `done`.
  5. Copy its report to `.review/feat-<slug>/workers/NN-report.md`, clean up the worker and its worktree (runner table), and start the tickets this merge unblocked.

## 6. Check the whole branch

On `feat/<slug>` against the base (so only this delivery's changes are reviewed), **in every repo of the delivery**. In a related repo without `.agents/`, "verify" means its own lint, typecheck and tests on the changed files, through this repo's `heavy.sh`:

0. **Only when a `simplify` skill is available to you:** check your own list of skills or slash commands for `simplify` (Claude Code bundles it, unless `disableBundledSkills` is on). If it isn't there (another agent, an older version, bundled skills off), skip this step without asking or installing anything, and log `simplify: not available`. If it is, run it on the delivery's diff against the base. Workers on different agents repeat helpers and drift in style; this cleans that up before anyone reviews it. It edits code, so:
   - keep only cleanups that don't change behaviour; revert any edit to a test that proves a spec invariant, and any change to an amount, a guard, a transaction or an idempotency key;
   - commit what's left on its own (`refactor(<area>): simplify <slug>`), so the reviewer can tell it apart from the tickets;
   - log it as a `DECISION` with a one-line summary.
   When it's skipped, the Standards axis of `code-review` covers part of it.
1. the `verify` skill
2. the `risk-review` skill, on the whole diff
3. the `code-review` skill, when any ticket is red

Fix through a worker (the agent that built that ticket, or another): create a fix worktree with `worktree.sh add NNb` and brief exactly what to change. The same limit of 2 rounds applies. When the fix is small and the zone is green, the whole-branch `verify` after the merge is its review.

Then **consolidate the open questions**: copy every open question from the worker reports into the spec's "Open questions" section (one line each, with the file and behaviour), and commit it on `feat/<slug>`.

## 7. E2E, locally

Skip this step only when the spec's "E2E scenarios" section says it is not applicable (no runtime behaviour changes); say so in the log and the packet.

The e2e must run **the delivery's code**, so start the apps yourself from the integration worktrees, without asking:

1. Run the `dev-env` skill only to check the **infrastructure** the apps need (database, cache, queues). If it is down, don't start it: finish everything else, mark the e2e as pending, and ask about it in the hand-over.
2. Start each app the scenarios need with `.agents/skills/deliver/scripts/servers.sh`, from its integration worktree, on a free port (`servers.sh free-port <from>`), as "Run from a worktree" in `AGENTS.md` says. Point each front at the API you started, not at the developer's. An app not listed there: derive the command from its `package.json` (`dev` script) and README, log it as a DECISION, and propose the entry for `AGENTS.md` in the hand-over.
3. A migration of this delivery runs on the local database only if the developer said yes in section 1; otherwise the scenarios that need it are pending. Never a container build, never a shared or remote database.
4. Run the `e2e` skill against those URLs. A failing scenario goes back to a worker for the ticket it belongs to; restart that app, then run the e2e again.
5. `bash .agents/skills/deliver/scripts/servers.sh stop` when the e2e is done, even when it failed.

## 8. Hand over

1. Run the `review-packet` skill: **one packet for the whole delivery**, with a section per repo (branch, files, zone). List the runner, which agent and model built each ticket, every effort or model change, and every `DECISION` from the log.
2. Make sure no worker or app is left running (`bash .agents/skills/deliver/scripts/servers.sh status`) and no ticket worktree is left over (`git worktree list`, and `git -C <repo> worktree list` for each related repo). Keep the integration worktree: the developer reviews there, and `/open-pr` closes it once the PR is open.
3. Tell the developer it is ready for their review: the branch in each repo with its integration worktree path, the review page (`.review/<branch>/review.html`) and the packet path, and one line each for the zone, the tests, the e2e result, the decisions you made and any open question. Send a push notification if the tool has one.

## Decide on your own (log it as a DECISION)

- which agent continues a ticket when one can't go on (next in the developer's list, then yours)
- effort and model changes, and dropping a level an agent rejects
- answers to worker questions the spec, the code or `AGENTS.md` answer, including test conventions and tooling choices inside the spec's zone that add no dependency
- merge conflicts between tickets of this delivery
- fixing review findings through a worker, up to the limits
- a minor finding: fix it if cheap, otherwise record it in the packet
- skipping a step the spec marks as not applicable

## Stop and ask the developer only when

- the spec doesn't answer a question on money, auth, access or data exposure
- a ticket needs a new dependency, a migration not in the spec, or a change outside the spec
- a worker pushed, touched another ticket's files, or worked outside its worktree
- every agent in the list, and your own, failed the same ticket (the escalation ladder is used up)
- a test can't pass without changing what the spec says

Batch what you can: finish all the work the question doesn't block first, then ask once, with your recommended answer, and wait. Everything else goes in the hand-over message and the packet.

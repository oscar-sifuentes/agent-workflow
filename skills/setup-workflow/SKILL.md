---
name: setup-workflow
description: Configure a repo for the agent-workflow kit after `npx skills add`. Detects the stack, commands, installed agents and runners; asks the documents' language; proposes risk zones from the code for the developer to confirm; writes .agents/project.json, AGENTS.md, CLAUDE.md, the PR template, CI and the per-tool links; recommends official stack skills. Re-run it to refresh or repair a setup. Use when the developer asks to set up, install or configure the workflow in a project.
disable-model-invocation: true
---

# Setup workflow

Turn a repo that has the kit's skills in `.agents/skills/` into a configured project. Ask few questions: detect what you can, propose, and let the developer correct. Templates are in `templates/` next to this file.

**Never overwrite without asking.** For each file that exists, show what you would add or change and ask once. In an existing `AGENTS.md`, only add missing sections; never rewrite a section the project already has.

## 1. Detect

Read, don't ask:

- **Stack and package manager:** `package.json` (and the lockfile: `yarn.lock`, `pnpm-lock.yaml`, `bun.lock*`, `package-lock.json`), `pyproject.toml`, `go.mod`, `Cargo.toml`. Frameworks from the dependencies (Next.js, React, NestJS, Express, Django, FastAPI, …).
- **Commands:** `package.json` scripts and tool configs (prettier, eslint, `tsconfig.json`, jest/vitest config, ruff, pytest). Build the `commands` block of `project.json`: `install`, `format`, `formatCheck`, `lint`, `typecheck`, `test`, with `{files}` where a command takes a file list, and one test worker (`-w 1`, `--maxWorkers=1`, no `-n`).
- **Branches:** the remote's default branch (`git symbolic-ref refs/remotes/origin/HEAD`); deploy branches from `.github/workflows/*` triggers (`on.push.branches`) and branch names like `production`, `staging`, `sandbox`, `release/*`.
- **Local environment:** dev ports in `package.json` scripts, `.env.example`, compose files (`docker-compose*.yml`, `compose*.yml`), and run docs (`README`, `HOW_TO_RUN*`, `CONTRIBUTING`).
- **Agents installed:** `command -v claude codex gemini grok agy cursor-agent copilot`. **Runners:** `command -v orca hc`.
- **What exists already:** `AGENTS.md`, `CLAUDE.md`, `.agents/project.json`, `.github/pull_request_template.md`, `.github/workflows/`, `.claude/skills`, `.gemini/settings.json`, `CHANGELOG.md`, `docs/`.

Show the developer a short summary of what you found.

## 2. Ask

Ask these together, in one message, each with a recommended answer:

1. **Language of the documents people read** (specs, tickets, review packets, HTML pages). Default: English. Agent instructions stay in English.
2. **Protected branches:** confirm the list you detected.
3. **Shared test environment** (staging, sandbox, preview), if any: its name, URLs, and how a branch gets deployed there. "None" is a valid answer.
4. **Stack skills:** the matching rows of `recommended-skills.md`, to install or skip.

## 3. Propose the zones

Read the code and propose the three zones as paths and topics:

- **Red:** payments, balances, billing, money-like names (`wallet`, `balance`, `ledger`, `payout`, `refund`, `transaction`); auth, sessions, permissions, roles; inbound webhooks and their signature checks; anything that exposes personal data in responses; migrations; app bootstrap and security config (CORS, headers).
- **Yellow:** the rest of the business logic.
- **Green:** docs, READMEs, CHANGELOG, scripts, local-dev tooling, tests that only pin behaviour.

Show the table and ask for corrections in one question. Then ask whether the project has **domain rules** for the red zone (for example money rules) and **team code conventions** the agents must follow. Write what the developer gives; if they have none yet, leave the sections with a one-line placeholder that says so. Don't invent rules.

## 4. Write

1. `.agents/project.json` from `templates/project.json` (see `project-json.md` for every key), filled from sections 1 and 2. Keep the `models` block; leave non-Claude tiers empty unless the developer names models.
2. `AGENTS.md` from `templates/AGENTS.md`. Fill every placeholder, then check that no `{{` is left, and remove the `<!-- PROJECT … -->` comments:

   | Placeholder | Fill with |
   |---|---|
   | `{{WHAT_THIS_IS}}` | 3–6 lines: what the product does, the stack, where the main code lives, which docs to read first |
   | `{{COMMANDS}}` | The commands a person types (dev server, lint, tests, migrations), one per line with a short comment |
   | `{{RED}}`, `{{YELLOW}}`, `{{GREEN}}` | The confirmed zones from section 3, as paths and topics |
   | `{{DOMAIN_RULES}}` | The developer's red-zone rules, or "Not defined yet." with one line on what they would cover |
   | `{{CODE_STYLE}}` | The team's conventions, or "Not defined yet." plus "follow how the touched module is written" |
   | `{{PROTECTED_BRANCHES}}` | The confirmed protected branches, in backticks |
   | `{{README_LOCATIONS}}` | Where module READMEs live, for example ": `src/modules/<feature>/README.md`", or empty |
   | `{{GUARD_NOTE}}` | " A hook blocks these in Claude Code." when the project has one, or empty | If `AGENTS.md` exists, merge section by section as above.
3. `CLAUDE.md` from `templates/CLAUDE.md` when Claude Code is installed or the file exists. If it exists without `@AGENTS.md`, add that line at the top.
4. `.github/pull_request_template.md` from the template.
5. `.github/workflows/pr-checks.yml`: fill `{{DEFAULT_BRANCH}}`, `{{INSTALL_COMMAND}}` and `{{SETUP_STEPS}}` (from `templates/workflows/setup-steps.md` for the stack). `.github/workflows/claude-review.yml` only if the developer wants the GitHub review; tell them it needs the Claude GitHub App and the `ANTHROPIC_API_KEY` secret, and optionally `CONTEXT7_API_KEY`.
6. Claude Code sub-agents, when Claude Code is installed: copy `templates/claude-agents/*.md` to `.claude/agents/` (`html-renderer` runs `render-html` on Sonnet; `risk-reviewer` and `ticket-implementer` wrap their skills).
7. Per-tool links: `npx skills add` already links each skill into the folders of the agents chosen at install (for Claude Code, `.claude/skills/<name>`). If Claude Code is installed and `.claude/skills` is missing, run `npx skills add` again for it rather than linking by hand. On Windows, or whenever an agent doesn't see the skills, run `node .agents/skills/setup-workflow/scripts/link-skills.mjs` (symlink, else junction, else copy). Write `.gemini/settings.json` from `templates/gemini-settings.json` when Gemini is installed, so it reads `AGENTS.md`.
8. Append the lines of `templates/gitignore.txt` to `.gitignore` when missing.
9. `CHANGELOG.md` with an `## Unreleased` section if there is none, and one bullet for this setup.
10. Create `docs/specs/` with a short `README.md` (specs and tickets live here) if missing.

Install the stack skills the developer accepted with `npx skills add <owner/repo> --skill <name>`.

## 5. Check and report

- Run `bash .agents/skills/verify/changed.sh` and the `formatCheck` command on one changed file, to prove the commands work. Fix the config if one fails.
- Report: the files written or changed, the zones, the commands, the agents and runners found, the stack skills installed, and what the developer still has to do (GitHub secrets, branch protection, filling the test-accounts file).
- Don't commit. The developer reviews the setup like any other change.

## Updates

`npx skills update` refreshes the kit's skills. Re-run `/setup-workflow` afterwards only when the kit's release notes say a template changed; it adds what is missing and asks before changing anything.

---
name: code-review
description: "Review the changes since a fixed point (commit, branch or merge-base) along three axes: Standards (does the code follow AGENTS.md and the repo's documented conventions?), Spec (does it do what docs/specs/<slug>/spec.md and its tickets ask, no more and no less?) and Docs (do the external library APIs it uses match the official docs for the installed versions, checked with Context7?). Runs the axes in parallel sub-agents and reports them side by side. Use for red-zone work after risk-review, or when asked to review a branch or a change against its spec or the library docs."
---

# Code review

Three separate reviews of `git diff <base>...HEAD`. Risk (money, auth, exposure) is the `risk-review` skill's job; this skill checks conventions, the spec and the library docs.

## 1. Pin the base

Use the ref the caller gives (default `origin/<defaultBranch>` from `.agents/project.json`, or the remote's default branch). Check that it resolves and that the diff is not empty before spawning anything. Capture the diff command and `git log <base>..HEAD --oneline`.

## 2. Find the spec

In order: a path the caller passed; `docs/specs/<slug>/` named in commit messages or matching the branch name; ask the developer. With no spec, skip the Spec axis and say so.

## 3. Find the standards

`AGENTS.md`, the README of each touched module, `docs/` pages on the touched area, and the existing code of the touched module (it shows the house style). A documented repo rule always overrides a generic one.

Also check these smells as judgement calls, never hard violations: mysterious names, duplicated logic, feature envy, data clumps, primitive obsession, repeated switches, shotgun surgery, speculative generality, middle man (thin wrappers that only rename a call are banned outright by `AGENTS.md`).

## 4. Find the library APIs the diff touches

List the external packages whose APIs the added or changed lines call or configure: new imports, decorators, query builder methods, validator rules, client options, config keys. Ignore this repo's own code (its path aliases, relative imports) and pure type imports. Take each package's version from the project's manifest (`package.json`, `pyproject.toml`, `go.mod`, …).

Keep the list to the **five packages most involved in red-zone or behaviour-changing lines**. With no external API touched, skip the Docs axis and say so.

## 5. Spawn the sub-agents in parallel

**Standards sub-agent.** Give it the diff command, the commit list and the standards files. Brief: "Report each place the diff breaks a documented rule (cite the file and rule) and each smell you see (name it, quote the hunk). Separate hard violations from judgement calls. Skip what lint enforces. Under 400 words."

**Spec sub-agent.** Give it the diff command, the commit list and the spec and ticket paths. Brief: "Report (a) requirements or invariants missing or partial, (b) behaviour not asked for, (c) requirements that look implemented but wrong, and (d) invariants with no test. Quote the spec line for each. Under 400 words."

**Docs sub-agent.** Give it the diff command, the package list with versions, and the "Docs checked" table of the spec if there is one. Brief: "For each package, use the Context7 CLI as AGENTS.md describes (`npx ctx7@latest library`, then `docs` with the version), at most 3 commands per package. Compare how the diff uses the API with the docs for that version. Report: deprecated or removed APIs, wrong or missing options, defaults that change behaviour (timeouts, transactions, validation, serialization), and usage the docs warn against. Quote the hunk and cite the doc (library id and what it says). If Context7 fails (quota, login), stop and report that instead of answering from memory. Under 400 words."

## 6. Report

Show the reports under `## Standards`, `## Spec` and `## Docs`, without merging or reranking them. End with one line: findings per axis and the worst one in each.

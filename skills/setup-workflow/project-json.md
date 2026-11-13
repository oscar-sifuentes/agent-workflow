# `.agents/project.json`

What the kit's skills and scripts read mechanically. Prose rules (zones, domain rules, conventions) go in `AGENTS.md`, not here. A developer's own overrides go in `.agents/project.local.json` (git-ignored), merged key by key.

| Key | Used by | Meaning |
|---|---|---|
| `docsLanguage` | to-spec, to-tickets, review-packet, research, render-html | Language of documents people read (`en`, `es`, …). Agent instructions stay in English. |
| `defaultBranch` | deliver, code-review, review-packet, open-pr, CI | The branch PRs target. |
| `protectedBranches` | deliver, open-pr, `AGENTS.md` | Branches agents never push to or merge into (default branch, deploy branches). |
| `commands.install` | `worktree.sh integration` | Installs dependencies once in a new integration worktree. Empty to skip. |
| `commands.format`, `formatCheck`, `lint`, `typecheck`, `test` | verify, tdd, implement-ticket, CI | `{files}` is replaced by the space-separated file list. `typecheck` runs on the whole project; its output is filtered to the changed files. `test` must run one worker. |
| `paths.*` | planning skills, e2e, dev-env | Where specs, research notes, ADRs, the glossary and the test-accounts file live. |
| `environments.local` | dev-env | Services to probe (`name`, `url`, `health`), and how the developer starts the local stack (`start`, `startDir`, `docs`). |
| `environments.shared` | e2e, open-pr | Shared test environments (`name`, `urls`, `deploy` note). Empty list: no shared-environment e2e. |
| `models` | deliver, render-html | Model per tier (`fast`, `standard`, `deep`) for each agent. Empty: the agent's default. |

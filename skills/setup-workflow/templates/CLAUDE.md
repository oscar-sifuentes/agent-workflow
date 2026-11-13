@AGENTS.md

## Claude Code specifics

- Flow: `/grill-me` → `/to-spec` → `/to-tickets` → (developer approves) → `/deliver <slug>` → (developer reviews the review page) → `/open-pr`.
- Green-zone changes: implement → `/verify` → `/risk-review` → PR.
- Work on feature branches in a worktree, never on the default branch.
- When you get something wrong and a rule would have prevented it, propose the rule for `AGENTS.md` instead of only fixing the code.

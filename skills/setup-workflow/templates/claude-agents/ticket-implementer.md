---
name: ticket-implementer
description: Builds one ticket from docs/specs/<slug>/tickets/ test-first in the worktree the /deliver orchestrator created for it, verifies it, commits locally, writes the worker report file and returns. The sub-agent runner of /deliver when the orchestrator is Claude Code and every worker is Claude; never pushes, merges or opens a PR.
---

Follow `.agents/skills/implement-ticket/SKILL.md` exactly (also available as the `implement-ticket` skill). Your brief gives you the ticket, the branches, your worktree, the report file path and the runner (`sub-agent`). Work only inside that worktree (`cd` into it first). Your final message is the report file path and its `RESULT` line.

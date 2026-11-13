---
name: open-pr
description: Open the pull request for a branch the developer has already reviewed. Pushes the branch, opens a draft PR to the default branch with the review packet as its description, and walks the test-environment deploy, its e2e and the switch to ready for review. Use when the developer says the branch is reviewed and asks to open the PR.
disable-model-invocation: true
---

# Open PR

Running `/open-pr` authorizes pushing this branch and opening a draft PR. It never authorizes a merge, or a push to the default branch or any branch in `protectedBranches` (`.agents/project.json`).

## 1. Check

- The developer has reviewed the branch (they ran this command for that reason). If `REVIEW.md` is missing or older than the last commit, run the `review-packet` skill first.
- The `verify` skill passes on the branch. Run it if the branch changed since the last run.
- The working tree is clean.

## 2. Push and open as draft

```bash
git push -u origin <branch>
gh pr create --draft --base <defaultBranch> --title "<type>(<area>): <spec title>" --body-file <body>
```

The body is `.github/pull_request_template.md` filled in from `.review/<branch>/REVIEW.md`: the zone, the "Must read" list, the invariants table, the decisions, the e2e results and the deploy notes. Add the attribution line the session uses at the end.

## 3. Shared test environment

The PR's checks run while it is a draft. Then, with the developer:

Skip this section when `environments.shared` in `.agents/project.json` is empty, and say so in the PR.

1. Deploy the branch to the shared environment as its `deploy` note says, or ask the developer how. A person usually deploys; never deploy to production.
2. Call the `e2e` skill with `--target <environment name>`.
3. Update the PR's E2E section with the result (`gh pr edit --body-file`).

## 4. Ready for review

When the checks pass and the shared-environment e2e passes (or was skipped), regenerate the review page with its result (the `render-html` skill, `review <branch>` mode).

For the lead reviewer, the PR description stays the source (GitHub renders it). If the agent can publish a page (a claude.ai artifact from Claude Code), offer to publish `review.html` as a private page and add its link at the top of the PR description; the developer shares it with the lead. Otherwise the developer can send the file. Never publish without the developer's yes: the page describes unreleased code.

Then mark it ready: `gh pr ready`. That starts the Claude review on GitHub, which posts the reviewer summary and the 👀 inline comments. Then the lead reviewer (CODEOWNERS) does the final review.

## 5. Close the integration worktree

Once the PR is ready for review, the local worktree has done its job: the branch lives on in the PR. From another worktree (the base's, for example), run:

```bash
bash .agents/skills/deliver/scripts/worktree.sh close <slug>
```

It removes `<parent>/<slug>` and any ticket worktree left over, and keeps `feat/<slug>`. To review or fix the PR later, check the branch out again (`git worktree add <path> feat/<slug>`). Copy `.review/feat-<slug>/` somewhere first if you want to keep the local evidence; it is git-ignored and goes with the worktree.

If the developer drops the delivery instead of opening a PR, use `close <slug> --discard`, which also deletes `feat/<slug>` and its ticket branches. Only on their word.

Report the PR URL and what is still pending.

---
name: dev-env
description: Find the local test environment before an end-to-end test. Probes the services listed in .agents/project.json (APIs, fronts, local stack) and uses whatever is already running; if nothing is up, asks the developer which environment to use. Use before /e2e, or when asked to check, find or start the local environment.
---

# Dev env

Find a running environment and use it. Don't invent one, and don't start anything the developer did not choose.

## 1. Detect what is running

Read `environments.local` in `.agents/project.json`:

```json
"local": {
  "services": [{ "name": "api", "url": "http://localhost:3000", "health": "/health" }],
  "start": "docker compose up -d",
  "startDir": "local-dev",
  "docs": "HOW_TO_RUN.md"
}
```

Probe each service, one call each, with a short timeout:

```bash
curl -s -m 5 -o /dev/null -w '%{http_code}\n' <url><health>
```

If `startDir` has a compose file, also check it: `(cd <startDir> && docker compose ps --format '{{.Name}} {{.State}}')`.

If `project.json` lists no services, look for them: the ports in `package.json` scripts, `.env.example`, compose files and the README. Report what you found and suggest adding it to `project.json`.

## 2. Decide

- **Something answers.** Use it. Report which services are up and whether the local stack is the one serving them.
- **Nothing answers, or the service the change needs is down.** Ask the developer once. Offer:
  1. "Start the local stack" (the `start` command in `startDir`, see `docs`)
  2. "I'll start it myself", then wait and probe again
  3. "Skip the e2e for now"

  Never start anything without that answer. Starting a stack is a heavy command: run it alone, never next to tests or builds.

## 3. Find out which database it writes to

Ask the developer once per session if you can't tell whether the running app writes to a local database or to a shared one (the shared environments are under `environments.shared` in `project.json`). If anything suggests a production database, stop and say so. Never run tests against production.

## 4. Rules for a shared database

A shared test database is a test environment, so tests may write to it, but other people use it too:

- Use the test accounts in the file named by `paths.testAccounts` in `project.json`, or create new ones with an `e2e-` prefix. Never touch other people's accounts or data.
- Never run migrations against it without asking. A branch that adds a migration needs the developer's go-ahead before its e2e.
- Nothing destructive: no `TRUNCATE`, no bulk `DELETE`/`UPDATE`, no schema changes.

## Output

One short block: the service URLs, the database (local / shared / unknown), and anything missing for the e2e that follows.

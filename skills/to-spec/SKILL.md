---
name: to-spec
description: Turn the current conversation (usually a /grill-me session) into a spec at docs/specs/<slug>/spec.md, with the risk zone, the invariants every test must prove and the e2e scenarios. No interview; it synthesises what was already decided. Use when the developer asks for a spec.
disable-model-invocation: true
---

# To spec

Write the spec from what is already decided. Don't interview, with one exception: **a decision you discover while writing** (a route the grill didn't cover, a case where a decision doesn't fit) is not an open question. Stop, ask the developer that one question with your recommended answer, and write the answer into the spec. If the code can answer it, read the code instead.

## Steps

1. Explore the modules the change touches and read their READMEs, so the spec uses the code's names.
2. Choose the **test seams**: the public boundaries the tests will exercise (a controller route, a service method, a guard). Prefer existing seams and the highest one that works. Fewer is better.
3. **Check the library decisions against the docs.** For each decision that relies on how an external library or framework behaves (a framework guard or middleware, an ORM query or transaction, a validation rule, an HTTP client option, a vendor SDK), look it up with Context7 for the version the project's manifest pins, as `AGENTS.md` describes. If the docs disagree with the plan, that is a decision: ask the developer, with your recommended fix. Record what you checked under "Docs checked". Skip this step when the spec relies on no library behaviour.
4. **Sort what is still open** before writing it down; only the first kind goes in "Open questions":
   - **External facts** nobody here can settle (vendor plan features, limits they haven't published): first check the `docs/research/` note and our own data; if still open, write who answers it, the value the spec assumes meanwhile, and what changes if the answer differs.
   - **Work for a ticket** (check ids against other branches, list an app's actions, add a start command): "Notes for the tickets".
   - **Findings outside this spec** (a bug elsewhere, a deadline): "Outside this spec".
   - **Decisions**: never here; see above.
5. Pick a short kebab-case slug and write `docs/specs/<slug>/spec.md` with the template below, in the language set by `docsLanguage` in `.agents/project.json` (English when unset). Keep the template's headings so other skills can find the sections.
6. Run the `render-html` skill in `spec <slug>` mode (in Claude Code, the `html-renderer` sub-agent): there are no tickets yet, so the page shows the spec alone. The developer reads **the page**, not the markdown.
7. Show the developer the page path (`.review/specs/<slug>/index.html`; on macOS `open <path>`) and, in a few lines, the zone, the repos, the invariants and any decision the docs changed. They approve the spec before `/to-tickets`. When they ask for changes, edit `spec.md` and render the page again.

Don't put file paths or code in the spec, except a type or state machine that states a decision more precisely than prose.

## Template

```markdown
# <Title>

- **Zone:** 🔴 red | 🟡 yellow | 🟢 green (and why, in one line)
- **Repos:** <this repo> (and every related repo the change needs)
- **Rollout / flag:** <who gets it>, `FEATURE_X_ENABLED` (unset = off)
- **Status:** draft | approved

## Problem
What is wrong or missing, from the user's side (end user, operator, integration partner).

## Solution
What changes, from the same point of view.

## User stories
1. As a <user / operator / partner>, I want <capability>, so that <benefit>.
(Long and complete: every path, including the failure paths.)

## Invariants
Each one a testable sentence. Every one gets a test, and the red ones also an e2e scenario.
1. A webhook with a bad or missing signature is rejected with 403 and nothing changes.
2. The same event id twice is applied once.

## Decisions
Modules touched, interfaces, API contracts, schema changes and migrations, and the choices made in the grill.

## Test seams
| Seam | What it catches | What it misses |

## Docs checked
| Decision | Library @ version | Context7 id | What the docs say |
|---|---|---|---|
| <decision from above> | <package> @ <version in package.json> | </org/project[/version]> | <what the docs say, in one line> |

## E2E scenarios
Short list; /e2e expands them into docs/specs/<slug>/e2e.md.

## Out of scope

## Open questions
External facts only. Each: the question · who answers it · the value assumed meanwhile · what changes if it differs. "None" is a good answer.

## Notes for the tickets

## Outside this spec
Findings and deadlines that belong to other work.
```

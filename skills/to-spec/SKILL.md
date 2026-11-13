---
name: to-spec
description: Turn the current conversation (usually a /grill-me session) into a spec at docs/specs/<slug>/spec.md, with the risk zone, the invariants every test must prove and the e2e scenarios. No interview; it synthesises what was already decided. Use when the developer asks for a spec.
disable-model-invocation: true
---

# To spec

Write the spec from what is already decided. Don't interview; if something essential is missing, list it under "Open questions" instead of guessing.

## Steps

1. Explore the modules the change touches and read their READMEs, so the spec uses the code's names.
2. Choose the **test seams**: the public boundaries the tests will exercise (a controller route, a service method, a guard). Prefer existing seams and the highest one that works. Fewer is better.
3. **Check the library decisions against the docs.** For each decision that relies on how an external library or framework behaves (a framework guard or middleware, an ORM query or transaction, a validation rule, an HTTP client option, a vendor SDK), look it up with Context7 for the version the project's manifest pins, as `AGENTS.md` describes. If the docs disagree with the plan, fix the decision or raise it as an open question. Record what you checked under "Docs checked". Skip this step when the spec relies on no library behaviour.
4. Pick a short kebab-case slug and write `docs/specs/<slug>/spec.md` with the template below, in the language set by `docsLanguage` in `.agents/project.json` (English when unset). Keep the template's headings so other skills can find the sections.
5. Show the developer the zone, the invariants, the seams and any decision the docs changed. They approve the spec before `/to-tickets`.

Don't put file paths or code in the spec, except a type or state machine that states a decision more precisely than prose.

## Template

```markdown
# <Title>

- **Zone:** 🔴 red | 🟡 yellow | 🟢 green (and why, in one line)
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
```

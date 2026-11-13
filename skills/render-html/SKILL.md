---
name: render-html
description: Turn a spec with its tickets, or a review packet, into a polished HTML page a person actually wants to read (zones in color, the ticket dependency graph, invariants, the lines to read, e2e screenshots). The markdown stays the source of truth; the page is a view of it. Use at the end of /to-spec (spec alone), /to-tickets (spec and tickets) and /review-packet, or when the developer asks for a readable version of a spec or packet.
argument-hint: 'spec <slug> | review <branch>'
---

# Render HTML

People skim long markdown. This skill writes a page that leads with what matters and shows structure (zones, dependencies, pass/fail) at a glance. Agents keep reading the markdown.

## Who runs it

It is writing, not reasoning, so run it on a cheaper model than the orchestrator:

- **Claude Code:** the `html-renderer` sub-agent (Sonnet).
- **Orca or Herdr:** a worker of the current agent at the `standard` tier from `models` in `.agents/project.json` (`fast` is fine for a short packet). Signal and report as any worker.
- **Otherwise:** run it yourself.

Inside `/deliver`, don't wait on it: start it and keep going.

## Inputs and output

| Mode | Read | Write |
|---|---|---|
| `spec <slug>` | `docs/specs/<slug>/spec.md`, and `docs/specs/<slug>/tickets/*.md` when they exist | `.review/specs/<slug>/index.html` |
| `review <branch>` | `.review/<branch>/REVIEW.md`, `e2e-*.md`, `screenshots/` in that folder, the spec | `.review/<branch>/review.html` |

`<branch>` has `/` replaced by `-`. `.review/` is git-ignored, so the page is never committed.

## Steps

1. Read the inputs above, then `components.html` in this folder. It is the whole design vocabulary: use only its classes, never write `<style>` or inline styles, never add scripts or external assets.
2. Write the page's text in the `docsLanguage` of `.agents/project.json` (English when unset) (`build.mjs` sets `<html lang>` from the same field). Write only the body to `<output dir>/body.html`: the `topbar` nav, then one `<div class="page">` with the hero and the sections.
3. Build the page:
   ```bash
   node .agents/skills/render-html/build.mjs <output dir>/body.html <output> "<title>" <each source .md>
   ```
4. Delete `body.html`. Report the output path. On macOS the developer can run `open <output>`.

## What to put on the page

Lead with what the reader must decide or check, then the detail. Rewrite for the page; don't paste the markdown.

**Spec** (the developer approves it):
- Hero: the spec title, one sentence of what it delivers, zone, ticket and invariant counts as chips.
- Stats: tickets, red tickets, invariants, open questions.
- The problem and the user stories as cards.
- Tickets as `waves`, one column per dependency level, from the "Blocked by" lines, with each ticket's repo when the spec spans several. **No tickets yet** (right after `/to-spec`): leave out the waves and the ticket counts, show the repos as chips, and end with a `callout`: "Approve the spec, then `/to-tickets` splits it".
- Invariants table: number, invariant, the ticket that proves it.
- Open questions (`qa .open`) near the top if any block a ticket.
- Out of scope, test seams, docs checked, e2e scenarios: shorter, in `details` when long.

**Review packet** (the developer, then the lead reviewer):
- Hero: title, zone, files by zone, the "Must read" size in lines and minutes.
- A `callout` with the verdict: everything passes, or what is still open.
- Must read (`ol.must`) first, exactly as the packet lists it.
- Invariants → tests with `pill pass|fail|pend`.
- Decisions the orchestrator and the agents made (`qa .decided`).
- E2E: scenarios table, then screenshots (`shots`, paths relative to the page).
- Who built it, not tested, deploy notes, can skip: last.

## Rules

- **Faithful.** Every fact on the page is in the sources. No new claims, no softened findings, no invented numbers. If a section is empty in the source, say "none" instead of dropping it.
- **Complete for the reader's decision.** Every "Must read" entry, every invariant, every open question and every failing scenario appears. Brevity applies to prose, not to these lists.
- No secrets, tokens or personal data, same as the evidence files.
- The footer (added by `build.mjs`) names the sources and their hashes; don't remove it.

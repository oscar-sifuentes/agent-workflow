---
name: research
description: Research a question against primary sources (official provider or library docs, source code, specs) and save the findings with citations in docs/research/<topic>.md, in a background agent. Use before /grill-me on a new integration or unfamiliar API, or when asked to research, gather docs or check API facts.
---

# Research

Start a **background agent** for the reading, so the conversation can go on. Give it the question and the output path; tell the developer where the notes will land.

The agent:

1. **Primary sources only:** the provider's or library's official docs, its source code, the spec, the API reference. For libraries, use the Context7 CLI first, as `AGENTS.md` describes. Trace each claim to the source that owns it, not to a blog or a summary.
2. **For an integration**, cover at least: authentication and request signing (algorithm, which bytes are signed, header names), every callback and its payload, how retries and duplicates are sent, idempotency keys, amount units and rounding, error codes, test or sandbox credentials and URLs, and rate limits.
3. **Check our code** for prior art: a similar integration or guard already in the repo, and the module READMEs.
4. **Tries to close what the docs leave open**, without changing anything: a measurement with a trial or test key (latency, response shape), our own data for our side of a number (traffic peaks from the database or logs, read-only), or the provider's dashboard notes the developer pasted. Each result with how it was measured.
5. **Writes** `docs/research/<topic>.md` (in the `docsLanguage` of `.agents/project.json`, English when unset): a short summary first, then the facts, each with its source link, then what is still unknown (each with who can answer it: the vendor, a measurement that needs access we don't have, the developer) and contradictions between sources. No secrets or credentials in the file.

When it finishes, give the developer the summary and the open questions. `/grill-me` reads these notes.

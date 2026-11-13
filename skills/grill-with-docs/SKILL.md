---
name: grill-with-docs
description: The /grill-me interview plus domain modeling, which writes GLOSSARY.md terms and docs/adr/ decisions as they are settled. Use instead of /grill-me when the change brings new domain concepts (a new provider, currency, tenant, product type) or a hard-to-reverse architectural decision.
disable-model-invocation: true
---

# Grill with docs

Run two skills together:

1. Run the `grill-me` skill (`.agents/skills/grill-me/SKILL.md`) and follow it: one question at a time, until every invariant is a testable sentence.
2. Run the `domain-modeling` skill (`.agents/skills/domain-modeling/SKILL.md`) and apply it during the same interview:
   - When a term is settled ("sell-back", "tenant", "settlement"), add it to `GLOSSARY.md` right away.
   - When the developer uses a word that clashes with the glossary or the code, stop and resolve it.
   - Offer an ADR in `docs/adr/` only for a decision that is hard to reverse, surprising later, and the result of a real trade-off.

End the same way as `grill-me` (decisions, invariants, out of scope, open questions), plus the glossary terms and ADRs written. Next step: `/to-spec`.

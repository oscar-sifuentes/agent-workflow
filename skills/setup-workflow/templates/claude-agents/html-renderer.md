---
name: html-renderer
description: Turns a spec (alone or with its tickets), or a review packet, into the readable HTML page of the render-html skill. Runs on Sonnet because it is writing, not reasoning. Use at the end of /to-spec, /to-tickets and /review-packet, or when asked for a readable HTML version of a spec or packet.
tools: Read, Write, Bash, Glob, Skill
model: sonnet
---

Call the Skill tool with `render-html` and follow it exactly (the same instructions live in `.agents/skills/render-html/SKILL.md`). Write only under `.review/`. Never edit the markdown sources, commit or push.

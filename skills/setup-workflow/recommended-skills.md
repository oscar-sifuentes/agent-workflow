# Recommended stack skills

Only skills published by the vendor of the tool (or by a recognised tooling vendor), and only when they add knowledge the model lacks: fast-changing APIs, or a review against a maintained checklist. Generic skills (SOLID, clean code, "testing best practices") are never recommended: the model already knows them, and their opinions compete with the project's own conventions.

Install with `npx skills add <owner/repo> --skill <name>` after the developer says yes. Re-check install counts with `npx skills find <query>` when in doubt.

| Detected | Skill | Source | Why |
|---|---|---|---|
| React or Next.js | `vercel-react-best-practices` | `vercel-labs/agent-skills` | React and Next.js performance and patterns from Vercel, current with new versions |
| React or Next.js | `web-design-guidelines` | `vercel-labs/agent-skills` | Reviews UI code against Vercel's Web Interface Guidelines (accessibility, focus, forms, interaction); fetches the guidelines fresh each time |
| React, with composition-heavy components | `vercel-composition-patterns` | `vercel-labs/agent-skills` | Component composition patterns from Vercel |
| A new front end with no design system yet | `frontend-design` | `anthropics/skills` | Distinctive visual direction instead of a generic generated look. Don't use on a product with an existing brand: it invites the agent to restyle. Check its license before installing |
| Supabase | `supabase-postgres-best-practices` | `supabase/agent-skills` | Vendor guidance for Supabase Postgres |
| Prisma | `prisma-postgres` | `prisma/skills` | Vendor guidance for Prisma |
| Neon | `neon-postgres` | `neondatabase/agent-skills` | Vendor guidance for Neon |
| Clerk | `clerk-nextjs-patterns` | `clerk/skills` | Vendor guidance for Clerk with Next.js |
| Sentry SDK | the SDK skill for the framework | `getsentry/sentry-for-ai` | Vendor setup guidance |

Not recommended (seen and rejected): community "best practices" skills for back-end frameworks whose rules push structure (split services, custom repositories, injection tokens) that may contradict the team's conventions. For framework APIs, Context7 with the pinned version is enough.

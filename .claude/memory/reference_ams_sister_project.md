---
name: AMS sister project and cross-project context
description: Background on Kevin's other project (AMS), shared technical lessons, and the inventory methodology used across both repos
type: reference
---

# AMS Sister Project & Cross-Project Context

Kevin maintains two Java/JSP/Maven web apps for SSA (Superior State Administrators):

- **AMS** (github.com/Murphnd2/ams) — benefits administration platform. 196 servlets, 138 JPA entities, 280 JSPs. EclipseLink ORM, MySQL, Tomcat 10, Jakarta EE. Production runs on IONOS VPS (Ubuntu 24.04) across four hosts: ssa-production, ssa-demo, ssa-bpo, ssa-master. All behind nginx + Let's Encrypt SSL.
- **Jyrnyl** (github.com/Murphnd2/jotpage) — this project. Digital notebook / journaling app. Raw JDBC (no ORM), MySQL, Tomcat 10, Google OAuth, Whisper AI transcription.

Both repos use the same in-repo memory pattern (`.claude/memory/` tracked in git) and the same developer preferences (one step at a time, full file replacements, no unsolicited refactoring).

## AMS key facts (for cross-reference)

- **Internal name:** AMS. Maven artifactId `ams`, package `net.superiorstate.ams`.
- **Stack:** Java 17 (CI runs on 21), EclipseLink 3.0.2 JPA, JSoup, Jakarta Mail, Bootstrap, CKEditor 5 (CDN).
- **Build:** Maven WAR. Profiles: `local` (dev), `server` (deploy). WAR name: `ams`.
- **Entity inheritance:** Single-table inheritance rooted at `Assignee`. Chain: `Assignee → Activity → Ticket/Renewal/Setup/CheckList/Opportunity`. `Person extends Assignee`. Any FK to a Person column must reference `assignee(id)`, not `person(person_id)`.
- **Role IDs:** 1=PSP User, 2=Agent, 3=Client, 4=Applicant, 5=PSP Admin, 8=Agency Admin, 9=PSP Sales, 102=BPO Admin, 103=BPO User.
- **Migration discipline:** Versioned SQL scripts in `docs/migrations/` (V025–V062+). Each script self-registers in `schema_version`. Tracker: `docs/analysis/migration_tracker.md`.
- **"25" suffix convention:** Current/modern version of a servlet or JSP (e.g., `GoActivityDetail25.java`).
- **Production MySQL quirk:** Requires `LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu` due to Acronis library conflict.

## EclipseLink gotchas (AMS-specific, but good to know)

These don't apply to Jyrnyl (raw JDBC), but Kevin has been bitten by all three:

1. **L2 cache eviction after mutations.** `EntityManagerFactory.getCache().evictAll()` can corrupt the cache. Use per-class `evict(Class)` instead. Fixed in `DatabaseResetUtil.evictEntityCaches()`.
2. **Nested JOIN FETCH silently dropped.** EclipseLink ignores the inner fetch in `JOIN FETCH a.b JOIN FETCH a.b.c`. Workaround: separate queries. Three AMS queries remain unpatched (backlog item).
3. **EntityManager must stay open during JSP forward.** If EM is closed before `request.getRequestDispatcher().forward()`, lazy-loaded fields throw. Two patterns coexist safely in AMS production.

## Inventory methodology (used on both repos)

Both AMS and Jyrnyl went through a structured inventory pass in April 2026:

- **Pass 1:** Factual file/package map. No opinions, no changes. Output: `INVENTORY.md`, `CLAUDE-ASSETS.md`, `TECHNICAL-ARCHITECTURE.md` (AMS only), `DOMAIN-KNOWLEDGE.md` (AMS only), `DOCS-INDEX.md` (AMS only), `OPEN-QUESTIONS.md`.
- **Pass 2 (closure):** Every open question resolved with evidence. Resolution text appended directly to the open-questions file with commit references. AMS: 30/30 resolved, 3 real EclipseLink bugs found and fixed in the process. Jyrnyl: 15/15 resolved.
- **Key principle:** Inventory files record what IS, not what should be. Changes happen in separate commits, then the inventory entry gets a resolution note pointing to the commit.

## Toolkit concept (not implemented, preserved for reference)

A central git repo (`kevin-claude-toolkit`) was planned as a git submodule at `.claude/toolkit/` in both AMS and Jyrnyl. Purpose: share cross-cutting knowledge (developer preferences, generic lessons, reusable conventions) without copy-paste duplication. Design decisions made but never executed:

- Cross-cutting knowledge goes central; project-specific stays in each repo's `.claude/memory/`.
- Git submodule mechanism (not loose paths, not duplication).
- Maximum five files on day one; grow organically.
- Private repo on github.com/Murphnd2/kevin-claude-toolkit.

**Why it wasn't built:** The in-repo memory pattern already works well for each project independently. The toolkit can be bootstrapped later if a third project makes the duplication painful enough to justify the submodule overhead.

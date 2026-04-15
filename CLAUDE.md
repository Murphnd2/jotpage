# CLAUDE.md

Project-level context for Claude Code when working on Jyrnyl (repo: `jotpage`).

## Source of truth

- **Infrastructure, schema, deployment, brand, architecture:** `JOTPAGE_FULL_PROJECT_DOC.md` — always treat this as authoritative over any memory summary.
- **How Kevin prefers to collaborate + ongoing action items:** `.claude/memory/` — see index below.

## Project memory (read when relevant)

The following files in `.claude/memory/` encode persistent context about the user, the collaboration style, and active work items. Read the specific file(s) when the topic comes up; do not inline their content unless asked.

- [`.claude/memory/MEMORY.md`](.claude/memory/MEMORY.md) — index of all memories below.
- [`.claude/memory/feedback_pacing.md`](.claude/memory/feedback_pacing.md) — Kevin strongly prefers single-command instructions, not batched multi-step blocks. Apply to any walkthrough.
- [`.claude/memory/project_production_live.md`](.claude/memory/project_production_live.md) — Current state of production at jyrnyl.com (root context, Cloudflare + nginx + Tomcat + ROOT.war).
- [`.claude/memory/project_secrets_rotation.md`](.claude/memory/project_secrets_rotation.md) — Three production credentials exposed in chat on 2026-04-15; must be rotated before public launch.
- [`.claude/memory/user_workstation.md`](.claude/memory/user_workstation.md) — Kevin's role, dev workstation paths, what a workstation switch requires.
- [`.claude/memory/reference_external_systems.md`](.claude/memory/reference_external_systems.md) — Pointers to GitHub, Google Cloud Console, Anthropic Console, Cloudflare, IONOS.

## Writing new memories

When you learn something new and memory-worthy (per the memory-type rubric: user / feedback / project / reference), write it into `.claude/memory/` and add an index line to `.claude/memory/MEMORY.md`. These files are tracked in git so the memory travels between workstations.

Do NOT write to the machine-local Claude memory path (`~/.claude/projects/.../memory/`) — on this repo we've chosen the in-repo location as the single source of truth.

## Repo quick facts (do not duplicate the full doc here)

- Java 17 + Jakarta Servlet 6.0 + Tomcat 10 + MySQL 8, plain JDBC, no Spring.
- Build: `mvn clean package` produces `target/jotpage.war`.
- Prod deploy: scp the WAR to `/home/deploy/jyrnyl/` on `66.179.248.54`, then `sudo cp ... /var/lib/tomcat10/webapps/ROOT.war && sudo chown tomcat:tomcat ...`.
- Local dev: IntelliJ → Tomcat 10, VM option `-Djotpage.config=C:\ssa\jotpage.properties`.

# CLAUDE.md

Project-level orientation for Claude Code working on Jyrnyl (repo: `jotpage`).

## What Jyrnyl is

Jyrnyl is a voice-to-page digital journaling web app: users record or upload audio, the server transcribes it with Whisper and (for non-verbatim modes) reshapes the transcript with Claude, and the result is laid out across A5 canvas pages with an ink/text/image drawing layer on top. The product is publicly branded **Jyrnyl** ("Record your life"), but the repo, Maven artifact (`jotpage`), database (`jotpage`), and Java packages (`com.jotpage.*`) intentionally retain the original internal name.

## Stack and runtime

- **Language / runtime:** Java 17 (Maven `maven.compiler.source/target=17`)
- **Build:** Maven, WAR packaging — `mvn clean package` produces `target/jotpage.war`. No profiles. No CI/CD configured.
- **Servlet container:** Apache Tomcat 10 (Jakarta Servlet 6.0). No Spring, no JPA — plain servlets + JDBC.
- **Persistence:** MySQL 8 via the Connector/J `MysqlDataSource` populated from `jotpage.properties`. **Not JNDI** — `META-INF/context.xml` is empty. (`SETUP.md` describes a JNDI setup; it is the original scaffold prompt and is obsolete — disregard it for current work.)
- **External services:** Anthropic Claude API (model `claude-sonnet-4-20250514`, called via `HttpURLConnection` in `ClaudeService`); OpenAI Whisper CLI (subprocess via `WhisperService`, requires FFmpeg on PATH); Google OAuth 2.0 (`google-api-client` 2.7.0); Cloudflare in front of production for DNS/TLS.
- **PWA / service worker:** `src/main/webapp/sw.js`. **`CACHE_VERSION` must be bumped on every release that changes JS behaviour** — currently `'v9'`. Check `sw.js` directly; do not trust memory files for the live version.
- **Stripe:** schema columns and `Subscription`/`SubscriptionDao` exist, but no Stripe SDK in `pom.xml` and no servlet calls them. Treat as scaffold only.

## Repository layout

```
jotpage/
├── pom.xml                              Maven descriptor
├── CLAUDE.md                            this file
├── JOTPAGE_FULL_PROJECT_DOC.md          deeper architecture reference
├── JYRNYL_PRODUCT_SUMMARY_v2.md         current product summary (v1 superseded)
├── SETUP.md                             original scaffold prompt — obsolete
├── .claude/                             memory + inventory + permissions (tracked in git)
├── src/main/java/com/jotpage/
│   ├── model/  dao/  servlet/  util/    POJOs, JDBC DAOs, servlets, helpers
├── src/main/resources/
│   ├── schema.sql                       full create-from-scratch
│   ├── jotpage.properties.example       template (no real secrets)
│   └── migrations/                      001..005 manual SQL migrations
├── src/main/webapp/
│   ├── index.jsp  jsp/  WEB-INF/        login + dashboard/editor/voice-record + jspf fragments
│   ├── js/  css/  images/  icons/       client assets
│   ├── sw.js  manifest.webmanifest      PWA
│   └── META-INF/context.xml             empty Tomcat context
└── tools/IconGenerator.java             standalone PWA-icon generator (not in Maven build)
```

## Production environment

Live at https://jyrnyl.com behind Cloudflare (Full Strict, orange-cloud) → IONOS VPS at `66.179.248.54` (Ubuntu 24.04) → nginx 1.24 → Tomcat 10 on `127.0.0.1:8080`. The WAR is deployed as `/var/lib/tomcat10/webapps/ROOT.war` (root context — no `/jotpage/` prefix). MySQL 8 is local-only on the box; Whisper venv at `/opt/whisper/venv` (binary symlinked to `/usr/local/bin/whisper`); FFmpeg at `/usr/bin/ffmpeg`. The runtime properties file is `/etc/tomcat10/jotpage.properties` (resolved via `{catalina.base}/conf/`). For the full deploy procedure, see [`.claude/memory/project_deploy_flow.md`](.claude/memory/project_deploy_flow.md) and [`.claude/memory/project_production_live.md`](.claude/memory/project_production_live.md).

## Local development

Windows + IntelliJ + a local Tomcat 10 run config. Properties file at `C:\ssa\jotpage.properties`, wired via VM option `-Djotpage.config=C:\ssa\jotpage.properties`. Local Maven, MySQL, FFmpeg, and Whisper toolchains required. **Local Tomcat deploys the WAR at `/jotpage/` context, not root** — so the local OAuth redirect URI is `http://localhost:8080/jotpage/oauth2callback` (vs. `https://jyrnyl.com/oauth2callback` in prod). Per-workstation specifics in [`.claude/memory/user_workstation.md`](.claude/memory/user_workstation.md).

## Where deeper context lives

- [`.claude/memory/`](.claude/memory/) — operational gotchas: deploy flow, SSH discipline, pacing preferences, secrets rotation, Voice Booth open bugs. Indexed in [`MEMORY.md`](.claude/memory/MEMORY.md).
- [`.claude/inventory/`](.claude/inventory/) — pass-1 audit output: [`JYRNYL-INVENTORY.md`](.claude/inventory/JYRNYL-INVENTORY.md) (factual map), [`JYRNYL-CLAUDE-ASSETS.md`](.claude/inventory/JYRNYL-CLAUDE-ASSETS.md) (`.claude/` contents), [`JYRNYL-OPEN-QUESTIONS.md`](.claude/inventory/JYRNYL-OPEN-QUESTIONS.md) (15 open questions, numbered).
- [`JOTPAGE_FULL_PROJECT_DOC.md`](JOTPAGE_FULL_PROJECT_DOC.md) — authoritative deeper project doc (note the file/title still say "JotPage"; the internal name was kept on purpose).
- [`JYRNYL_PRODUCT_SUMMARY_v2.md`](JYRNYL_PRODUCT_SUMMARY_v2.md) — current product summary. The unsuffixed `JYRNYL_PRODUCT_SUMMARY.md` is an earlier draft; v2 supersedes it.

When this file and the inventory disagree, the inventory is authoritative — it is the most recent factual sweep.

## Developer preferences

Pulled from [`.claude/memory/feedback_pacing.md`](.claude/memory/feedback_pacing.md) and [`.claude/memory/feedback_deploy_ssh.md`](.claude/memory/feedback_deploy_ssh.md):

- **One step at a time, one command per step.** Wait for confirmation before the next. Don't batch numbered walkthroughs — earlier steps often fail and invalidate later ones. Read-only verification bundles (independent commands) are an acceptable exception.
- **Multi-file edits go one file at a time** — confirm before moving to the next file.
- **SSH login is its own step.** Never combine `ssh user@host` with the remote command. Each subsequent remote command (`sudo cp`, `chown`, `systemctl`) is also its own step.

## Writing new memories

When you learn something memory-worthy (user / feedback / project / reference per the rubric), write a new file under [`.claude/memory/`](.claude/memory/) and add a one-line index entry to [`.claude/memory/MEMORY.md`](.claude/memory/MEMORY.md). These files are tracked in git so memory travels with the repo. Do **not** write to the machine-local Claude memory path (`~/.claude/projects/.../memory/`); the in-repo location is the single source of truth on this project.

## Known unknowns

Items below reference numbers in [`JYRNYL-OPEN-QUESTIONS.md`](.claude/inventory/JYRNYL-OPEN-QUESTIONS.md). Surface-only — see that file for evidence.

- **#1, #2 — `SETUP.md` is obsolete.** Pre-rebrand and pre-secrets-externalization, contains JNDI guidance that contradicts the current code. Do not use it as a reference for current work.
- **#3 — Stripe scaffolding is not wired.** `Subscription`, `SubscriptionDao`, and the `user_subscriptions` table exist; no servlet calls them and `pom.xml` has no Stripe SDK. Confirm intent before either implementing or deleting.
- **#5 — `project_deploy_flow.md` claims `CACHE_VERSION = 'v4'`.** It's actually `'v9'` in `sw.js`. Always check `sw.js` directly rather than the memory note.
- **#14 — `ai_jobs` has no stuck-`processing` recovery.** If Tomcat restarts mid-job, that row stays `processing` forever. Currently acceptable at this traffic level; revisit before scale.
- **#15 — Internal name "jotpage" vs. brand "Jyrnyl" is intentional.** Maven artifactId, DB schema, Java packages, and the WAR filename all stay `jotpage`. Only the user-facing surface is "Jyrnyl".

## Security baseline (as of 2026-04-25)

All three production secrets — Google OAuth client secret, Anthropic API key, MySQL `jotpage` password — were rotated on 2026-04-25. Jyrnyl now uses its own dedicated Anthropic API key, separate from any AMS-shared key. The active property names in `/etc/tomcat10/jotpage.properties` are `google.clientSecret`, `anthropic.apiKey`, and `db.password`. The rotation procedure is documented in [`.claude/memory/project_secrets_rotation.md`](.claude/memory/project_secrets_rotation.md); the specific values listed in that file are stale (rotated away), but the procedure itself is still valid. Never embed real secret values in chat, commits, or memory files.

## What NOT to assume

This file is a snapshot. Versions, branches, deployed state, cache version numbers, and credential property names drift over time. For anything time-sensitive, read the authoritative source directly — `git log` for history, the live `/etc/tomcat10/jotpage.properties` for runtime config, `sw.js` for the current cache version, and the running server for deployed behaviour — rather than trusting this file.

# JYRNYL-INVENTORY.md — Pass 1 Factual Inventory
**Date:** 2026-04-25  
**Branch inventoried:** main (HEAD 4728642)  
**Inventory branch:** inventory/pass-1-jyrnyl

---

## 1. Top-Level Directory Structure (depth 1)

| Path | Description |
|---|---|
| `.claude/` | Claude Code project config: `settings.local.json` + in-repo memory files |
| `.git/` | Git internal data (excluded from traversal) |
| `.idea/` | IntelliJ IDEA project files (gitignored) |
| `src/` | Maven standard source tree (`src/main/java`, `src/main/resources`, `src/main/webapp`) |
| `target/` | Maven build output directory (gitignored) |
| `tools/` | One-off Java utility (`IconGenerator.java`); not part of the Maven build |
| `.gitignore` | Excludes `.idea/`, `target/`, `jotpage.properties`, `client_secret_*.json` |
| `CLAUDE.md` | Claude Code project instructions (source-of-truth pointer + memory index) |
| `JOTPAGE_FULL_PROJECT_DOC.md` | Comprehensive project documentation (authoritative per CLAUDE.md) |
| `JYRNYL_PRODUCT_SUMMARY.md` | Short product summary (prior to v2 revision) |
| `JYRNYL_PRODUCT_SUMMARY_v2.md` | Updated product summary |
| `SETUP.md` | Original bootstrap prompt used to scaffold the Maven project |
| `client_secret_495733086690-…json` | Google OAuth credentials JSON — **tracked in git** despite gitignore pattern `client_secret_*.json` |
| `pom.xml` | Maven project descriptor |

---

## 2. Build System

**File:** `pom.xml`

- **groupId:** `com.jotpage`
- **artifactId:** `jotpage`
- **version:** `1.0-SNAPSHOT`
- **packaging:** `war`
- **Java source/target:** 17 (`maven.compiler.source`, `maven.compiler.target`)
- **Build output name:** `jotpage` (`<finalName>jotpage</finalName>`) → produces `target/jotpage.war`

### Declared Dependencies

| Dependency | Version | Scope |
|---|---|---|
| `jakarta.servlet:jakarta.servlet-api` | 6.0.0 | provided |
| `com.mysql:mysql-connector-j` | 8.3.0 | compile |
| `com.google.code.gson:gson` | 2.11.0 | compile |
| `com.google.api-client:google-api-client` | 2.7.0 | compile |
| `com.google.oauth-client:google-oauth-client-jetty` | 1.36.0 | compile |
| `com.google.apis:google-api-services-oauth2` | v2-rev20200213-2.0.0 | compile |
| `jakarta.servlet.jsp.jstl:jakarta.servlet.jsp.jstl-api` | 3.0.0 | compile |
| `org.glassfish.web:jakarta.servlet.jsp.jstl` | 3.0.1 | compile |

### Maven Plugins

| Plugin | Version | Configuration |
|---|---|---|
| `maven-compiler-plugin` | 3.13.0 | source=17, target=17 |
| `maven-war-plugin` | 3.4.0 | default configuration |

No Maven profiles declared.

---

## 3. Java Packages

Root package: `com.jotpage`

### `com.jotpage.model` — 8 files
| File | Fields |
|---|---|
| `User.java` | `id`, `googleId`, `email`, `displayName`, `avatarUrl`, `tier`, `createdAt`, `updatedAt` |
| `Page.java` | `id`, `userId`, `pageTypeId`, `title`, `sortOrder`, `inkData`, `textLayers`, `imageLayers`, `closed`, `createdAt`, `updatedAt` |
| `PageType.java` | `id`, `userId`, `name`, `backgroundType`, `backgroundData`, `immutableOnClose`, `system`, `sortOrder`, `createdAt` |
| `Tag.java` | `id`, `userId`, `name`, `color`, `createdAt` |
| `PageTag.java` | `pageId`, `tagId` (inferred from schema; file exists in the tree but not individually read — see JOTPAGE_FULL_PROJECT_DOC.md:33) |
| `Subscription.java` | `id`, `userId`, `tier`, `stripeCustomerId`, `stripeSubscriptionId`, `expiresAt`, `createdAt`, `updatedAt` |
| `AiJob.java` | `id`, `userId`, `jobType`, `status`, `inputText`, `outputText`, `audioFilePath`, `customPrompt`, `errorMessage`, `createdAt`, `updatedAt` |
| `UsageRecord.java` | `id`, `userId`, `monthYear`, `pagesCreated`, `aiJobsRun`, `audioMinutesProcessed`, `createdAt`, `updatedAt` |

### `com.jotpage.dao` — 9 files
| File | Key public methods |
|---|---|
| `UserDao.java` | `findByGoogleId`, `createOrUpdate`, `updateTier` |
| `PageDao.java` | `findById`, `findByUserId`, `findByUserIdAndPageTypeId`, `create`, `update`, `reorder`, `close`, `countByUserId`, `delete` |
| `PageTypeDao.java` | `findSystemTypes`, `findByUserId`, `findById`, `create`, `delete`, `countCustomByUserId`, `updateSortOrder` |
| `TagDao.java` | `findByUserId`, `create`, `update`, `countPages`, `replaceTag`, `delete` |
| `PageTagDao.java` | `addTag`, `removeTag`, `findTagsByPageId`, `findPagesByTagId` |
| `SubscriptionDao.java` | `findByUserId`, `createOrUpdate`, `isProUser` |
| `AiJobDao.java` | `create`, `findById`, `updateStatus`, `findByUserId`, `countByUserIdAndJobType` |
| `UsageDao.java` | `findOrCreateCurrentMonth`, `incrementPages`, `incrementAiJobs`, `incrementAudioMinutes` |
| `TemplateInUseException.java` | `RuntimeException` subclass; thrown by `PageTypeDao.delete()` on FK violation (MySQL SQLState 23000 / error 1451) |

### `com.jotpage.servlet` — 12 files
| File | URL mapping | Methods handled |
|---|---|---|
| `AuthFilter.java` | `/app/*` | Jakarta `Filter`; redirects to `/login` if no session |
| `NoCacheFilter.java` | `/sw.js`, `/manifest.webmanifest` | Jakarta `Filter`; sets `Cache-Control: no-store` |
| `LoginServlet.java` | `/login` | GET → redirects to Google OAuth authorization URL |
| `OAuthCallbackServlet.java` | `/oauth2callback` | GET → exchanges OAuth code, creates/updates user, sets session |
| `LogoutServlet.java` | `/logout` | GET → invalidates session |
| `DashboardServlet.java` | `/app/dashboard` | GET → renders `dashboard.jsp` (book or list view) |
| `PageServlet.java` | `/app/page/*` | GET (view/new), PUT (save ink/text/imageLayers, reorder), DELETE |
| `PageThumbnailServlet.java` | `/app/api/page-thumbnail/*` | GET → returns minimal JSON for book-view lazy render |
| `PageTypeServlet.java` | `/app/api/pagetypes/*` | GET, POST (multipart PNG upload), DELETE, PUT (reorder) |
| `TagServlet.java` | `/app/api/tags/*` | GET, POST, PUT, DELETE (with optional `?replaceWith=` merge) |
| `PageTagServlet.java` | `/app/api/page-tags/*` | GET, POST (add tag to page), DELETE (remove tag from page) |
| `VoiceRecordServlet.java` | `/app/voice-record` | GET (render form), POST (multipart audio upload → Whisper → Claude → page creation) |

`VoiceRecordServlet` is annotated `@MultipartConfig(maxFileSize=26,214,400, maxRequestSize=27,262,976)` (25 MB / ~26 MB) (`VoiceRecordServlet.java:46-50`).  
`PageTypeServlet` is annotated `@MultipartConfig(maxFileSize=5MB, maxRequestSize=6MB)` (`PageTypeServlet.java:29-33`).

### `com.jotpage.util` — 6 files
| File | Purpose |
|---|---|
| `AppConfig.java` | Singleton `java.util.Properties` loader; 3-step lookup: `-Djotpage.config` system property → `{catalina.base}/conf/jotpage.properties` → classpath |
| `DbUtil.java` | Singleton `MysqlDataSource` from AppConfig `db.*` keys; no JNDI |
| `ClaudeService.java` | HTTP wrapper around `https://api.anthropic.com/v1/messages`; model `claude-sonnet-4-20250514`; max_tokens 4096 |
| `WhisperService.java` | Runs the Whisper CLI as a subprocess (`ProcessBuilder`); 5-minute timeout; handles ffmpeg PATH prepend |
| `TierCheck.java` | Pure gatekeeper for free/pro limits; reads `pro.emails` from `AppConfig` |
| `PageSplitter.java` | Splits text into page-sized chunks; canvas 1480×2100 (A5 at 10x); exposes `POINT_TO_PIXEL = 10` |
| `VoiceModeValidator.java` | Pre-flight transcript validation for non-verbatim AI modes; returns pass/fail with user-facing message |

---

## 4. Web Assets (`src/main/webapp/`)

### Directory layout

```
src/main/webapp/
├── META-INF/context.xml        — Empty Tomcat context; comment says credentials moved to jotpage.properties
├── WEB-INF/
│   ├── web.xml                 — Jakarta Servlet 6.0 descriptor; filter/servlet mappings
│   └── jspf/                  — JSP fragment includes
│       ├── bubble-menu.jspf   — Floating radial menu HTML + inline CSS
│       ├── edge-tabs.jspf     — Edge-tab navigation fragment
│       ├── pen-button.jspf    — Floating pen/pencil button fragment
│       ├── pwa-head.jspf      — PWA <link>/<meta> tags for <head>
│       └── pwa-register.jspf  — Service worker registration script
├── css/
│   └── theme.css              — 238 lines; CSS custom properties, typography, layout tokens
├── icons/
│   ├── favicon-32.png         — 32×32 favicon
│   ├── icon-192.png           — PWA icon 192×192
│   ├── icon-512.png           — PWA icon 512×512
│   └── icon-maskable-512.png  — PWA maskable icon 512×512
├── images/
│   ├── jyrnyl-banner-1500.png — 1500px wide brand banner
│   ├── jyrnyl-banner.svg      — SVG brand banner
│   ├── jyrnyl-logo-400.png    — Logo 400×400
│   ├── jyrnyl-logo-800.png    — Logo 800×800
│   └── jyrnyl-logo-square.svg — Square SVG logo
├── js/
│   ├── book-view.js           — 867 lines; book/spine dashboard view, lazy thumbnail loading
│   ├── bubble-menu.js         — 455 lines; draggable floating radial menu, gesture handling
│   ├── edge-tabs.js           — 159 lines; slide-out edge tab navigation
│   ├── ink-engine.js          — 1275 lines; HTML5 Canvas ink drawing, text layers, image layers
│   ├── pen-button.js          — 260 lines; pen/pencil mode toggle button
│   ├── tablet-mode.js         — 231 lines; tablet UX (touch vs pointer distinction)
│   └── voice-recorder.js      — 661 lines; MediaRecorder API, live transcript dedup, voice booth UI
├── jsp/
│   ├── dashboard.jsp          — 2131 lines; main notebook view (book + list modes, tag filter, tier UI)
│   ├── editor.jsp             — 942 lines; page editor with ink/text/image layer canvas
│   └── voice-record.jsp       — 771 lines; voice recording UI (mode cards, mic, transcript display)
├── index.jsp                  — 96 lines; landing/login page
├── manifest.webmanifest       — PWA manifest; name "Jyrnyl", start_url "/app/dashboard", shortcuts for "Drop a new track" and "Voice record"
├── offline.html               — Offline fallback page (contents not read)
└── sw.js                      — 121 lines; service worker; CACHE_VERSION = 'v9'; strategy: network-first for navigation, stale-while-revalidate for static assets
```

**File counts by type under `src/main/webapp/`:**
- `.jsp` / `.jspf`: 8 files
- `.js`: 7 files
- `.css`: 1 file
- `.png`: 7 files
- `.svg`: 2 files
- `.json` / `.webmanifest`: 1 file each
- `.html`: 1 file
- `.xml`: 2 files (context.xml, web.xml)

---

## 5. Configuration Files

| Path | Configures |
|---|---|
| `pom.xml` | Maven build: dependencies, plugins, Java version |
| `src/main/webapp/WEB-INF/web.xml` | Jakarta Servlet 6.0 descriptor: filters, servlet mappings, welcome-file, MIME types |
| `src/main/webapp/META-INF/context.xml` | Empty Tomcat context element (no JNDI DataSource; comment references migration to `jotpage.properties`) |
| `src/main/resources/jotpage.properties.example` | Template for all runtime config: Google OAuth, DB JDBC, Whisper CLI, Anthropic API key, `pro.emails` whitelist |
| `src/main/webapp/manifest.webmanifest` | PWA manifest: name, icons, start URL, shortcuts |
| `.claude/settings.local.json` | Claude Code permission allowlist for `git`, `mvn`, `ssh`, `scp`, and specific one-off commands |

---

## 6. Scripts

| Path | Type | Description |
|---|---|---|
| `tools/IconGenerator.java` | Java (standalone; not in Maven src) | Generates 4 Jyrnyl PWA icons into `src/main/webapp/icons/`. Run manually: `javac tools/IconGenerator.java && java -cp tools IconGenerator`. Not integrated into the Maven build. |

No `.sh`, `.bat`, `.ps1`, or `.py` files found in the repo.

---

## 7. Database Artifacts

### Schema (`src/main/resources/schema.sql`)
Full create-from-scratch script. Tables:

| Table | Key columns |
|---|---|
| `users` | `id`, `google_id` (UNIQUE), `email`, `display_name`, `avatar_url`, `tier ENUM('free','pro')` |
| `user_subscriptions` | `id`, `user_id` (UNIQUE FK), `tier`, `stripe_customer_id`, `stripe_subscription_id`, `expires_at` |
| `ai_jobs` | `id`, `user_id`, `job_type ENUM(verbatim,study_notes,meeting_minutes,journal_entry,outline,custom)`, `status ENUM(pending,processing,complete,failed)`, `input_text`, `output_text`, `audio_file_path`, `custom_prompt`, `error_message` |
| `usage_tracking` | `id`, `user_id`, `month_year VARCHAR(7)`, `pages_created`, `ai_jobs_run`, `audio_minutes_processed DECIMAL(10,2)`; UNIQUE on `(user_id, month_year)` |
| `page_types` | `id`, `user_id` (NULL for system types), `name`, `background_type ENUM(blank,lined,dot_grid,graph,daily_calendar,monthly_calendar,time_slot,custom)`, `background_data MEDIUMTEXT`, `immutable_on_close`, `is_system`, `sort_order` |
| `pages` | `id`, `user_id`, `page_type_id`, `title`, `sort_order`, `ink_data JSON`, `text_layers JSON`, `image_layers MEDIUMTEXT`, `is_closed` |
| `tags` | `id`, `user_id`, `name VARCHAR(100)`, `color VARCHAR(7)`; UNIQUE on `(user_id, name)` |
| `page_tags` | `page_id`, `tag_id` (composite PK; CASCADE deletes) |

Seed data: 4 system `page_types` (Blank, Lined, Dot Grid, Graph).  
Also creates MySQL user `jotpage@localhost` with CHANGEME password (`schema.sql:111-113`).

### Migrations (`src/main/resources/migrations/`)
Applied manually; no migration framework.

| File | Description |
|---|---|
| `001_add_page_sort_order.sql` | `ALTER TABLE pages ADD COLUMN sort_order INT`; initializes existing rows |
| `002_ai_pipeline_and_tiers.sql` | Adds `users.tier` column; creates `user_subscriptions`, `ai_jobs`, `usage_tracking` tables |
| `003_remove_calendar_templates.sql` | Reassigns pages from deleted calendar/timeslot system types to Blank; deletes 3 system `page_type` rows |
| `004_add_pagetype_sort_order.sql` | `ALTER TABLE page_types ADD COLUMN sort_order INT`; initializes existing rows |
| `005_add_image_layers.sql` | `ALTER TABLE pages ADD COLUMN image_layers MEDIUMTEXT NULL` |

---

## 8. `.claude/` Contents

```
.claude/
├── settings.local.json     — Claude Code project-level permission allowlist (tracked in git)
└── memory/
    ├── MEMORY.md                       — Index of all memory files below
    ├── feedback_pacing.md              — Feedback: single-command-at-a-time rule
    ├── feedback_deploy_ssh.md          — Feedback: SSH login as separate step before remote commands
    ├── project_production_live.md      — Project: production deployment state at jyrnyl.com
    ├── project_deploy_flow.md          — Project: step-by-step deploy procedure
    ├── project_secrets_rotation.md     — Project: three credentials exposed in chat on 2026-04-15
    ├── project_voice_booth_rethink.md  — Project: Voice Booth UX tabled; open bugs recorded
    ├── reference_external_systems.md   — Reference: GitHub, Google Cloud Console, Anthropic, Cloudflare, IONOS
    └── user_workstation.md             — User: Kevin Murphy; two Windows workstations; SSH key notes
```

---

## 9. Docs / Top-Level Files

| File | Last commit | Description |
|---|---|---|
| `CLAUDE.md` | 2026-04-15 | Claude Code instructions; designates `JOTPAGE_FULL_PROJECT_DOC.md` as authoritative |
| `JOTPAGE_FULL_PROJECT_DOC.md` | 2026-04-16 | Full architecture, deploy process, schema, feature descriptions |
| `JYRNYL_PRODUCT_SUMMARY.md` | 2026-04-15 | Short marketing/product summary (version 1) |
| `JYRNYL_PRODUCT_SUMMARY_v2.md` | 2026-04-16 | Updated product summary |
| `SETUP.md` | 2026-04-12 | Original Maven project scaffold prompt used to initialize the repo |

---

## 10. External Integrations

Identified from `pom.xml`, `jotpage.properties.example`, and Java source:

| Integration | Entry point | Config key |
|---|---|---|
| **Google OAuth 2.0** | `LoginServlet`, `OAuthCallbackServlet` | `google.clientId`, `google.clientSecret`, `google.redirectUri` |
| **MySQL 8** | `DbUtil` → `MysqlDataSource` | `db.url`, `db.username`, `db.password`, `db.driverClassName`, `db.maxTotal`, `db.maxIdle`, `db.maxWaitMillis` |
| **Anthropic Claude API** | `ClaudeService` via `VoiceRecordServlet` | `anthropic.apiKey`; endpoint `https://api.anthropic.com/v1/messages` |
| **OpenAI Whisper CLI** (local) | `WhisperService` via `VoiceRecordServlet` | `whisper.command`, `whisper.model`, `ffmpeg.path` |
| **Stripe** (data model only) | `Subscription.java`, `SubscriptionDao.java` | `stripe_customer_id`, `stripe_subscription_id` columns in `user_subscriptions` |

Note: Stripe appears in the DB schema and Java model/DAO layer only. No Stripe SDK dependency in `pom.xml`. No servlet endpoint calls `SubscriptionDao`. (See JYRNYL-OPEN-QUESTIONS.md, item 3.)

---

## 11. CI/CD

No `.github/`, `.gitlab-ci.yml`, `Jenkinsfile`, or equivalent CI/CD configuration was found in the repository.

---

## Staleness Assessment

The repo's first commit is `adb1dbb` (2026-04-12). All files postdate it. No files predate the first commit.

Files last modified on the oldest commit date (2026-04-12):
- `SETUP.md` — original scaffold prompt; content describes a simpler state than the current codebase (see JYRNYL-OPEN-QUESTIONS.md, items 1 and 2).

`project_deploy_flow.md` mentions `CACHE_VERSION` as "current: v4"; `sw.js` shows `CACHE_VERSION = 'v9'` — the memory file is stale relative to the code (see JYRNYL-OPEN-QUESTIONS.md, item 5).

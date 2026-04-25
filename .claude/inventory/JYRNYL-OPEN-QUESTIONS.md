# JYRNYL-OPEN-QUESTIONS.md — Open Questions, Contradictions, Surprises
**Date:** 2026-04-25  
**Branch inventoried:** main (HEAD 4728642)

---

## 1. `SETUP.md` describes JNDI — code uses `jotpage.properties`

**Title:** SETUP.md's `DbUtil` description contradicts actual `DbUtil.java`

**Evidence:**
- `SETUP.md:26` states: "Create `DbUtil.java` — a simple JDBC connection utility class that reads DB url/user/pass from **context.xml JNDI resource** named `jdbc/jotpage`."
- `SETUP.md:28` states: "Create `context.xml` with a **JNDI DataSource resource** for MySQL."
- `DbUtil.java:1-54` — actual implementation uses `MysqlDataSource` populated from `AppConfig.get("db.*")`. No JNDI. Comment on line 14 explicitly says: "Previous versions used a JNDI DataSource configured in `META-INF/context.xml`. This version reads from the external `jotpage.properties` file instead."
- `src/main/webapp/META-INF/context.xml` — contains only `<Context/>` (empty), with a comment: "Database credentials are now in jotpage.properties, not here."

**Question:** `SETUP.md` is the original bootstrap prompt (committed 2026-04-12, before the secrets-externalization commit `777f997` on the same day). Is `SETUP.md` intentionally preserved as a historical artifact, or is it meant to document the current setup? If the latter, it is wrong and misleading.

---

## 2. `SETUP.md` describes a "JotPage" landing page — current app is "Jyrnyl"

**Title:** SETUP.md content is pre-rebrand

**Evidence:**
- `SETUP.md:1` begins: "Set up a Maven project called **jotpage**…"
- `SETUP.md:31` describes: "a bare-bones **JotPage** landing page that includes Bootstrap 5 CDN and has a **Sign in with Google button placeholder**."
- The actual `index.jsp` (96 lines) is a fully styled Jyrnyl-branded immersive cover page with Google Sign-In implemented, not a placeholder.
- `web.xml:8` shows `<display-name>Jyrnyl</display-name>`.
- The rebrand commit is `f472b8c` (2026-04-12).

**Question:** Same as item 1 — is `SETUP.md` intentionally a historical artifact (the original scaffold prompt) or documentation that should be kept current? If it should be kept current, it needs to be entirely rewritten.

---

## 3. `SubscriptionDao` and `Subscription` model exist but are never called by any servlet

**Title:** Stripe subscription infrastructure is wired but dead-end

**Evidence:**
- `src/main/java/com/jotpage/model/Subscription.java` — full POJO with `stripeCustomerId`, `stripeSubscriptionId`, `expiresAt`.
- `src/main/java/com/jotpage/dao/SubscriptionDao.java` — full DAO with `findByUserId`, `createOrUpdate`, `isProUser`.
- `src/main/resources/schema.sql:15-25` — `user_subscriptions` table defined with Stripe columns.
- No servlet, filter, or utility class imports or instantiates `SubscriptionDao`.
- `pom.xml` — no Stripe SDK dependency.
- `TierCheck.java:51-57` — tier is determined from `User.getTier()` (the `users.tier` DB column) and `pro.emails` property; `SubscriptionDao.isProUser()` is never called.

**Question:** Is the Stripe/subscription infrastructure stub code for a planned feature? If so, when is it expected to be wired up? If there are no plans, does this dead code create maintenance burden?

---

## 4. `client_secret_*.json` is tracked in git despite the `.gitignore` rule

**Title:** Live Google OAuth credentials file committed to the repo

**Evidence:**
- `.gitignore:14` contains the line: `client_secret_*.json`
- `git ls-files client_secret_495733086690-…json` → `TRACKED` — the file IS in the git index.
- The file contains: `"client_secret":"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"` — this appears to be a live credential.
- The filename matches the gitignore glob, which means the file was committed before the gitignore entry was added, or the entry was added after `git add` had already staged it.

**Question:** Was this file committed accidentally? The gitignore entry suggests the intent was to keep it out. The file contains what appears to be a live Google OAuth client secret. If the secret has not been rotated, it is exposed to anyone who can clone or read this git history. (This overlaps with `project_secrets_rotation.md` which already notes the Google OAuth client secret as needing rotation, though it does not mention the committed file directly.)

**Immediate action needed:** Confirm whether this secret has been rotated. Rotating the secret alone is not sufficient — the file will remain in git history. If the repo is or will be public, the history must be scrubbed (e.g., `git filter-repo` or BFG Repo Cleaner).

---

## 5. `project_deploy_flow.md` says `CACHE_VERSION = 'v4'`; `sw.js` shows `'v9'`

**Title:** Memory file cites stale cache version

**Evidence:**
- `.claude/memory/project_deploy_flow.md` (last modified 2026-04-16): "Bump it on every release that changes JS behaviour (current: **v4**)."
- `src/main/webapp/sw.js:19` (last modified 2026-04-15): `const CACHE_VERSION = 'v9';`

**Note:** The `sw.js` file predates the `project_deploy_flow.md` file by commit order, yet shows a higher version. This means the memory file was written with incorrect version information, or the version in `sw.js` was bumped multiple times before `project_deploy_flow.md` was written.

**Question:** Is the service worker cache version note in `project_deploy_flow.md` simply stale? If it exists to orient future readers about how to bump the version, the specific "current" number should be removed or the file should be updated on each release.

---

## 6. `ClaudeService.java` and `WhisperService.java` javadocs say "Config comes from web.xml context params"

**Title:** Javadoc comment in two utility classes references a configuration source that no longer exists

**Evidence:**
- `ClaudeService.java:9-11`: "Config comes from **web.xml context params**: `anthropic.apiKey`"
- `WhisperService.java:12-16`: "Config comes from **web.xml context params** (wired by the servlet layer): `whisper.command`, `whisper.model`, `ffmpeg.path`"
- `web.xml` — contains no context params at all. Config is loaded from `jotpage.properties` via `AppConfig`.
- `VoiceRecordServlet.java:72-74` — calls `AppConfig.get("whisper.command", "whisper")` etc., not servlet context.

**Question:** These comments are misleading to a reader of the utility classes. They reflect an earlier design where the servlet layer injected config. Since the docs are otherwise sparse, this creates confusion about where the config actually comes from. Is there a reason these javadocs were not updated alongside the config migration?

---

## 7. `PageDao.create()` does not include `image_layers` in the INSERT

**Title:** `image_layers` column omitted from `PageDao.create()` SQL

**Evidence:**
- `PageDao.java:69-71`: INSERT statement names columns: `user_id, page_type_id, title, sort_order, ink_data, text_layers, is_closed` — no `image_layers`.
- `schema.sql:79`: `image_layers MEDIUMTEXT NULL` is a nullable column, so the INSERT will succeed with NULL.
- `PageDao.update()` at line 125 DOES include `image_layers` in the UPDATE.
- `VoiceRecordServlet.buildPage()` at line 399 populates `page.setInkData()` and `page.setTextLayers()` but not `setImageLayers()` — so voice-created pages will have NULL `image_layers`, which is consistent.

**Question:** Is it intentional that newly created pages via `PageDao.create()` always have NULL `image_layers`? If a future path creates pages with image layers pre-populated (e.g. a duplicate/copy feature), this INSERT would need to be updated. Currently this appears to be by design, but worth confirming.

---

## 8. `PageDao.close()` method exists but no servlet endpoint calls it

**Title:** `PageDao.close()` is defined but appears unreachable from HTTP

**Evidence:**
- `PageDao.java:163-171`: `public void close(long id, long userId)` — sets `is_closed = TRUE`.
- Searched all servlet files: `PageServlet.doPut()` updates `is_closed` via `pageDao.update(existing)` (which takes a full `Page` object including the `closed` field) — the `close()` method on the DAO is not called anywhere.
- The page editor presumably sends `is_closed=true` as part of a full `PUT` update to `PageServlet`.

**Question:** Is `PageDao.close()` dead code that should be removed, or is it reserved for a future endpoint (e.g., a dedicated `POST /app/page/{id}/close` route)?

---

## 9. `UsageDao.incrementAudioMinutes()` is defined but never called

**Title:** Audio-minutes tracking method exists but is unused

**Evidence:**
- `UsageDao.java:45-47`: `public void incrementAudioMinutes(long userId, double minutes)`
- `schema.sql:49`: `audio_minutes_processed DECIMAL(10,2)` column in `usage_tracking`
- `VoiceRecordServlet.java` — calls `usageDao.incrementPages()` and `usageDao.incrementAiJobs()` but never `incrementAudioMinutes()`. No other caller found.
- The audio file duration is not measured anywhere in the codebase.

**Question:** Is audio-minutes tracking a planned but unimplemented feature? If so, where should the duration measurement be added (Whisper output, `audioPart.getSize()` approximation, or explicit duration from `ffprobe`)? If not planned, is `audio_minutes_processed` a dead column?

---

## 10. `PageTagDao.findPagesByTagId()` query omits `sort_order` and `image_layers`

**Title:** Partial `Page` mapping in `findPagesByTagId()` may produce inconsistent objects

**Evidence:**
- `PageTagDao.java:54-57`: SELECT names: `p.id, p.user_id, p.page_type_id, p.title, p.ink_data, p.text_layers, p.is_closed, p.created_at, p.updated_at` — missing `sort_order` and `image_layers`.
- The inline mapping at lines 63-73 does not call `setSortOrder()` or `setImageLayers()`, so returned `Page` objects will have `sortOrder = 0` (Java default) and `imageLayers = null`.
- `PageDao.SELECT_COLUMNS` at line 16 includes both `sort_order` and `image_layers`.

**Question:** Is this method only used in contexts where `sort_order` and `image_layers` are irrelevant (e.g. a tag-to-pages lookup that is purely navigational)? If so, the partial mapping is acceptable. If callers start relying on `imageLayers` from these results, they will silently get null. Worth confirming the usage contract.

---

## 11. `AuthFilter.isPublicPath()` whitelists `/favicon` but no root-level favicon file exists

**Title:** Filter exempts a path that has no corresponding file

**Evidence:**
- `AuthFilter.java:58`: `return path.startsWith("/favicon")` — this exempts `/favicon`, `/favicon.ico`, `/favicon-32.png`, etc.
- The `src/main/webapp/icons/` directory contains `favicon-32.png`, but that is served at `/icons/favicon-32.png`, not `/favicon`.
- No file exists at `src/main/webapp/favicon.ico` or `src/main/webapp/favicon-32.png` (root level).
- `icons/` is not in the `isPublicPath` whitelist.

**Question:** Is `/icons/` accessible to unauthenticated users? The filter does not whitelist `/icons/`. If a browser requests `/icons/favicon-32.png` before a session exists (e.g. from the login page `index.jsp`), it will be redirected to `/login`. The PWA manifest references `/icons/icon-maskable-512.png` with no path prefix, which would fail the same way. This may or may not matter depending on how `index.jsp` references the icons.

---

## 12. `JYRNYL_PRODUCT_SUMMARY.md` and `JYRNYL_PRODUCT_SUMMARY_v2.md` both exist with no clear deprecation marker

**Title:** Two product summary files with no indication which is current

**Evidence:**
- `JYRNYL_PRODUCT_SUMMARY.md` — last modified 2026-04-15
- `JYRNYL_PRODUCT_SUMMARY_v2.md` — last modified 2026-04-16
- `CLAUDE.md` — does not reference either file; designates only `JOTPAGE_FULL_PROJECT_DOC.md` as authoritative.
- Neither file contains a header marking it as superseded or current.

**Question:** Is `JYRNYL_PRODUCT_SUMMARY.md` superseded by v2? Should the older file be removed or renamed to make the status clear?

---

## 13. `sw.js` pre-caches URLs with no leading context path — may fail on local dev

**Title:** Service worker pre-cache URLs assume root context

**Evidence:**
- `sw.js:25-31`: `PRECACHE_URLS = ['/offline.html', '/css/theme.css', '/manifest.webmanifest', '/images/jyrnyl-logo-square.svg', '/images/jyrnyl-logo-400.png']`
- Production deploys at root context (`/`), so these paths are correct in prod.
- Local IntelliJ dev runs the WAR at `/jotpage/` context path (per `user_workstation.md` and the OAuth redirect URI `http://localhost:8080/jotpage/oauth2callback`).
- On local dev, `/offline.html` would resolve to the Tomcat root, not the app.

**Question:** Does the service worker work correctly on local dev? If not, this is a local-only issue and acceptable if local dev always uses the app without offline mode. If it matters, the SW would need dynamic `self.registration.scope` detection. Worth noting so future developers don't investigate the discrepancy.

---

## 14. `VoiceRecordServlet` marks an AI job as `processing` before Whisper completes, then `complete` or `failed` after

**Title:** `ai_jobs` status does not reflect Whisper transcription as a distinct phase

**Evidence:**
- `VoiceRecordServlet.java:200-216`: job is created with `status = "processing"` before either Whisper or Claude runs.
- `VoiceRecordServlet.java:341`: `aiJobDao.updateStatus(job.getId(), "complete", outputText, null)` — set only after page creation succeeds.
- `AiJob.status ENUM`: `pending, processing, complete, failed` — no `transcribing` state.
- `AiJobDao.countByUserIdAndJobType()` at line 90 counts statuses `complete` and `processing` for trial enforcement.

**Question:** If Whisper succeeds but Claude fails (Claude API error), the job ends up `failed` with an error message, which is correct. However, if the server restarts mid-job, the job will be stuck in `processing` forever with no cleanup. Is this an acceptable risk at the current traffic level, or should a stuck-job recovery be added?

---

## 15. `JOTPAGE_FULL_PROJECT_DOC.md` title still says "JotPage" despite rebranding

**Title:** Authoritative documentation file has pre-rebrand title

**Evidence:**
- `JOTPAGE_FULL_PROJECT_DOC.md:1`: `# JotPage — Full Project Documentation`
- `JOTPAGE_FULL_PROJECT_DOC.md:4`: "JotPage is a digital notebook web application…"
- The application is publicly branded as "Jyrnyl" (`web.xml:8`, `manifest.webmanifest:2`, `OAuthCallbackServlet.java:26`).

**Question:** The file name `JOTPAGE_FULL_PROJECT_DOC.md` and the title "JotPage" inside it are both pre-rebrand. Is this a documentation inconsistency worth resolving, or is the internal/repo name intentionally kept as "jotpage" (matching the Maven artifactId and DB name)?

---

*End of open questions — 15 items total.*

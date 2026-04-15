# JotPage — Full Project Documentation

## Overview
JotPage is a digital notebook web application built on Java 17 / Jakarta Servlet 6.0 / Apache Tomcat 10. It provides an HTML5 Canvas drawing surface at A5 ratio (148:210), voice-to-page transcription via Whisper + Claude AI, and a warm Moleskine/journal-themed UI.

## Tech Stack
- **Backend:** Java 17, Jakarta Servlet 6.0, Apache Tomcat 10
- **Database:** MySQL 8 (mysql-connector-j 8.3.0)
- **Build:** Maven (WAR packaging)
- **Auth:** Google OAuth 2.0 (google-api-client 2.7.0, google-oauth-client-jetty 1.36.0)
- **AI:** Anthropic Claude API (claude-sonnet-4-20250514 via java.net.HttpURLConnection)
- **Speech:** OpenAI Whisper CLI (subprocess via ProcessBuilder)
- **Frontend:** JSP, Bootstrap 5, Bootstrap Icons, Google Fonts (Playfair Display + Source Sans 3), vanilla JS
- **No Spring, No JPA** — plain servlets + JDBC throughout

## Repository
- **GitHub:** https://github.com/Murphnd2/jotpage
- **Branch:** main

## Project Structure
```
jotpage/
├── pom.xml
├── SETUP.md                          # Original bootstrap instructions
├── .gitignore                        # Excludes secrets, IDE, build output
├── src/main/java/com/jotpage/
│   ├── model/
│   │   ├── User.java                 # id, googleId, email, displayName, avatarUrl, tier
│   │   ├── Page.java                 # id, userId, pageTypeId, sortOrder, inkData, textLayers, closed
│   │   ├── PageType.java             # id, userId, name, backgroundType, backgroundData, immutableOnClose, system
│   │   ├── Tag.java                  # id, userId, name, color
│   │   ├── PageTag.java              # pageId, tagId
│   │   ├── Subscription.java         # id, userId, tier, stripeCustomerId, stripeSubscriptionId, expiresAt
│   │   ├── AiJob.java                # id, userId, jobType, status, inputText, outputText, audioFilePath, customPrompt, errorMessage
│   │   └── UsageRecord.java          # id, userId, monthYear, pagesCreated, aiJobsRun, audioMinutesProcessed
│   ├── dao/
│   │   ├── UserDao.java              # findByGoogleId, createOrUpdate, updateTier
│   │   ├── PageDao.java              # findById, findByUserId, create, update, reorder, close, delete
│   │   ├── PageTypeDao.java          # findSystemTypes, findByUserId, findById, create, delete (with TemplateInUseException)
│   │   ├── TagDao.java               # findByUserId, create, delete
│   │   ├── PageTagDao.java           # addTag, removeTag, findTagsByPageId, findPagesByTagId
│   │   ├── SubscriptionDao.java      # findByUserId, createOrUpdate, isProUser
│   │   ├── AiJobDao.java             # create, findById, updateStatus, findByUserId
│   │   ├── UsageDao.java             # findOrCreateCurrentMonth, incrementPages, incrementAiJobs, incrementAudioMinutes
│   │   └── TemplateInUseException.java  # RuntimeException for FK violation on page_types delete
│   ├── servlet/
│   │   ├── AuthFilter.java           # Jakarta filter on /app/*, session-based auth
│   │   ├── LoginServlet.java         # GET /login → Google OAuth redirect
│   │   ├── OAuthCallbackServlet.java # GET /oauth2callback → token exchange → session
│   │   ├── LogoutServlet.java        # GET /logout → invalidate session
│   │   ├── DashboardServlet.java     # GET /app/dashboard → book or list view
│   │   ├── PageServlet.java          # GET/PUT /app/page/* → editor, save, reorder
│   │   ├── PageTypeServlet.java      # GET/POST/DELETE /app/api/pagetypes/* (multipart upload for custom PNG)
│   │   ├── PageThumbnailServlet.java # GET /app/api/page-thumbnail/{id} → JSON for book-view rendering
│   │   ├── TagServlet.java           # GET/POST/DELETE /app/api/tags/*
│   │   ├── PageTagServlet.java       # GET/POST/DELETE /app/api/page-tags/*
│   │   └── VoiceRecordServlet.java   # GET/POST /app/voice-record (multipart, full AI pipeline)
│   └── util/
│       ├── AppConfig.java            # Singleton properties loader (3-step lookup)
│       ├── DbUtil.java               # MysqlDataSource from AppConfig (no JNDI)
│       ├── TierCheck.java            # Feature gating: free vs pro tier
│       ├── WhisperService.java       # Whisper CLI subprocess with FFmpeg PATH injection
│       ├── ClaudeService.java        # Anthropic Messages API via HttpURLConnection
│       └── PageSplitter.java         # Text → page-sized chunks with POINT_TO_PIXEL scaling
├── src/main/resources/
│   ├── schema.sql                    # Full schema for fresh installs (9 tables + 4 system page types)
│   ├── jotpage.properties.example    # Template with all config keys (safe to commit)
│   └── migrations/
│       ├── 001_add_page_sort_order.sql
│       ├── 002_ai_pipeline_and_tiers.sql
│       └── 003_remove_calendar_templates.sql
├── src/main/webapp/
│   ├── index.jsp                     # Login page (centered card, warm styling)
│   ├── css/
│   │   └── theme.css                 # Shared warm Moleskine theme (CSS vars, Bootstrap overrides)
│   ├── js/
│   │   ├── ink-engine.js             # Canvas drawing engine (pen, eraser, text blocks, undo/redo)
│   │   ├── book-view.js              # Dashboard book view (spreads, thumbnails, swipe, cover)
│   │   ├── tablet-mode.js            # Tablet immersive mode (FAB, panel, auto-save, swipe nav)
│   │   └── voice-recorder.js         # Voice entry client (MediaRecorder, SpeechRecognition, upload)
│   ├── jsp/
│   │   ├── dashboard.jsp             # Notebook dashboard (book view default, list view alternate)
│   │   ├── editor.jsp                # Canvas editor (navbar, toolbar, tag bar, tablet immersive)
│   │   └── voice-record.jsp          # Voice entry page (record/upload tabs, mode selector)
│   ├── WEB-INF/
│   │   └── web.xml                   # Servlet/filter mappings only (no secrets)
│   └── META-INF/
│       └── context.xml               # Empty <Context/> (DB config moved to properties file)
```

## Configuration / Secrets Management

All secrets are externalized to a `jotpage.properties` file that lives OUTSIDE the WAR and is NOT checked into Git.

### Properties file format
```properties
# Google OAuth
google.clientId=...
google.clientSecret=...
google.redirectUri=...

# Database
db.url=jdbc:mysql://127.0.0.1:3306/jotpage?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
db.username=...
db.password=...
db.driverClassName=com.mysql.cj.jdbc.Driver
db.maxTotal=20
db.maxIdle=10
db.maxWaitMillis=10000

# Whisper
whisper.command=whisper
whisper.model=base
ffmpeg.path=           # empty on Linux (on PATH), set to e.g. C:\\ffmpeg\\bin on Windows

# Anthropic
anthropic.apiKey=...
```

### Lookup order (AppConfig.java)
1. System property: `-Djotpage.config=/custom/path/jotpage.properties`
2. Fallback: `{catalina.base}/conf/jotpage.properties`
3. Fallback: classpath `jotpage.properties` (for tests)

### Environment-specific files

| Environment | Path | How resolved |
|---|---|---|
| Local dev (Windows) | `C:\ssa\jotpage.properties` | `-Djotpage.config=C:\ssa\jotpage.properties` in IntelliJ VM options |
| Production (Linux) | `/var/lib/tomcat10/conf/jotpage.properties` | Auto via `{catalina.base}/conf/` |

### Key differences between environments
- `google.redirectUri`: `http://localhost:8080/jotpage/oauth2callback` (local, WAR still deploys at `/jotpage/` on dev) vs `https://jyrnyl.com/oauth2callback` (prod, deployed as ROOT)
- `db.username`: `root` (local) vs `jotpage` (prod)
- `ffmpeg.path`: `C:\\ffmpeg\\bin` (local Windows) vs empty (prod Linux, ffmpeg on PATH)
- `whisper.command`: `whisper` (local, on PATH) vs `/usr/local/bin/whisper` (prod, symlink to venv binary)

## Database

### MySQL access

**Local dev:**
```bash
mysql -u root -p
# password: Passw0rd!
```

**Production:**
```bash
LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu mysql --socket=/var/run/mysqld/mysqld.sock -u jotpage -p
```

### Schema
- 9 tables: `users`, `user_subscriptions`, `ai_jobs`, `usage_tracking`, `page_types`, `pages`, `tags`, `page_tags`
- 4 system page types: Blank, Lined, Dot Grid, Graph
- Calendar/schedule templates removed (migration 003)
- `page_types.background_type` ENUM still includes legacy values for backward compat

### Fresh install
```bash
mysql -u root -p < src/main/resources/schema.sql
```

### Upgrading existing DB
Run migrations in order:
```bash
mysql -u root -p jotpage < src/main/resources/migrations/001_add_page_sort_order.sql
mysql -u root -p jotpage < src/main/resources/migrations/002_ai_pipeline_and_tiers.sql
mysql -u root -p jotpage < src/main/resources/migrations/003_remove_calendar_templates.sql
```

## Production Server

- **Host:** jyrnyl.com
- **Origin IP:** 66.179.248.54 (IONOS DCD VPS, Ubuntu 24.04 LTS)
- **URL:** https://jyrnyl.com/ (deployed as ROOT context — no `/jotpage/` path prefix)
- **DNS/TLS:** Cloudflare proxied (orange cloud), SSL mode **Full (Strict)** with a Cloudflare Origin Certificate installed on the box
- **Reverse proxy:** nginx 1.24 terminates TLS and proxies to Tomcat on `127.0.0.1:8080`
  - Config: `/etc/nginx/sites-available/jyrnyl`
  - Origin cert: `/etc/nginx/ssl/jyrnyl.crt` (15-year Cloudflare cert for `*.jyrnyl.com` + `jyrnyl.com`)
  - Origin key:  `/etc/nginx/ssl/jyrnyl.key` (mode 600)
- **Tomcat:** 10.1.16 (Ubuntu package), CATALINA_BASE=`/var/lib/tomcat10`, CATALINA_HOME=`/usr/share/tomcat10`
  - WAR deployed as `/var/lib/tomcat10/webapps/ROOT.war` (context path `/`)
  - JAVA_OPTS set in `/etc/default/tomcat10`: `-Xms256m -Xmx1024m -XX:+UseG1GC`
- **Java:** OpenJDK 17 at `/usr/lib/jvm/java-17-openjdk-amd64`
- **MySQL 8** (Ubuntu package)
  - Socket: `/var/run/mysqld/mysqld.sock`
  - App user: `jotpage@localhost` (scoped to `jotpage` DB only)
  - Root: `auth_socket` (no password — OS `root` user authenticates via socket)
- **Whisper:** venv at `/opt/whisper/venv` (owned by `deploy`), binary symlinked to `/usr/local/bin/whisper`
  - Tomcat-user model cache pre-populated at `/var/lib/tomcat/.cache/whisper/base.pt`
- **FFmpeg:** `/usr/bin/ffmpeg` (system package, on PATH)
- **Firewall (UFW):** allow 22/80/443, deny everything else
- **Timezone:** America/Chicago
- **User accounts:**
  - `root` — initial setup only, password-only SSH disabled in favor of key-based
  - `deploy` — sudoer, handles all day-to-day ops and scp target
  - `tomcat` — app runtime (home `/var/lib/tomcat`, shell nologin)
- **SSH requires:** `LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu` prefix for `mysql`/`mysqldump` commands (Ubuntu 24.04 ships an ABI that trips the MySQL client without this)

## Deploy Process

Build locally, scp, drop into Tomcat webapps dir as `ROOT.war`:

```bash
# On Windows workstation
cd C:\Users\kevinmurphy.SUPERIORSTATE\IdeaProjects\jotpage
mvn clean package
scp target\jotpage.war deploy@66.179.248.54:/home/deploy/jyrnyl/

# On server (deploy user)
sudo cp /home/deploy/jyrnyl/jotpage.war /var/lib/tomcat10/webapps/ROOT.war
sudo chown tomcat:tomcat /var/lib/tomcat10/webapps/ROOT.war
# Tomcat auto-redeploys in ~1s; no restart required
```

Watch logs during deploy:
```bash
sudo journalctl -u tomcat10 -f --since "30 seconds ago"
```

After deploy, users may need a hard-refresh (Ctrl+Shift+R) once — the service worker bumps its cache version on each release so most users pick up changes automatically on next visit.

### Note on the WAR artifact name
`pom.xml` still builds `jotpage.war`; it's renamed to `ROOT.war` at deploy time. If that becomes annoying, change the `<finalName>` in `pom.xml` to `ROOT`.

## Canvas / Drawing Engine

### Internal resolution
- Canvas: 1480 × 2100 pixels (A5 at 10× resolution: 148mm × 210mm)
- 1 real-world point = 10 canvas pixels (`POINT_TO_PIXEL = 10`)
- Font sizes in UI dropdowns are real-world points (2, 4, 6, 8, 10, 12, 14, 16, 18, 24, 32, 48, 64)
- Stored `fontSize` in text_layers JSON is always in canvas pixels (UI value × 10)

### Ink data model
- Strokes: `{ points: [{x, y, pressure}], color: "#000000", thickness: 3 }`
- Text blocks: `{ id, x, y, text, fontSize, color, width, height }`
- Both stored as JSON in MySQL columns (`ink_data`, `text_layers`)

### Background types
- blank (white), lined (horizontal rules), dot_grid (dot pattern), graph (square grid), custom (PNG base64)
- Graph: warm gray (#d4c9bc), 3px line width, 40px grid spacing
- Custom: PNG uploaded by user, stored as base64 in `page_types.background_data`

### Editor features
- Pen tool (pressure-sensitive via Pointer Events API)
- Eraser tool (stroke-level hit testing)
- Text tool (contenteditable overlays, drag handle, resize handle)
- Font size control (2–64pt range, shown only when text block selected)
- Color picker, thickness slider (1–20)
- Undo/redo (stroke-level history, Ctrl+Z / Ctrl+Y)
- Save (PUT /app/page/{id}), Ctrl+S shortcut
- Tags (add/remove via API, popover UI)
- Prev/Next page navigation (preserves ?tags= filter and ?immersive=1 mode)

### Tablet immersive mode (tablet-mode.js)
- Auto-activates on `(pointer: coarse) and (min-width: 768px)`, or via toggle button, or `?immersive=1` URL param
- Canvas fills 100dvh × 100dvw
- Floating toolbar pill (auto-hides after 5s of drawing, reappears on pen lift)
- FAB (top-right) opens slide-out panel with reparented navbar + tag bar
- Auto-save every 30s if dirty
- "Saved" flash toast near FAB (via MutationObserver on #save-status)
- Two-finger swipe: left=next, right=prev (calls inkEngine.cancelStroke() to abort any single-finger stroke)
- Browser gesture prevention: touch-action:none, overscroll-behavior:none, contextmenu blocked
- Prev/next hrefs rewritten with &immersive=1 to preserve mode across page flips

### External API (ink-engine.js → window.inkEngine)
- `cancelStroke()` — aborts in-progress stroke without committing to strokes array

## Dashboard

### Views
- **Book view** (default): two-page spread layout, leather desk background, animated cover
  - Lazy-fetches ink data via `/app/api/page-thumbnail/{id}`
  - Renders miniature text preview (word-wrapped) or skeleton placeholder
  - "Add Page" slot after last real page, opens template chooser modal
  - Cover-only mode: hides left page, centers cover on right
  - Keyboard arrows, touch swipe, prev/next buttons
  - Tag filter (union/OR semantics)
- **List view**: vertical notebook list with CSS page-type thumbnails
  - Drag-to-reorder (HTML5 DnD, POST to /app/page/reorder)
  - Tag filter with "Showing X of Y pages" counter
- View toggle in header preserves ?tags= param
- Tag filter state restored from URL ?tags= on page load
- Voice Entry button links to /app/voice-record

### New Page modal
- Lists system + user custom templates
- Custom template creation: name + PNG upload (multipart, max 5MB, PNG magic-number validation)
- Delete button on user-owned templates (409 if pages still reference it)

## Voice Entry Pipeline

### Flow
1. User records audio (MediaRecorder + SpeechRecognition) or uploads a file (MP3/WAV/WebM/M4A/OGG/FLAC, max 25MB)
2. Client sends multipart POST to /app/voice-record
3. Server runs Whisper transcription (any tier, any audio file)
4. For non-verbatim modes (Pro only): runs Claude AI processing
5. PageSplitter splits output into page-sized chunks
6. Creates Page records with text block overlays
7. Applies selected tags
8. Tracks usage in ai_jobs + usage_tracking tables

### Processing modes
- **Verbatim** (free): straight transcription, no AI
- **Study Notes** (pro): organized notes with headers + key concepts
- **Meeting Minutes** (pro): action items, decisions, next steps
- **Journal Entry** (pro): reflective first-person writing
- **Outline** (pro): structured topic outline
- **Custom** (pro): user-provided prompt

### Tier system
- Free: Month 1 unlimited, then 20 pages/month, deletion allowed, verbatim mode only, system templates only, up to 5 custom templates
- Pro: unlimited pages, all AI modes, custom templates, Whisper transcription
- "Month 1" = the calendar month the user's account was created (`user.created_at` year+month matches the current year+month)
- Page-creation gating uses `TierCheck.canCreatePage(user, pagesThisMonth)` against `usage_tracking.pages_created` for the current month
- Page deletion is allowed on ALL tiers
- Checked via `TierCheck.java` (reads `user.tier` from session)
- Usage tracked monthly in `usage_tracking` table

### Whisper integration
- `WhisperService.java` runs CLI: `whisper <file> --model base --output_format txt --output_dir <tmp> --language en`
- FFmpeg PATH injection: `ffmpeg.path` from properties prepended to child process PATH
- 5-minute timeout, stderr capture, temp file cleanup
- Falls back to browser transcript on Whisper failure

### Claude integration
- `ClaudeService.java` POSTs to `https://api.anthropic.com/v1/messages`
- Model: claude-sonnet-4-20250514, max_tokens: 4096
- System prompts per job type (hardcoded in ClaudeService)
- 30s connect / 120s read timeout
- Single `sendRequest()` method for LLM swappability

## Styling / Theme

### Color palette (theme.css)
- Background: warm cream (#faf6f0)
- Cards: off-white (#fffdf9)
- Primary accent: deep warm brown (#5c4033)
- Secondary accent: muted gold (#c9a84c)
- Text: dark warm brown (#3b2f2f)
- Muted text: warm gray (#8a7e74)
- Borders: subtle warm gray (#e8dfd0)

### Typography
- Headings: Playfair Display (serif)
- Body/UI: Source Sans 3 (sans-serif)
- All loaded from Google Fonts CDN

### Design principles
- Moleskine/leather-bound journal aesthetic
- Tactile warm shadows, subtle paper textures
- No Bootstrap primary blue — overridden everywhere with warm palette
- 44px+ touch targets throughout
- Responsive: desktop two-column, mobile single-column

## Brand Identity

### Name & tagline
- **Name:** Jyrnyl (pronounced "Journal")
- **Tagline:** Record your life.
- **Pitch:** Your personal liner notes. Drop the needle on a new thought.

### Brand assets
All in `src/main/webapp/images/`:
- `jyrnyl-logo-square.svg` — vinyl record with J label, pen/needle, "JYRNYL / RECORD YOUR LIFE" (800×800 source, SVG scales to any size). **Used as the primary logo in:** login page (120px), offline page (96px), navbar-brand (28px via CSS background-image), SVG favicon, manifest icon.
- `jyrnyl-logo-800.png`, `jyrnyl-logo-400.png` — raster fallbacks for older clients / manifest icons.
- `jyrnyl-banner.svg`, `jyrnyl-banner-1500.png` — 1500×500 wordmark banner (record on left, wordmark on right). Not yet used in-app; reserved for marketing/social.

### Vinyl metaphor vocabulary
This is the user-facing language; apply consistently in any new UI copy.

| Term | Meaning | Where it appears |
|---|---|---|
| Drop the needle | Start a new entry / CTA | Login footer, dashboard subhead |
| Track | A single page | Add-page placeholder ("Drop a new track") |
| Liner notes | Journal entries / the words on a page | Login subtitle, manifest description |
| Album | The user's full journal | Editor back-button: "Back to your Jyrnyl" |
| B-side | Private / locked pages (future) | Not yet in UI |
| Studio | The editor / canvas workspace | Editor `<title>` |
| Voice Booth | The voice-recording page | Voice-record `<title>` and heading |
| Press it to vinyl | Transcribe + save voice entry | Voice-record subhead |

### Non-user-facing vs user-facing
Do NOT rename Java packages, servlet mappings, DB columns, or any internal identifier. The repo name, package name, and WAR artifact all remain `jotpage` — this is a cosmetic/brand layer on top, not a code rename.

## Known issues / TODOs
- [x] ~~Deploy latest WAR to production~~ — done (Jyrnyl live on jyrnyl.com at 66.179.248.54 as of 2026-04-15)
- [x] ~~Test Google OAuth on production after deploy~~ — working
- [ ] Rotate production secrets exposed during chat setup (Google client secret, Anthropic API key, MySQL `jotpage` password)
- [ ] Stripe integration for Pro tier (subscription table exists, no webhook handler yet)
- [ ] Automated DB backups (cron `mysqldump` → `/home/deploy/backups/` with retention)
- [ ] Uptime monitoring / alerting (no external check configured yet)
- [ ] Book view thumbnails for custom-background pages show blank (no base64 in dashboard payload)
- [ ] Pre-scale-fix voice pages have tiny fontSize in DB (legacy compat handles display, but editing shows wrong dropdown selection)
- [ ] Touch drag-to-reorder in list view (HTML5 DnD doesn't support touch natively)

# Jyrnyl — Product Summary

*Pronounced "Journal." A warm, tactile digital notebook with a vinyl/liner-notes soul.*

---

## 1. Product Overview

**Jyrnyl** is a browser-native digital notebook that blends handwritten drawing, typed text, image overlays, and AI-powered voice transcription on a genuine A5 page canvas — wrapped in a warm Moleskine-meets-vinyl aesthetic and delivered as an installable Progressive Web App. It is built for modern journalers, students, knowledge workers, and tablet-first creatives who want the tactile feel of a leather-bound notebook with the convenience of cloud sync, Google sign-on, and the ability to dictate an entry and have Claude AI reshape it into study notes, meeting minutes, or journal prose. Unlike generic note apps, Jyrnyl renders a proper two-page book-spread dashboard (with a real animated cover), treats each page as a standalone A5 artifact (148×210 mm at 10× resolution), preserves pressure-sensitive stylus ink, and has a first-class tablet immersive mode with two-finger page-flip gestures — all built on a lean Java 17 / Servlet 6.0 / MySQL 8 stack with no client framework dependencies.

---

## 2. Complete Feature Inventory

### Canvas / Drawing

- **Pressure-sensitive pen tool** (`ink-engine.js`) — reads `e.pressure` from the Pointer Events API; stores `{x, y, pressure}` per point.
- **Variable thickness slider (1–20 px)** — paired with the pen, persists per-stroke.
- **Color picker** — native `<input type="color">`, applies to pen strokes and selected text blocks.
- **Stroke-level eraser** — hit-tests whole strokes (not pixels) and removes them cleanly.
- **Text blocks** — contenteditable overlays positioned freely on the page; drag handle, resize handle, delete button; retain font size, color, width, height.
- **Font size dropdown (2, 4, 6, 8, 10, 12, 14, 16, 18, 24, 32, 48, 64 pt)** — real-world point sizes; internally scaled via `POINT_TO_PIXEL = 10`.
- **Image overlay tool** — add PNG/JPEG images (≤ 5 MB) with draggable move handle, resize handle, and delete button; stored as base64 in `image_layers` JSON.
- **Undo / redo** — stroke-level history, `Ctrl+Z` / `Ctrl+Y` (Shift+Ctrl+Z also works).
- **Save** — `PUT /app/page/{id}` with `inkData`, `textLayers`, `imageLayers`; `Ctrl+S` shortcut; status flashes "Saving... / Saved / Error / Locked" in the navbar.
- **Background page types (system)** — Blank (white), Lined (horizontal rules), Dot Grid (dot pattern), Graph (warm-gray 40 px grid, 3 px line).
- **Custom PNG backgrounds** — user-uploaded templates stored base64 on `page_types.background_data` and rendered behind the ink layer.
- **Locked / closed pages** — immutable-on-close templates flip pages into read-only mode; save returns 423 Locked.
- **Navigation buttons** — First, Prev, Next, Last with disabled state when at bounds; preserve `?tags=` filter and `?immersive=1` param.
- **Delete page** — trash button in navbar; locked pages require typing `DELETE` as a confirmation phrase before destruction.

### Templates

- **System templates** — Blank, Lined, Dot Grid, Graph, always available.
- **User custom templates** — upload any PNG (max 5 MB) with PNG magic-number validation server-side.
- **Immutable-on-close flag** — per-template switch so finished pages lock automatically.
- **Template chooser modal** — grid layout, live preview, inline creation form with drop zone, upload progress.
- **In-use protection** — deleting a template that still has referenced pages returns 409 with `TemplateInUseException`.

### Voice & AI

- **In-browser recording** — `MediaRecorder` with `audio/webm;codecs=opus` preference, `getUserMedia` permission, circular pulsing record button, elapsed-time readout (mm:ss).
- **Live interim transcript** — `SpeechRecognition` / `webkitSpeechRecognition` API prints partial text into a live box while you speak (fallback if Whisper fails).
- **Audio upload tab** — drag-drop or file picker; accepts `.mp3`, `.wav`, `.webm`, `.m4a`, `.ogg`, `.flac`; max 25 MB; shows filename + size.
- **Whisper transcription** — server subprocess (`WhisperService.java`) runs `whisper <file> --model base --output_format txt --language en` with FFmpeg PATH injection and 5-minute timeout.
- **Processing modes** (`ClaudeService.java`, Claude Sonnet 4):
  - **Verbatim** — straight transcript, page-split (free tier).
  - **Study Notes** — organized headings and key concepts (Pro).
  - **Meeting Minutes** — action items, decisions, next steps (Pro).
  - **Journal Entry** — reflective first-person prose (Pro).
  - **Outline** — structured hierarchical topics/subtopics (Pro).
  - **Custom** — user supplies their own instructions (Pro).
- **Page splitter** (`PageSplitter.java`) — wraps AI output into A5-sized chunks using font-size-aware geometry (chars/line = 1380 / (pt × 6), lines/page = 2000 / (pt × 15)); respects newlines; never splits mid-word.
- **AI job tracking** — every run persisted to `ai_jobs` table with input, output, status, error.
- **Usage metering** — `usage_tracking` table records `pagesCreated`, `aiJobsRun`, `audioMinutesProcessed` per user per month.
- **Free-tier AI trial** — 1 trial per non-verbatim mode before Pro gating kicks in.
- **Progress overlay** — two-phase indicator ("Transcribing… / Processing… / Creating pages…") during server pipeline.
- **Editable transcript** — users can tweak the Whisper output before submitting for AI processing.
- **Per-entry font size + tag selection** — applied to every page produced from the voice run.

### Organization

- **Tags** — full CRUD, user-scoped, color-picked (`#hex`), up to 100 chars.
- **Page-tag associations** — attach/detach tags via popover on the editor, checkbox list on voice entry, badges in both dashboard views.
- **Tag filter** — clickable chip bar on dashboard; OR/union semantics; "Showing X of Y pages" counter.
- **Manage Tags modal** — rename, recolor, delete; in-use tags prompt a "strip from all pages" or "replace with another tag" choice.
- **Page locking / closed flag** — closed pages badge "Closed" on thumbnails; locked ones refuse edits and require confirmation to delete.

### Navigation

- **Dashboard book view** (default) — animated two-page spread, leather desk background, cover page, "Add Page" placeholder slot, keyboard arrows (`←`/`→`/`Home`/`End`), touch swipe, lazy-fetched thumbnails via `/app/api/page-thumbnail/{id}`.
- **Dashboard list view** — vertical notebook-entry rows with CSS page-type mini-thumbnails, "tape strip" flourish, creation date, template name, tag chips, entry order, hover-reveal delete button.
- **View toggle** — book/list switcher in header; preserves active tag filter.
- **Reorder mode** (list view) — HTML5 drag-and-drop on page rows; POST to `/app/page/reorder`.
- **First / Prev / Next / Last** — chevron navigation in both dashboard book view and the editor navbar.
- **URL-driven state** — tag filter (`?tags=1,3,7`), view mode (`?view=book|list`), immersive mode (`?immersive=1`) all round-trip through navigation.

### Tablet Mode

- **Auto-activation** — CSS media query `(pointer: coarse) and (min-width: 768px)` triggers immersive mode; manual toggle via navbar button; URL param survives page flips.
- **Full-viewport canvas** — 100 dvh × 100 dvw with pages shown edge-to-edge on iPad-size devices.
- **Floating toolbar pill** — auto-hides after 5 s of drawing, reappears on pen lift or tap.
- **FAB menu** — top-right floating action button (three-dot icon) opens a slide-out drawer that reparents the navbar + tag bar.
- **Auto-save every 30 s** when dirty; "Saved" toast flashes near the FAB.
- **Two-finger swipe navigation** — left = next page, right = prev; calls `inkEngine.cancelStroke()` so a single-finger ink stroke is cleanly aborted when the second finger lands.
- **Browser-gesture suppression** — `touch-action: none`, `overscroll-behavior: none`, `contextmenu` blocked.
- **Immersive-preserving links** — `?immersive=1` appended to prev/next/first/last hrefs so mode survives page flips.
- **Hot-edge toolbar reveal** — tapping the bottom edge brings the toolbar back during drawing sessions.

### Account & Auth

- **Google OAuth 2.0** — single sign-on only; no passwords ever stored; uses `google-api-client 2.7.0` + `google-oauth-client-jetty 1.36.0`.
- **Session-based auth** — `AuthFilter.java` enforces login on `/app/*`; redirects unauthenticated users to the login page.
- **User profile** — Google-supplied display name + avatar shown in dashboard navbar.
- **Tier tracking** — `user.tier` column + `user_subscriptions` table with Stripe customer/subscription IDs scaffolded.
- **Properties-based Pro override** — `pro.emails=a@x,b@y` in `jotpage.properties` grants Pro to listed addresses without a DB flag (handy for founders/testers).
- **Logout** — invalidates session; returns to login page.
- **PWA install** — `manifest.webmanifest` with 192/512/maskable icons, shortcut links to "New page" and "Voice record," cream-and-brown theme colors.
- **Offline fallback page** (`offline.html`) — service worker serves a branded "You're offline" card with reload button when the network is unreachable.
- **Service worker** (`sw.js`) — network-first for navigations (with offline fallback), stale-while-revalidate for static assets, never-cache for `/login`, `/logout`, `/oauth2callback`, `/api/*`. `NoCacheFilter` forces the browser to always re-fetch `sw.js` and `manifest.webmanifest`.

---

## 3. Tier Feature Matrix

Source of truth: `src/main/java/com/jotpage/util/TierCheck.java`.

| Feature | Free | Pro | Pro+ (future) |
|---|---|---|---|
| Google OAuth sign-in | ✅ Included | ✅ Included | ✅ Included |
| Page creation | ⚠ Month 1 unlimited, then 20 pages / calendar month | ✅ Unlimited | ✅ Unlimited |
| System templates (Blank / Lined / Dot Grid / Graph) | ✅ Included | ✅ Included | ✅ Included |
| Custom PNG templates | ⚠ Limited to 5 templates | ✅ Unlimited | ✅ Unlimited |
| Pen, eraser, text, image overlay | ✅ Included | ✅ Included | ✅ Included |
| Undo / redo | ✅ Included | ✅ Included | ✅ Included |
| Tags (unlimited) | ✅ Included | ✅ Included | ✅ Included |
| Book view / list view | ✅ Included | ✅ Included | ✅ Included |
| Tablet immersive mode | ✅ Included | ✅ Included | ✅ Included |
| Drag-to-reorder (list view) | ✅ Included | ✅ Included | ✅ Included |
| PWA install + offline shell | ✅ Included | ✅ Included | ✅ Included |
| Voice recording + browser transcript | ✅ Included | ✅ Included | ✅ Included |
| Audio upload (MP3/WAV/WebM/M4A/OGG/FLAC, ≤ 25 MB) | ✅ Included | ✅ Included | ✅ Included |
| Whisper server-side transcription | 🔒 Locked | ✅ Unlimited | ✅ Unlimited |
| Verbatim voice-to-pages | ✅ Included | ✅ Unlimited | ✅ Unlimited |
| Study Notes AI mode | ⚠ 1 free trial | ✅ Unlimited | ✅ Unlimited |
| Meeting Minutes AI mode | ⚠ 1 free trial | ✅ Unlimited | ✅ Unlimited |
| Journal Entry AI mode | ⚠ 1 free trial | ✅ Unlimited | ✅ Unlimited |
| Outline AI mode | ⚠ 1 free trial | ✅ Unlimited | ✅ Unlimited |
| Custom AI prompt mode | ⚠ 1 free trial | ✅ Unlimited | ✅ Unlimited |
| Delete pages | ✅ Included | ✅ Included | ✅ Included |
| Export / download pages | 🔒 Locked (scaffolded, not yet implemented) | 🔜 Planned | ✅ Included |
| Stripe subscription billing | — | 🔜 Planned | 🔜 Planned |
| Collaborative shared notebooks | — | — | 🔜 Planned |
| Native apps (iOS / Android / desktop) | — | — | 🔜 Planned |
| Handwriting-to-text OCR | — | — | 🔜 Planned |
| End-to-end encrypted notebooks | — | — | 🔜 Planned |

**Legend:** ✅ Included · ⚠ Limited · 🔒 Locked · 🔜 Planned · — Not offered.

---

## 4. Technical Specs

### Canvas

- **Internal resolution:** 1480 × 2100 pixels (A5 at 10×: 148 mm × 210 mm).
- **Coordinate scale:** `POINT_TO_PIXEL = 10` — one real-world point = 10 canvas pixels; single source of truth shared between `ink-engine.js`, `editor.jsp`, `voice-record.jsp`, and `PageSplitter.java`.
- **Usable text area:** 1380 × 2000 pixels (50 px margins on all sides).
- **Font sizes (UI dropdown):** 2, 4, 6, 8, 10, 12, 14, 16, 18, 24, 32, 48, 64 pt.
- **Pointer Events API** for pressure-sensitive input; works with Apple Pencil, Surface Pen, Wacom, capacitive stylus, and finger.
- **Ink data format:** `{ strokes: [{ points: [{x,y,pressure}], color, thickness }] }` — JSON in MySQL.
- **Text layer format:** `{ id, x, y, text, fontSize (canvas px), color, width, height }`.
- **Image layer format:** `{ id, x, y, width, height, src (data:image/… base64) }`.
- **Max image overlay size:** 5 MB per image; scaled to ~40 % canvas width on insert with aspect preserved.

### Audio

- **Supported upload formats:** MP3, WAV, WebM, M4A, OGG, FLAC.
- **Max upload size:** 25 MB (servlet `maxFileSize = 26,214,400`; `maxRequestSize = 27,262,976`).
- **Browser recording:** `MediaRecorder` preferring `audio/webm;codecs=opus`, falling back to default.
- **Live interim transcript:** Web Speech API (`SpeechRecognition` / `webkitSpeechRecognition`).
- **Server transcription:** OpenAI Whisper CLI (default model `base`), 5-minute per-file timeout, temp-file cleanup, stderr capture.
- **FFmpeg integration:** path is PATH-injected into the child process; properties-configurable per environment.

### AI

- **Provider:** Anthropic Claude API.
- **Model:** `claude-sonnet-4-20250514`.
- **Max tokens per response:** 4,096.
- **Transport:** plain `java.net.HttpURLConnection` (30 s connect, 120 s read) — no vendor SDK, one-method `sendRequest()` for easy LLM swapping.
- **System prompts:** hardcoded per job type in `ClaudeService.java` (study_notes, meeting_minutes, journal_entry, outline, custom).
- **Fallback:** if Whisper fails, the client-side interim transcript is used; if Claude is not configured, verbatim mode still works.

### Platform / Browser

- **PWA installable** on Chromium desktops, Android Chrome/Edge, iOS Safari (Add to Home Screen).
- **Service worker:** network-first for navigations, stale-while-revalidate for static assets, precaches `/offline.html`, `/css/theme.css`, `/manifest.webmanifest`. Cache version `v1`.
- **Offline fallback:** branded HTML page with retry button.
- **Tested browsers:** Chrome, Edge, Safari, Firefox desktop; Safari iPad (with immersive pen mode); Android Chrome.
- **Responsive breakpoints:** ≤ 767 px single-page mobile book view; 768 px+ two-page spread; `(pointer: coarse) and (min-width: 768px)` triggers tablet immersive auto-activation.

### Deployment

- **Runtime:** Java 17, Jakarta Servlet 6.0, Apache Tomcat 10.
- **Build:** Maven WAR packaging; no Spring, no JPA, plain servlets + JDBC.
- **Database:** MySQL 8 via `mysql-connector-j 8.3.0`; 9 tables (`users`, `user_subscriptions`, `ai_jobs`, `usage_tracking`, `page_types`, `pages`, `tags`, `page_tags`, plus migrations log).
- **Config:** single `jotpage.properties` file outside the WAR; 3-step lookup (system property → `{catalina.base}/conf/` → classpath).
- **Secrets:** Google OAuth client ID/secret, Anthropic API key, DB password — all externalized, none in Git.
- **Production host:** `https://superiorstate.biz/jotpage/` on Ubuntu/Debian Tomcat 10.
- **Fonts:** DM Serif Display + Inter (Google Fonts CDN) for the rebranded Jyrnyl look; Playfair Display + Source Sans 3 available as an earlier palette.
- **CSS framework:** Bootstrap 5.3.3 (heavily overridden by `theme.css` to remove primary-blue) + Bootstrap Icons 1.11.3.

---

## 5. Competitive Differentiators

These are features grounded in the actual codebase, each hard to find bundled together elsewhere:

1. **True-A5 1480 × 2100 px pressure-ink canvas.** A real aspect-accurate A5 sheet at 10× resolution — notes written on a phone look correct when viewed on a tablet or printed, because the page is a physical object, not a zoom-dependent whiteboard. Very few web notebooks commit to a paper size.
2. **Two-finger swipe page-flip that cleanly cancels the in-flight pen stroke.** The `inkEngine.cancelStroke()` API was written specifically so the first finger's stroke doesn't ghost-commit when the second finger starts a swipe — a level of stylus/gesture polish most web drawing tools don't solve.
3. **Auto-activating tablet immersive mode with reparented navbar.** Detects `(pointer: coarse) and (min-width: 768px)`, hides the toolbar pill after 5 s of inking, auto-saves every 30 s, and preserves state across page flips via `?immersive=1`. Most competitors either toss you into a full-screen canvas with no chrome or never give you one at all.
4. **Six-mode AI voice pipeline with a real page-splitter.** Verbatim, Study Notes, Meeting Minutes, Journal Entry, Outline, or Custom — Claude-reshaped output is chunked into A5-sized pages by font-size-aware geometry (`PageSplitter.java`), not dumped into one infinite scroll. Notability, GoodNotes, and most others don't transform audio into structured multi-page notes.
5. **Animated book-spread dashboard with a physical cover page.** The dashboard is a literal two-page leather-bound spread with an animated cover ("My Jyrnyl — Drop the needle on a new thought"), keyboard/arrow/swipe navigation, and lazy-loaded text previews. No competitor ships this skin.
6. **PNG custom template backgrounds.** Users upload any PNG (5 MB, magic-number validated) as a reusable page template with an optional immutable-on-close flag — turning Jyrnyl into a personalized planner, habit tracker, or bullet-journal template engine without needing a template marketplace.
7. **Pro-email whitelist override.** Ops can flip specific addresses to Pro via `pro.emails=` in the properties file without touching the database — a rare and useful operational lever for beta programs and VIP users.
8. **Lean stack, installable PWA, zero client framework.** Plain Java 17 servlets + MySQL + vanilla JS, no React/Vue/Angular, no Electron wrapper — yet it installs to the home screen on iPad and Android with shortcuts for "New page" and "Voice record" and a branded offline fallback. Competitors tend to be either heavy Electron apps or walled-garden native apps.

---

## 6. Screenshots Description

Descriptions are detailed enough for a visual designer to reproduce each screen.

### Login (`index.jsp`)

A warm cream background with a faint gold radial glow at the top-left and a soft brown radial glow at the bottom-right. Dead center sits a single cream card (max-width 460 px) with a subtle 1 px warm-gray border, paper-style shadow, and a second inner border inset 18 px to create a frame-within-a-frame. Above the fold: the serif wordmark **"Jyrnyl"** in DM Serif Display, 3.4 rem, deep warm brown (#5c4033), tight letter-spacing. Beneath it a 64 px gold horizontal rule, then the italic tagline "*Your personal liner notes*" in muted warm gray. Below that, a single brown pill-shaped button with a white Google "G" SVG and the label **"Sign in with Google."** Footer in italic muted gray: *"Drop the needle on a new thought."*

### Dashboard — Book View (`dashboard.jsp`, `viewMode=book`)

Top: simple light-cream navbar with the Jyrnyl wordmark on the left, the user's Google avatar (36 px circle) on the right, "Welcome, {displayName}" text, and a small outlined "Logout" button. Main area: large serif headline **"My Jyrnyl"** with italic sub-line "*Drop the needle on a new thought*" and a small monthly usage counter shown to free-tier users after their first calendar month (`X / 20 pages this month`; first-month users see "Unlimited pages this month"; Pro users see no counter). Right of the header: a two-button book/list view toggle (open-book icon active) and a brown **"+ New Page"** primary button. Tag filter chip row: pill-shaped chips colored per tag, semi-transparent until active. Center stage: a leather-desk-textured background hosts a 3D-styled two-page book — a left page and a right page separated by a tooled "spine" shadow, each page slightly rotated to feel tactile. The first spread renders an animated cover with "My Jyrnyl" in serif, a ❖ ❖ ❖ gold flourish, and the tagline. Subsequent spreads show shrunken text-layer previews (word-wrapped, legible at thumbnail scale) or a "skeleton" placeholder of faint lines. Chevron nav buttons (first/prev/next/last) flank the book. Status strip beneath: "Page 3 / 12 · Lined." On mobile, only one page shows at a time. An "Add Page" slot appears after the last real page — a faded cream page with a large plus icon, "New Page" label, and subscript "Drop a new track."

### Dashboard — List View (`dashboard.jsp`, `viewMode=list`)

Same navbar, header, and tag filter. Below, a vertical stack of notebook-style entries with 14 px gaps. Each row: cream card with warm-gray border, left-edge gold-to-transparent "binding" stripe, radius 8 px, soft paper shadow. Inside: on the left a 58 × 82 px mini page thumbnail styled per background type (white, lined, dot grid, or graph) rotated −1.2° with a gold "masking-tape" strip across the top; then the creation date in serif ("Mar 3, 2026"), template name in italic muted gray, and any tag chips beneath; on the far right, an italic order number "#3". Hover raises the card 2 px and reveals a circular trash button at top-right (available to all tiers — deletion is no longer gated). A "Reorder" button appears in the header to enter drag-and-drop mode.

### Editor — Desktop (`editor.jsp`)

Full-height flex column. Top navbar: ← back arrow, page title label in serif brown, then four chevron nav buttons (« ‹ › »), a brown **"Save"** button with italic "Saved" status text beside it, a trash button, and a fullscreen/immersive toggle. Center stage: a centered A5 paper rectangle (1480 × 2100 px ratio) with a faint paper-edge border and four stacked shadows for a lifted-notebook feel, floating on a warm-cream background with gold and sienna radial glows. Three layers stack inside the paper: the canvas with strokes, an image-overlay layer (dashed gold borders around each image in image-mode), and a text-layer with dashed outlines around each text block in text-mode. Bottom toolbar: row of equal-height pill-sized icon buttons — pen (active, brown background), eraser, text (T), image (picture icon), a font-size dropdown that only shows when a text block is selected, color input, a thickness slider (1–20) with a live numeric readout, undo (↶), redo (↷). A tag badge bar sits above the toolbar showing current page tags with an "+ Add tag" popover trigger.

### Editor — Tablet Immersive (`body.tablet-immersive`)

Entire viewport is taken over by the canvas — no margins, no navbar, no stage padding. The top-right corner has a floating circular FAB (three-dot icon) in warm brown. The bottom edge has an auto-hiding toolbar pill — same tools as desktop but narrower, translucent, with rounded ends; disappears after 5 seconds of inking, reappears on pen lift or tap at the bottom hot edge. Tapping the FAB slides a right-side panel (50 % width, cream, soft shadow) onto the screen containing the reparented navbar and tag bar with a small close "✕". While drawing, the browser's native gestures (pinch-zoom, context menu, overscroll glow) are suppressed. Two-finger swipes flip the page: a small "Saved" toast fades in near the FAB after each autosave.

### Voice Entry (`voice-record.jsp`)

Top navbar same as dashboard. Centered content column (max-width 860 px) with serif headline **"Voice"** and italic subhead. A cream card holds the UI. At top: a pill-shaped tab switcher with two options — **Record** (mic icon) and **Upload** (up-arrow icon); active tab has a solid brown background and white text, inactive is transparent. Record tab: a large 96 px circular mic button (solid brown, white icon) pulsing burgundy when active; a big serif "00:00" elapsed counter; an italic hint "Tap to start speaking"; beneath that a scrollable "live box" that shows interim Web Speech transcription in italic muted gray and final text in solid brown. Upload tab: dashed-border drop zone with cloud-upload icon, "Drop an audio file here" text, accepted-formats hint, and a file-meta row showing selected filename + size. Below either tab, a "Transcript" textarea with editable Whisper output. Then a **Processing Mode** grid of six icon-cards — Verbatim, Study Notes, Meeting Minutes, Journal Entry, Outline, Custom — each with a Bootstrap icon, title, description, and a gold "Pro" badge plus lock icon (overlay) on the five Pro modes for free users; selected card gets a brown border. A "Custom instructions" textarea appears when Custom is selected. Form row: font-size select (2 – 64 pt) and tag selector (chips + inline new-tag form). At the bottom: a brown **"Create Entry"** primary button (disabled until the form is complete). A full-screen progress overlay dims the page during submission, showing a two-phase spinner, "Working on it" title, and per-step message like "Transcribing audio… / Processing with AI… / Creating pages…".

---

## 7. Roadmap Items

### Short-term (next 30 days)

- **Deploy latest WAR to production** — secrets are externalized; the production schema still needs the `002_ai_pipeline_and_tiers.sql` and `003_remove_calendar_templates.sql` migrations applied.
- **Test Google OAuth on production after deploy** — `google.redirectUri` differs from local dev and needs end-to-end verification.
- **Fix book-view thumbnails for custom-background pages** — they currently show blank because the dashboard JSON payload does not carry the base64 background data for custom templates.
- **Fix legacy voice pages with tiny `fontSize` values** — pages created before the point-to-pixel scaling fix store raw pixel values; they display correctly thanks to a compat path, but the editor dropdown shows the wrong selection when editing them.
- **Add touch drag-to-reorder in list view** — HTML5 DnD does not natively support touch, so the current reorder mode is desktop-only; needs a touch polyfill or a custom long-press drag.
- **Finish the export lock** — `FEATURE_EXPORT` exists in `TierCheck.java` with a user-facing message but no export endpoint yet. (Page deletion used to be Pro-only but is now available on all tiers.)

### Medium-term (60–90 days)

- **Stripe integration for Pro tier** — `user_subscriptions` schema is scaffolded with `stripeCustomerId`, `stripeSubscriptionId`, `expiresAt`, but there is no checkout flow, no webhook receiver, and no billing portal yet; the "Upgrade coming soon!" hint on the voice page is placeholder copy.
- **Export / download pages** — likely targets: per-page PNG, multi-page PDF of the current notebook, and a ZIP with ink JSON for full portability.
- **Search across pages** — full-text search over text_layers and AI-generated transcripts; currently only tag filtering is available.
- **Proper admin dashboard** — replace the `pro.emails` properties whitelist with a DB-backed admin console for tier flipping and usage inspection.
- **Alternate AI providers** — `ClaudeService.sendRequest()` was built to be easily swappable; adding OpenAI or an open-source model behind the same interface is a natural next step, especially for privacy-sensitive users.
- **More voice processing modes** — request-frequent additions like "Email draft," "Task list," "Code review notes," "Therapy reflection."
- **Tablet-mode polish pass** — pen-only mode, palm rejection toggle, customizable swipe sensitivity, pen-tip cursor rendering.
- **Granular autosave & offline queue** — save strokes to IndexedDB and sync when the network returns, so the offline page is a genuine working state rather than just a fallback.

### Long-term (6+ months)

- **Native iOS and Android apps** — currently a PWA; native wrappers would unlock Apple Pencil tilt, proper palm rejection, and OS-level file-open handlers for audio.
- **Desktop app** — Tauri or Electron shell around the same web UI to get a dock/tray presence and a system-wide "quick capture" hotkey.
- **Collaborative / shared notebooks** — multi-user, per-page permissions, optional commenting.
- **Handwriting-to-text OCR** — run ink-layer recognition to make drawn notes searchable alongside typed text.
- **End-to-end encrypted notebooks** — optional zero-knowledge mode for journals; server stores ciphertext only.
- **Template marketplace** — user-submitted PNG templates, gallery, featured-collections, revenue share with creators.
- **Calendar / schedule integrations** — linking pages to calendar events; migration `003` removed an earlier calendar template line, suggesting this has been on the backlog.
- **Voice entry in low-resource mode** — a "browser-only" pipeline path that skips Whisper entirely for users who can't run the server subprocess (useful if we ever open-source the stack).
- **Skins / theme packs** — the codebase already toggles between two font systems (DM Serif Display + Inter vs. Playfair Display + Source Sans 3); promoting this into a user-selectable theme picker is a small step with high perceived value.

---

*Generated from the current `main` branch source tree. Source documents: `JOTPAGE_FULL_PROJECT_DOC.md`, the `src/main/java/com/jotpage/**` tree, and `src/main/webapp/**`.*

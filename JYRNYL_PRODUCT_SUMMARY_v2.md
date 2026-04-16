# Jyrnyl — Product Summary v2

*Pronounced "Journal." A warm, tactile digital notebook with a vinyl/liner-notes soul. Live at https://jyrnyl.com/ as of 2026-04-15; this document reflects the `main` branch of the `jotpage` repository as of 2026-04-16.*

---

## 1. Product Overview

**Jyrnyl** is a browser-native, pressure-sensitive digital notebook that treats every page as a real A5 artifact, dresses the dashboard as a leather-bound book spread with an animated cover, and turns spoken words into structured multi-page journal entries via Whisper + Claude. Its user-facing vocabulary borrows from the world of vinyl records — the editor is the **Studio**, the voice page is the **Voice Booth**, each individual page is a **"track"**, the journal itself is the user's **"album,"** the offline fallback reassures "the record's still spinning," and the manifest tagline is **"Your personal liner notes. Drop the needle on a new thought."** Under the brand skin sits a lean Java 17 / Jakarta Servlet 6.0 / MySQL 8 stack with no client framework, shipped as an installable PWA and delivered as the root context of `jyrnyl.com` behind Cloudflare + nginx + Tomcat 10. Jyrnyl is built for journalers, students, knowledge workers, and tablet-first creatives who want the feel of a Moleskine, the convenience of cloud sync and Google single sign-on, and the ability to dictate an entry and have Claude reshape it into study notes, meeting minutes, or reflective prose — all on a genuine 1480 × 2100 px A5 canvas that prints correctly at paper size.

---

## 2. Complete Feature Inventory

### Canvas / Drawing (`js/ink-engine.js`, `jsp/editor.jsp`)

- **Pressure-sensitive pen tool.** `Pointer Events API` reads `e.pressure`; stores `{x, y, pressure}` per point; color + thickness per stroke.
- **Variable thickness slider (1–20 px).** Value shown as live numeric readout next to a `bi-circle-fill` dot icon.
- **Native color picker** for pen strokes and selected text blocks.
- **Stroke-level eraser.** Hit-tests whole strokes using segment-distance with threshold `12 + stroke.thickness/2`; single-point strokes use circular distance; removes top-most hit stroke.
- **Text blocks.** Contenteditable overlays positioned anywhere on the page; drag handle, resize handle, delete button; stored `{id, x, y, text, fontSize, color, width, height}`. Android IME fix via a synthetic click dispatch. Backspace/Delete on an empty block removes it.
- **Font size dropdown (2, 4, 6, 8, 10, 12, 14, 16, 18, 24, 32, 48, 64 pt).** Shown only when a text block is selected; internally scaled via `POINT_TO_PIXEL = 10`; default 4 pt.
- **Image overlay tool (Pro only).** Hidden file picker (png/jpg), 5 MB cap, alert `"Image must be under 5 MB."` Each image gets draggable move, aspect-preserved resize (min 40×40), and × delete; stored as base64 in `image_layers` JSON.
- **Undo / redo** — stroke-level history capped at 100 entries; `Ctrl+Z`, `Ctrl+Shift+Z`, `Ctrl+Y`.
- **Save** — `PUT /app/page/{id}` with `{inkData, textLayers, imageLayers}`; `Ctrl+S`; status label mirrored into a floating top-center toast (`"Saved"`, `"Locked"`, `"Error …"`).
- **Auto-save** — 10 s interval on the editor; 30 s interval in tablet immersive mode; triggered additionally on `visibilitychange:hidden` and `beforeunload`.
- **Tool-preference persistence** — `localStorage('jyrnyl.tool.prefs')` holds `{color, thickness, fontPoint}` and is restored on load so preferences survive navigation and logout.
- **Backgrounds.** `blank` (#fffdf7 paper), `lined` (80 px spacing), `dot_grid` (60 px dots), `graph` (40 px warm-gray grid), `custom` (base64 PNG behind the ink layer). Legacy `daily_calendar` / `time_slot` / `monthly_calendar` values remain in the enum but no longer ship as system templates (see migration 003).
- **Locked / closed pages** — `is_closed && immutable_on_close` flips pages into read-only; save returns 403 `{"error":"page is locked"}`; delete requires typing `DELETE` as a confirmation phrase.
- **Page navigation (editor)** — first/prev/next/last hrefs are set as body data-attrs on render (`data-first-href`, etc.) and consumed by edge-tabs (see Navigation). Hidden `#first-btn`/`#prev-btn`/`#next-btn`/`#last-btn` kept in the DOM (clipped) so JS can trigger save-then-navigate programmatically.
- **Delete page (editor)** — modal with locked-page confirmation phrase; `DELETE /app/page/{id}` → redirect to `backHref`; allowed on all tiers.

### Templates (`jsp/dashboard.jsp`, `servlet/PageTypeServlet.java`, `dao/PageTypeDao.java`)

- **System templates** — Blank, Lined, Dot Grid, Graph (always available; seeded in `schema.sql`).
- **User custom templates** — upload any PNG, max 5 MB, PNG magic-number validated (`0x89 P N G`) server-side; stored as base64 TEXT.
- **Immutable-on-close toggle** per template (checkbox `"Lock pages on close"`).
- **Template chooser modal** — 3-column grid, drop-zone upload with live thumbnail preview (`140×200` max), inline `"Uploading…"` state, creation count `({customTemplateCount}/{customTemplateLimit})` visible to free users.
- **Drag-to-reorder templates** — HTML5 DnD on template cards → `PUT /app/api/pagetypes/reorder` with the full ordered `typeIds` list (system + custom).
- **Voice booth shortcut card** — a dashed template card labelled **"Voice"** (`bi-mic-fill`) appended to the grid as a quick launch into `/app/voice-record`.
- **In-use protection** — deleting a template that still has referenced pages returns **409 Conflict** with message `"Cannot delete — pages still use this template. Delete or reassign those pages first."`
- **Inline error banner** — persistent dismissable alert inside the modal for template errors.

### Voice & AI (`jsp/voice-record.jsp`, `js/voice-recorder.js`, `servlet/VoiceRecordServlet.java`, `util/ClaudeService.java`, `util/WhisperService.java`, `util/PageSplitter.java`, `util/VoiceModeValidator.java`)

- **In-browser recording** — `MediaRecorder` (prefers `audio/webm;codecs=opus`), 72 px brown/gold mic button pulsing burgundy while active, elapsed `mm:ss` readout, `Tap to start speaking` → `Recording — tap to stop` → `Tap to record again`.
- **Live interim transcript** — `SpeechRecognition` / `webkitSpeechRecognition`, `continuous=true`, `interimResults=true`, auto-restart with 250 ms delay on Chrome silence stop.
- **Overlap dedup** — `computeOverlapAppend()` trims repeated tails of re-emitted utterances (n-gram match, min n = 2…6 depending on build, max 80 tokens). Known bug: first-word doubling for short words (see §9 roadmap).
- **Audio upload** — drag-drop or click; accepts `.mp3 .wav .webm .m4a .ogg .flac`; max 25 MB enforced client-side with message `"File is N MB. Max is 25 MB."` and server-side via `@MultipartConfig(maxFileSize = 26_214_400L)` → HTTP 413.
- **Whisper transcription (server-side)** — `WhisperService` shells out `whisper <file> --model base --output_format txt --output_dir <tmp> --language en`, 5-minute per-file timeout, FFmpeg PATH injection, temp cleanup in `finally`. Runs for **all tiers when an audio file is uploaded** — the earlier "Pro-only" gate has been dropped in the current servlet. If Whisper fails, falls back to `browserTranscript`.
- **Claude processing** — `ClaudeService` POSTs to `https://api.anthropic.com/v1/messages`, model `claude-sonnet-4-20250514`, max_tokens 4096, 30 s connect / 120 s read.
- **Six processing modes** with per-mode system prompts:
  - **Verbatim** — straight transcript, no AI (free tier default).
  - **Study Notes** — markdown notes with `##` headers, **bold** terms, bullets, logical (not chronological) grouping.
  - **Meeting Minutes** — Attendees / Key Discussion Points / Decisions / Action Items (with owners) / Next Steps in markdown.
  - **Journal Entry** — reflective first-person prose in flowing paragraphs, no bullets.
  - **Outline** — `##` main topics and `-` subtopics, concise.
  - **Custom** — prompt prefixed with `"Process the following transcript according to these instructions: "` + user's own text.
- **`VoiceModeValidator`** — pre-flight sanity check before spending a Claude call. Each mode has its own word-count floor and heuristic (e.g. Journal Entry demands ≥ 3 first-person tokens; Study Notes requires ≥ 80 words + a definitional cue or repeated content noun; Meeting Minutes looks for decisions / action words or ≥ 2 proper nouns; Outline wants sequencers or colon-lists). Validation failures return **HTTP 422** with a user-facing message and a short `detail` debug code.
- **Free-tier AI trial** — `FREE_AI_TRIAL_PER_MODE = 1`; `AiJobDao.countByUserIdAndJobType()` counts `complete`+`processing` jobs only, so a failed job doesn't burn the trial. Unlock icon + gold `"Try free (1 use)"` label per unused card; `"Trial used — upgrade to Pro"` after.
- **Tier gating** — non-verbatim modes require Pro after trial. Free-tier cap re-checked inside the pipeline: if `pagesThisMonth + chunks > monthlyLimit`, job is marked failed and HTTP 403 returned.
- **Page splitter** — `PageSplitter` wraps AI output into A5 chunks using font-size-aware geometry: `charsPerLine = floor(1380 / (fontSizePx × 0.6))`, `linesPerPage = floor(2000 / (fontSizePx × 1.5))`; respects `\n` as hard breaks, never splits mid-word, always returns ≥ 1 page.
- **AI job tracking** — every run persisted to `ai_jobs` (`pending` → `processing` → `complete`/`failed`) with input, output, audio path, custom prompt, error message.
- **Usage metering** — `usage_tracking` records `pages_created` and `ai_jobs_run` per user per calendar month (`YYYY-MM` key); `audio_minutes_processed` column is scaffolded but not yet written from code.
- **Two-phase progress overlay** — simulated client-side ticker cycles Uploading → Transcribing → Processing with AI → Creating pages (with the vinyl-branded copy **"Pressing your journal entries"**).
- **Editable transcript** — Whisper output lands in a `#transcriptBox` textarea that the user can edit before submitting.
- **Font size + tag selection per entry** — one selection applied to every page created by the run; inline `"Add"` form for creating a new tag without leaving the page.

### Organization (`jsp/dashboard.jsp`, `servlet/TagServlet.java`, `servlet/PageTagServlet.java`)

- **Tags** — full CRUD, user-scoped; `name VARCHAR(100)`, `color VARCHAR(7)` hex (default `#6c757d`); `UNIQUE(user_id, name)`.
- **Page ↔ tag associations** — attach/detach via popover on the editor, checkbox list on voice entry, chip rows in list view and book view. `POST /app/api/page-tags/{pageId}` (INSERT IGNORE), `DELETE /app/api/page-tags/{pageId}/{tagId}`.
- **Tag filter bar (list view)** — clickable chip row with OR/union semantics; `"Showing X of Y pages"` counter; `"Clear"` link; `"Manage"` button that opens the tag-management modal.
- **Manage Tags modal** — rename (live dirty marker + Save), recolor, delete. Deleting an in-use tag opens a submenu: `"Remove from all pages & delete"` OR `"Replace with <select>"` (atomic `tagDao.replaceTag` in a transaction).
- **Tag filter popover (book view / bubble menu)** — same UX as the list-view chip bar but rendered as a centered dialog on desktop / bottom sheet on mobile, launched from the bubble menu's "Filter by tag" action.
- **Page locking** — closed pages badge `"Closed"` on thumbnails; locked ones refuse edits (HTTP 403) and require confirmation phrase `DELETE` to remove.

### Navigation & Dashboard (`jsp/dashboard.jsp`, `js/book-view.js`, `servlet/DashboardServlet.java`, `servlet/PageThumbnailServlet.java`)

- **Immersive cover landing (new in v2).** On first load (and whenever there's no `?tags=` filter), the dashboard drops the user onto a full-viewport leather desk with the book cover centered on it. No navbar, no heading, no buttons — only the floating bubble menu (☰) and an italic animated hint `"Tap the cover to open · swipe to turn the page"`. Tap, Space, Enter, → arrow, or a left swipe opens the book to the newest-page spread. "First page" nav returns to the cover landing state.
- **Book cover** — leather radial gradient (`#5a3d28` → `#2e2018`) with gold-foil double-border (`::before` at 22 px) + embossed inner frame (`::after` at 32 px / bottom 56 px) so the footer sits in the gap between frames. Center: `jyrnyl-logo-square.svg` with `mix-blend-mode: screen` + `sepia(0.6) saturate(2.2) brightness(0.75)` — renders as a warm gold stamp. Footer: 22 px avatar + display name + **"N track" / "N tracks"** (vinyl branding).
- **Book view (default)** — two-page spread on ≥720 px, single page on mobile; gold ribbon spine shadow; per-page ink/text layer thumbnail rendered via canvas at 296 × 420 px, with a 7×6 month grid or hour-strip drawn for legacy calendar backgrounds. Empty text layers paint a faded skeleton of 8 alternating-width bars.
- **"Add Page" slot** — placeholder after the last real page: striped paper, `+` icon, label **"Drop a new track"**, subscript **"Start your next entry"** (vinyl branding). Opens the template chooser modal.
- **Keyboard navigation** — `←` / `→` / `Home` / `End` / `Space` / `Enter`; touch swipe (48 px horizontal dominance).
- **List view (sort utility)** — no longer a primary view. Reached only via bubble menu → "Sort pages" which navigates to `?view=list&sort=1`. The `sort=1` param clears any active tag filter on load so drag-reorder is predictable. Top bar: heading **"Sort your pages"** + italic sub `"Drag to reorder · tap a page to open it"` + Reorder toggle + **Done** button that returns to book view. Each row: cream card with gold `::before` binding stripe, 58 × 82 px mini thumbnail rotated −1.2° with a gold "masking-tape" strip, creation date, template name, tag chips, `#N` order, hover-reveal trash button.
- **Reorder mode (list view only)** — HTML5 DnD on page rows; `PUT /app/page/reorder` with full `pageIds` list; dashed borders and reduced opacity while dragging.
- **URL-driven state** — `?view=book|list`, `?tags=1,3`, `?new=1` (auto-opens template modal when routed from editor bubble menu), `?filter=1` (auto-opens tag-filter popover), `?sort=1` (list view + clear filter), `?error=page_limit` (opens upgrade modal).
- **Lazy thumbnails** — book view fetches per-page data via `GET /app/api/page-thumbnail/{id}` with an in-memory cache + in-flight dedup and a ±1 spread prefetch.

### Floating UI (`js/bubble-menu.js`, `js/pen-button.js`, `js/edge-tabs.js` + matching JSPFs)

- **Bubble menu (☰)** — 56 px draggable, edge-friendly floating trigger present on both dashboard and editor. Position saved to `localStorage('jyrnyl.menu.pos')` (schema v2 = `{x, y}` viewport coords). Tap expands a 180° radial fan (44 px items, radius 84 px) toward the viewport center; falls back to a vertical column if any item clamps by > 2 px. Five actions, in order:
  1. **`new-track`** `bi-plus-lg` — "New track" → dispatches `jyrnyl:open-new-page-modal` (or redirects to `/app/dashboard?new=1` from the editor).
  2. **`sort`** `bi-sort-down` — "Sort pages" → `/app/dashboard?view=list&sort=1`.
  3. **`filter`** `bi-funnel` — "Filter by tag" → dispatches `jyrnyl:open-tag-filter` (or `/app/dashboard?filter=1`).
  4. **`voice`** `bi-mic` — "Voice booth" → `/app/voice-record`.
  5. **`logout`** `bi-box-arrow-right` — "Logout" → `/logout`.
- **Pen button (✏️) — editor only.** 52 px gold radial-gradient draggable edge-snap button. Position saved to `localStorage('jyrnyl.pen.pos')` (`{edge, offset}`, default right edge at 0.78). Single tap dispatches `jyrnyl:toggle-toolbar`, which shows/hides the floating drawing toolbar and repositions it adjacent to the button (extends leftward from right edge, rightward from left, horizontal from top/bottom; clamped to viewport). Button fades to `opacity: 0.15` while actively drawing. Keyboard Space/Enter also toggles.
- **Edge tabs (editor only).**
  - **Left edge** — `⟪` First page + `<` Previous page (`#edgeTabLeft`).
  - **Right edge** — `>` Next page + `⟫` Last page (`#edgeTabRight`).
  - **Top-center** — `bi-tags` Tag this page + `bi-trash3` Delete this page (`#edgeTabTop`, delete has `et-danger` styling).
  - All tabs sit translucently at the edge (base `opacity: 0.3`, `0.85` on hover), animate a gold `et-glow-pulse` on hover, `.flash` briefly on tap, and show an `et-spinner` replacing the icon while saving.
  - Navigation clicks flow through **save-and-navigate**: click hidden `#save-btn`, MutationObserver watches `#save-status` for `"Saved"`/`"Locked"`, navigates on success, aborts on `"Error"`, 2 s safety-timeout navigates anyway.
  - Top-center tab dispatches `jyrnyl:open-tag-editor` / `jyrnyl:delete-page`; the delete button is hidden from non-Pro users by `bubbleMenu.setActionVisible` (legacy code path; page deletion is actually available on all tiers).
  - `body.drawing-active` fades edge tabs to `opacity: 0.04` so they don't interfere with stylus work.
- **Floating drawing toolbar** — same tools as before but repositioned by the pen button, auto-hides 5 s after showing unless actively drawing, hides instantly on canvas `pointerdown`.
- **Save toast** — warm-brown italic pill at top center, driven by a MutationObserver watching `#save-status`.

### Tablet Mode (`js/tablet-mode.js`, Phase 5 slim edition)

- **Auto-activation** — CSS media query `(pointer: coarse) and (min-width: 768px)` triggers, `?immersive=1` URL override still supported, MediaQueryList listener enters/exits on device rotation.
- **Full-viewport canvas** with `touch-action: none`, `overscroll-behavior: none`, `contextmenu` blocked.
- **Auto-save every 30 s** (`AUTO_SAVE_INTERVAL_MS`) while dirty. Dirty tracking from canvas `pointerup`/`cancel` and text-layer `pointerup`/`input`/`keyup`.
- **Browser gesture suppression** — `touchmove` preventDefault outside canvas, `gesturestart` preventDefault.
- **Two-finger horizontal swipe** — ≥ 50 px dominance on canvas stage dispatches `jyrnyl:save-and-navigate` with the relevant prev/next href; also calls `window.inkEngine.cancelStroke()` the moment the second finger lands so an in-flight pen stroke is cleanly aborted.
- **REMOVED (vs. pre-overhaul build):** the FAB, the slide-out panel, reparenting of navbar/tag-bar into the immersive chrome, href rewriting for `?immersive=1`, the toolbar auto-hide timer, and the manual toggle button. Those responsibilities moved to the bubble menu + pen button + edge tabs.

### Account & Auth (`servlet/LoginServlet.java`, `servlet/OAuthCallbackServlet.java`, `servlet/LogoutServlet.java`, `servlet/AuthFilter.java`, `util/TierCheck.java`)

- **Google OAuth 2.0** — single sign-on only; scopes `openid email profile`, `prompt=select_account`, `response_type=code`. No passwords ever stored.
- **Session-based auth** — `AuthFilter` guards `/app/*`; public paths are `/`, `/login`, `/oauth2callback`, `/index.jsp`, `/css/*`, `/js/*`, `/images/*`, `/img/*`, `/static/*`, `/favicon*`. Unauthenticated → 302 to `/login`.
- **User profile** — Google-supplied display name + avatar shown on the book cover footer (no visible navbar on the dashboard in current build).
- **Tier tracking** — `users.tier ENUM('free','pro')` + `user_subscriptions` table scaffolded with `stripe_customer_id`, `stripe_subscription_id`, `expires_at`; `SubscriptionDao` exists but is **not wired to the live tier check** — that uses `User.tier` + `pro.emails` whitelist in `TierCheck.isPro()`.
- **Properties-based Pro override** — `pro.emails=a@x,b@y` in `jotpage.properties` grants Pro without touching the DB (useful for founders/testers).
- **Logout** — `/logout` invalidates session, 302 to `/index.jsp`.

### PWA / Offline (`manifest.webmanifest`, `sw.js`, `offline.html`, `jspf/pwa-*.jspf`, `NoCacheFilter.java`)

- **Installable PWA.** Manifest `name` = `"Jyrnyl — Record your life."`, `short_name` = `"Jyrnyl"`, description = `"Your personal liner notes. Drop the needle on a new thought."`, `start_url` = `/app/dashboard`, `scope` = `/`, `display` = `standalone`, `background_color` = `#faf6f0`, `theme_color` = `#5c4033`, categories: productivity / lifestyle / utilities.
- **Icons:** `jyrnyl-logo-square.svg` (any size), `jyrnyl-logo-400.png` (400×400), `jyrnyl-logo-800.png` (800×800), maskable `/icons/icon-maskable-512.png`.
- **Shortcuts:** **"Drop a new track"** (short: "New track") → `/app/dashboard?action=new`, and **"Voice record"** (short: "Record") → `/app/voice-record`.
- **Service worker (`sw.js`)** — `CACHE_VERSION = 'v9'`, caches `jyrnyl-static-v9` + `jyrnyl-runtime-v9`. Precache: `/offline.html`, `/css/theme.css`, `/manifest.webmanifest`, `/images/jyrnyl-logo-square.svg`, `/images/jyrnyl-logo-400.png`. Network-only patterns: `/login$`, `/logout$`, `/oauth2callback`, `/api/`. Navigation → network-first with fallback to cached shell then `/offline.html` then `503 Offline`. Other GETs → stale-while-revalidate. `skipWaiting()` + `clients.claim()` on activate + old-cache purge.
- **Offline fallback (`offline.html`)** — warm cream gradient card with 96 px logo, heading `"You're offline"`, italic subhead **"The record's still spinning — we just can't reach the server right now."** (vinyl branding), `"Try again"` button → `location.reload()`.
- **`NoCacheFilter`** forces the browser to re-fetch `sw.js` and `manifest.webmanifest` on every visit so new releases activate promptly.

---

## 3. Tier Feature Matrix

Source of truth: `src/main/java/com/jotpage/util/TierCheck.java` (constants `FREE_MONTHLY_PAGE_LIMIT = 20`, `FREE_CUSTOM_TEMPLATE_LIMIT = 5`, `FREE_AI_TRIAL_PER_MODE = 1`). "Month 1" = the calendar month the user's account was created (`user.createdAt` YearMonth equals current YearMonth in the system zone).

| Feature | Free | Pro | Pro+ (future) |
|---|---|---|---|
| Google OAuth sign-in | ✅ Included | ✅ Included | ✅ Included |
| Page creation | ⚠ Unlimited in Month 1, then 20 pages / calendar month | ✅ Unlimited | ✅ Unlimited |
| System templates (Blank / Lined / Dot Grid / Graph) | ✅ Included | ✅ Included | ✅ Included |
| Custom PNG templates | ⚠ Up to 5 templates | ✅ Unlimited | ✅ Unlimited |
| Pen / eraser / text tools | ✅ Included | ✅ Included | ✅ Included |
| Image overlay tool | 🔒 Locked (UI button not rendered) | ✅ Included | ✅ Included |
| Undo / redo (100-entry history) | ✅ Included | ✅ Included | ✅ Included |
| Tags (CRUD, filter, manage, replace-on-delete) | ✅ Included | ✅ Included | ✅ Included |
| Book view (default) | ✅ Included | ✅ Included | ✅ Included |
| Book cover landing | ✅ Included | ✅ Included | ✅ Included |
| List view (Sort utility via bubble menu) | ✅ Included | ✅ Included | ✅ Included |
| Drag-to-reorder pages and templates | ✅ Included | ✅ Included | ✅ Included |
| Tablet immersive mode | ✅ Included | ✅ Included | ✅ Included |
| Two-finger save-and-flip gesture | ✅ Included | ✅ Included | ✅ Included |
| Bubble menu, pen button, edge tabs | ✅ Included | ✅ Included | ✅ Included |
| PWA install + offline shell | ✅ Included | ✅ Included | ✅ Included |
| Voice recording (browser MediaRecorder + SpeechRecognition) | ✅ Included | ✅ Included | ✅ Included |
| Audio upload (MP3/WAV/WebM/M4A/OGG/FLAC, ≤ 25 MB) | ✅ Included | ✅ Included | ✅ Included |
| Whisper server-side transcription | ✅ Included (runs for any tier when audio uploaded) | ✅ Unlimited | ✅ Unlimited |
| Verbatim voice-to-pages | ✅ Included | ✅ Unlimited | ✅ Unlimited |
| Study Notes AI mode | ⚠ 1 free trial | ✅ Unlimited | ✅ Unlimited |
| Meeting Minutes AI mode | ⚠ 1 free trial | ✅ Unlimited | ✅ Unlimited |
| Journal Entry AI mode | ⚠ 1 free trial | ✅ Unlimited | ✅ Unlimited |
| Outline AI mode | ⚠ 1 free trial | ✅ Unlimited | ✅ Unlimited |
| Custom AI prompt mode | ⚠ 1 free trial | ✅ Unlimited | ✅ Unlimited |
| Delete pages (including locked) | ✅ Included (all tiers) | ✅ Included | ✅ Included |
| Properties-based `pro.emails` override | n/a (grants Pro) | ✅ Included | ✅ Included |
| Export / download pages | 🔒 Locked (`FEATURE_EXPORT` declared; no endpoint) | 🔜 Planned | ✅ Included |
| Stripe subscription billing | — | 🔜 Planned | 🔜 Planned |
| Collaborative shared notebooks | — | — | 🔜 Planned |
| Native iOS / Android / desktop apps | — | — | 🔜 Planned |
| Handwriting-to-text OCR | — | — | 🔜 Planned |
| End-to-end encrypted notebooks | — | — | 🔜 Planned |
| Full-text search across ink + transcripts | — | — | 🔜 Planned |
| Audio-minutes quota display | — | — | 🔜 Planned (column scaffolded, not written) |

**Legend:** ✅ Included · ⚠ Limited · 🔒 Locked · 🔜 Planned · — Not offered.

**Notes on implementation.** (a) Whisper is no longer tier-gated in `VoiceRecordServlet` — any user with an uploaded audio file gets server-side transcription; the **AI reshaping** step is what gates behind the 1-trial-per-mode / Pro logic. (b) Page deletion is allowed on every tier; the "delete hidden to non-Pro" call in `edge-tabs.js` is legacy dead-code still wired but overridden elsewhere. (c) The `FEATURE_EXPORT` constant is declared and has a user-facing error string, but no export servlet exists. (d) `user_subscriptions` with Stripe columns is in the schema; no checkout/webhook code is wired.

---

## 4. Technical Specs

### Canvas

- **Internal resolution:** 1480 × 2100 pixels (A5 at 10× resolution — 148 mm × 210 mm).
- **Coordinate scale:** `POINT_TO_PIXEL = 10` shared between `ink-engine.js`, `editor.jsp`, `voice-record.jsp`, and `PageSplitter.java`.
- **Usable text area:** 1380 × 2000 px (50 px margins on all sides).
- **Font sizes (UI dropdown):** 2, 4, 6, 8, 10, 12, 14, 16, 18, 24, 32, 48, 64 pt. Default 4 pt in the editor, 16 pt in voice runs.
- **Pointer Events API** for pressure-sensitive input; works with Apple Pencil, Surface Pen, Wacom, capacitive stylus, and finger.
- **Ink data format:** `{ strokes: [{ points: [{x,y,pressure}], color, thickness }] }` — JSON in MySQL `pages.ink_data`.
- **Text layer format:** `{ id, x, y, text, fontSize (canvas px), color, width, height }` — stored in `pages.text_layers`.
- **Image layer format:** `{ id, x, y, width, height, src (data:image/… base64) }` — stored in `pages.image_layers MEDIUMTEXT` (added in migration 005).
- **Max image overlay size:** 5 MB per image; inserts at ~40 % canvas width with aspect preserved.
- **Undo/redo history cap:** 100 entries.

### Audio

- **Supported upload formats:** MP3, WAV, WebM, M4A, OGG, FLAC.
- **Max upload size:** 25 MB (servlet `maxFileSize = 26_214_400`, `maxRequestSize = 27_262_976`).
- **Browser recording:** `MediaRecorder` preferring `audio/webm;codecs=opus`, with generic fallback.
- **Live interim transcript:** Web Speech API (`SpeechRecognition` / `webkitSpeechRecognition`), `lang='en-US'`.
- **Server transcription:** OpenAI Whisper CLI, model `base`, `--language en`, 5-minute timeout, temp-dir cleanup, stderr drain on a daemon thread.
- **FFmpeg integration:** path is PATH-injected into the Whisper child process; properties-configurable per environment.

### AI

- **Provider:** Anthropic Claude API.
- **Model:** `claude-sonnet-4-20250514`.
- **Max tokens per response:** 4,096.
- **Transport:** plain `java.net.HttpURLConnection` (30 s connect, 120 s read) — no vendor SDK, one `sendRequest()` method so LLMs can be swapped.
- **System prompts:** hardcoded per job type in `ClaudeService.java` (study_notes, meeting_minutes, journal_entry, outline, custom).
- **Pre-flight:** `VoiceModeValidator` gates each non-verbatim submission against word-count + heuristic rules; failures return HTTP 422 without spending a Claude call.
- **Trial counting:** counts only `complete` + `processing` job rows, so a failed trial doesn't burn the free slot.
- **Fallback:** if Whisper fails, the browser-side interim transcript is used; if Claude is not configured, only Verbatim mode is available (servlet returns 503 for other modes).

### Platform / Browser

- **PWA installable** on Chromium desktops, Android Chrome/Edge, iOS Safari (Add to Home Screen).
- **Service worker:** `CACHE_VERSION = 'v9'`; network-first for navigations, stale-while-revalidate for static assets, precaches offline page + theme CSS + manifest + both Jyrnyl logos.
- **Offline fallback:** branded HTML card with retry button, italic vinyl copy.
- **Tested browsers:** Chrome, Edge, Safari, Firefox desktop; Safari iPad (with immersive pen mode); Android Chrome.
- **Responsive breakpoints:** ≤ 720 px single-page mobile book view; 721 px+ two-page spread; `(pointer: coarse) and (min-width: 768px)` triggers tablet-immersive auto-activation.

### Stack / Runtime / Deploy

- **Runtime:** Java 17, Jakarta Servlet 6.0, Apache Tomcat 10.1.16.
- **Build:** Maven 3, WAR packaging (`jotpage.war` locally), `maven-compiler-plugin:3.13.0`, `maven-war-plugin:3.4.0`.
- **Dependencies:** `jakarta.servlet-api:6.0.0` (provided), `mysql-connector-j:8.3.0`, `gson:2.11.0`, `google-api-client:2.7.0`, `google-oauth-client-jetty:1.36.0`, `google-api-services-oauth2:v2-rev20200213-2.0.0`, `jakarta.servlet.jsp.jstl-api:3.0.0` + `jakarta.servlet.jsp.jstl:3.0.1`. **No Spring, no JPA, no connection pool library.**
- **DB:** MySQL 8 with **9 tables** (`users`, `user_subscriptions`, `ai_jobs`, `usage_tracking`, `page_types`, `pages`, `tags`, `page_tags` + migrations log). `pages.image_layers MEDIUMTEXT` added via migration 005; `page_types.sort_order` added via migration 004.
- **Config:** single `jotpage.properties` file outside the WAR; 3-step lookup (system property `jotpage.config` → `{catalina.base}/conf/jotpage.properties` → classpath). Keys: `google.*`, `db.*`, `whisper.*`, `ffmpeg.path`, `anthropic.apiKey`, `pro.emails`.
- **Secrets:** Google OAuth client/secret, Anthropic API key, DB password — all externalized, none in git.
- **Fonts:** DM Serif Display (`var(--font-serif)`) + Inter (`var(--font-body)`), Google Fonts CDN.
- **CSS framework:** Bootstrap 5.3.3 (overridden by `theme.css`) + Bootstrap Icons 1.11.3.
- **Cache-bust:** `?v=9` query-string on all editor JS, matching `sw.js` `CACHE_VERSION`.

---

## 5. Competitive Differentiators

Grounded in actual code, each hard to find bundled together elsewhere:

1. **True-A5 1480 × 2100 px pressure-ink canvas.** A real aspect-accurate A5 sheet at 10× resolution — notes written on a phone look correct on a tablet or printed, because the page is a physical object, not a zoom-dependent whiteboard. Very few web notebooks commit to a paper size.
2. **Pre-flight AI validator.** `VoiceModeValidator` checks each non-verbatim submission against word-count + mode-specific heuristics (first-person tokens for Journal mode, decision verbs for Meeting Minutes, colon-lists/sequencers for Outline, etc.) and returns HTTP 422 before spending a Claude call. Most dictation tools either ship output with no mode gating at all, or burn a paid trial on clearly wrong inputs.
3. **Two-finger swipe page-flip that cleanly cancels the in-flight pen stroke.** The `inkEngine.cancelStroke()` API exists specifically so the first finger's stroke doesn't ghost-commit when the second finger starts a swipe — the `save-and-navigate` flow then auto-saves before flipping.
4. **Animated book-spread dashboard with a leather-desk cover landing.** First load drops you onto a gold-stamped leather cover on a tooled desk; tap, arrow, or swipe to open the book. This replaces the usual list/grid dashboard with a genuinely branded tactile object that doubles as empty-state and first-run UX.
5. **Vinyl-themed vocabulary as a first-class UX design.** "Track" for a page, "Voice Booth" for the recorder, "press it to vinyl" / "Pressing your journal entries" for transcription steps, "the record's still spinning" for offline. This is a consistent, coded-in brand personality — not a logo reskin.
6. **Bubble-menu + pen-button + edge-tabs three-piece floating UI.** Universal actions (new, sort, filter, voice, logout) float on every page via the ☰ bubble; the pen button toggles the drawing toolbar and positions it adjacent; edge tabs give first/prev/next/last/tag/delete at the screen border. Positions persist to localStorage (`jyrnyl.menu.pos` / `jyrnyl.pen.pos`) so the interface remembers how each user arranged it.
7. **Six-mode AI voice pipeline with a font-aware page splitter.** Verbatim, Study Notes, Meeting Minutes, Journal Entry, Outline, Custom — Claude-reshaped output is chunked into A5-sized pages by geometry (`charsPerLine = 1380 / (pt × 0.6)`, `linesPerPage = 2000 / (pt × 1.5)`) and never splits mid-word.
8. **PNG custom template backgrounds with magic-number validation + drag-reorder.** Users upload any PNG (5 MB, `0x89 P N G` checked server-side) as a reusable page template, optionally locked-on-close, orderable alongside system templates via HTML5 DnD. Turns Jyrnyl into a personalized planner or bullet-journal engine without a template marketplace.
9. **Pro-email whitelist override.** Ops can flip specific addresses to Pro via `pro.emails=` in the properties file without touching the database — a rare and useful operational lever for beta programs and VIP users.
10. **Lean stack, installable PWA, zero client framework.** Plain Java 17 servlets + MySQL + vanilla JS, no React/Vue/Angular, no Electron wrapper — yet it installs to the home screen on iPad and Android with shortcuts for "Drop a new track" and "Record" and a branded offline fallback.

---

## 6. Screenshots Description

Descriptions reflect the current `main` branch, including the April 2026 branding and UX overhaul.

### Login (`index.jsp`)

Warm cream background with a faint gold radial glow at top-left and a soft brown radial glow at bottom-right. Dead center sits a single cream card (`max-width: 420 px`) with a subtle 1 px warm-gray border, paper-style shadow, and an inner border inset 18 px. The card is **filled edge-to-edge with `jyrnyl-logo-square.svg`** — no heading, no subtitle, no footer copy. Floating beneath the card as its own element: a brown pill-shaped **"Sign in with Google"** button (white "G" SVG icon, min-height 48 px). No navbar, no tagline, no secondary links. The page title is `"Jyrnyl — Record your life."`.

### Dashboard — Cover Landing (first load, default)

Full-viewport leather-brown radial desk (`#5a3d28` → `#3e2a1a` → `#281a0e`) with a subtle vertical-plank repeating gradient texture. No header, no chrome, no navigation arrows. Centered on the desk: the book cover scaled to single-page proportions (`aspect-ratio: 148/210`, `max-width: min(420px, 72vh)`), leather gradient with a gold-foil double border at 22 px and an embossed inner frame at 32 px whose bottom is pushed up to 56 px. Inside the frame: the `jyrnyl-logo-square.svg` rendered in gold-stamp style (`mix-blend-mode: screen` + `sepia(0.6) saturate(2.2) brightness(0.75) contrast(1.1)`) so the dark SVG background vanishes and the record grooves + "JYRNYL / RECORD YOUR LIFE" wordmark glow as warm gold. The gap between the two border frames at the bottom holds: a 22 px avatar, the user's display name, a muted gold dot separator, and **"N tracks"** in small italic. At the bottom edge (above safe-area), a gently pulsing italic hint in faded gold: **"Tap the cover to open · swipe to turn the page."** The only floating UI visible is the bubble menu trigger (☰).

### Dashboard — Book View (after opening)

Same leather desk, now with the book shown as a true two-page spread (desktop ≥ 721 px) with a gold-shadow spine between the pages. Flanking the book: four circular nav arrows (first, prev, next, last) — cream 52 px, brown chevrons, opacity 0.3 when disabled. Left and right pages each render as a miniature A5 sheet with warm-cream background, inset shadow at the spine side, lazy-fetched ink thumbnail (strokes, text-layer skeleton bars, and custom PNG backgrounds all rendered via `<canvas>`), meta line `"{Mar 3, 2026}  ·  {Lined}"` in italic serif, and any tag chips beneath. Below the book: italic serif status line `"Page 3 of 12"` or `"Pages 3 – 4 of 12"`. On mobile, only the right page is shown. The **"Add Page"** slot after the last real page is a faded cream page with a large circular plus icon (`+`), label **"Drop a new track"**, subscript **"Start your next entry"**. Touching the cover, arrow keys, and 48-px swipes navigate spreads. The bubble menu (☰) is the only persistent chrome.

### Dashboard — List View (Sort pages utility)

Reached only via the bubble menu's "Sort pages" action. Top bar (cream background): left side has serif heading **"Sort your pages"** and italic subhead **"Drag to reorder · tap a page to open it"**; right side has a yellow **"Reorder"** toggle and a brown **"Done"** pill button (`bi-journal-bookmark-fill`) that returns to book view. Below: optional tag-filter chip bar with `Filter:` label + `"Clear"` + `"Manage"` buttons + `"Showing X of Y pages"` counter. Then a vertical stack of notebook-entry cards with 14 px gaps. Each card: warm cream background, left-edge gold-to-transparent binding stripe, 1 px warm-gray border, soft paper shadow. Inside: 58 × 82 px mini thumbnail with a gold masking-tape strip at top, rotated −1.2°, styled per background type; then the creation date in serif brown, template name in italic muted gray, tag chips beneath; far right `#N` order in italic light gray. Hover lifts the card 2 px and reveals a circular trash button at top-right with a burgundy hover tint. While reorder mode is on, the cards get dashed borders and drag opacity; drop-target preview uses a gold tint.

### New Page modal

Opened via the bubble menu's "New track" action (or `?new=1`). Warm cream modal centered over a dim leather backdrop. Title: **"Choose a page template"**. Body: 3-column template grid of cream cards with serif names, a subtle lock icon (bottom right) on templates that lock on close, and a hover × button on user-owned custom templates. A trailing dashed **"Voice"** card (`bi-mic-fill`) links to the Voice Booth. Below the grid, a bordered section `"Create a custom template (count/limit for free users)"` with hint `"Upload a PNG to use as the page background."`, a name input, a dashed drop-zone (`"Click to choose a PNG file"`) with live preview (`140 × 200 px` max) and filename + size, a `"Lock pages on close"` checkbox, and a brown **"Create Template"** submit button. An error slot shows validation / upload messages. A persistent dismissable alert banner at the top of the body surfaces server errors like "Cannot delete — pages still use this template."

### Editor — Desktop (`editor.jsp`, "Studio")

Full-viewport warm-cream stage with gold + sienna radial glows. Dead center: an A5 paper rectangle (1480 × 2100 ratio) with `#fffdf7` background and four stacked warm shadows, a 1 px inset border, and three layered surfaces inside: `<canvas>` ink, `#image-layer` (Pro), `#text-layer`. No visible navbar, no top toolbar — the chrome is entirely floating:
- **Bubble menu (☰)** — brown draggable bubble, usually snapped to one edge.
- **Pen button (✏️)** — gold draggable bubble, default right edge ~78 % down.
- **Edge tabs** — translucent tabs at left / right / top-center edges with paired icons; hover → gold glow pulse; tap → brief flash then save-and-navigate.
- **Floating toolbar pill** — appears when the pen button is tapped: dark chocolate pill with backdrop-blur, rounded ends, containing pen / eraser / text / (image if Pro) / fontsize (when text selected) / color / thickness + readout / undo / redo icons. Auto-hides 5 s after appearing unless drawing; hides instantly when the user starts inking so chrome moves out of the way.
- **Save toast** — italic serif pill at top center, flashes `"Saved"`, `"Locked"`, or `"Error …"` driven by `#save-status` mutations.

The `<title>` is **"Jyrnyl — Studio"**. User-select is disabled to prevent text-selection interference with inking.

### Editor — Tablet Immersive (`body.tablet-immersive`)

Same canvas but the viewport is taken over entirely — no padding, no margins. `touch-action: none` on the canvas, `contextmenu` blocked, two-finger swipes flip pages via `jyrnyl:save-and-navigate` with a clean stroke-cancel. The bubble menu and pen button float as on desktop. The pre-overhaul FAB, slide-out panel, and reparented navbar are **gone** from this build — the bubble menu replaced them.

### Voice Booth (`voice-record.jsp`, `"Jyrnyl — Voice Booth"`)

Warm cream background with the same gold + sienna radial glows. Top navbar: `"Jyrnyl"` brand link (left), tier label (`<i class="bi bi-star-fill"></i> Pro` for Pro users, `"Free tier"` for free), and a `"Back"` button. Centered content column (`max-width: 760 px`). Header: serif heading **"Voice Booth"** with italic subhead **"Speak or upload — we'll press it to vinyl."** Below, a cream card with a pill-shaped tab switcher: **Record** (mic icon) / **Upload** (up-arrow icon); active tab has a solid brown background. Record tab: a 72 px brown/gold circular mic button that pulses burgundy when active, a serif "00:00" elapsed counter, italic hint `"Tap to start speaking"`, and a scrollable live-transcript box. Upload tab: dashed drop-zone `"Drop audio file here or click to browse"` with hint `"MP3, WAV, WebM, M4A, OGG, FLAC · max 25 MB"`, shows a `bi-file-earmark-music` file-meta row after selection. Below the tabs: a `"Transcript"` textarea (editable, placeholder `"Your transcript will appear here. You can edit before creating pages."`). Then a **Processing Mode** grid of 6 icon cards (Verbatim selected by default) with gold `Pro` badges and lock/unlock icons reflecting trial usage, plus an amber upgrade hint: `<i class="bi-star-fill"></i> This feature requires Jyrnyl Pro. Upgrade coming soon!`. A custom prompt textarea appears when Custom is selected. Form row: font-size `<select>` (2 – 64 pt, default 4) and tag selector chips with inline `"Add"` form. Footer: `"Cancel"` and a brown **"Create Pages"** button (`bi-journal-plus`). A full-screen progress overlay dims the page during submission, showing a spinner, title **"Working on it"** (default) or **"Done"** (success), and a ticking message sequence through **"Uploading audio…"** → **"Transcribing…"** → **"Processing with AI…"** → **"Pressing your journal entries"** (vinyl branding) → **"Created N page(s). Redirecting…"**.

---

## 7. Current Deployment

- **Public URL:** https://jyrnyl.com/ — deployed as Tomcat's **ROOT context** (no `/jotpage/` path prefix). The old `/jotpage/*` paths return a hard 404 — intentional, no redirect grace period.
- **Origin server:** IONOS DCD VPS at `66.179.248.54`, Ubuntu 24.04 LTS.
- **DNS / TLS:** Cloudflare proxied (orange cloud), SSL mode **Full (Strict)** with a 15-year Cloudflare Origin Certificate installed at `/etc/nginx/ssl/jyrnyl.{crt,key}`.
- **Reverse proxy:** nginx 1.24 terminates TLS and proxies to Tomcat on `127.0.0.1:8080`. Config at `/etc/nginx/sites-available/jyrnyl`.
- **App server:** Apache Tomcat 10.1.16 (Ubuntu package). CATALINA_BASE = `/var/lib/tomcat10`, CATALINA_HOME = `/usr/share/tomcat10`. WAR deployed as `/var/lib/tomcat10/webapps/ROOT.war`. JAVA_OPTS in `/etc/default/tomcat10`: `-Xms256m -Xmx1024m -XX:+UseG1GC`.
- **JDK:** OpenJDK 17 at `/usr/lib/jvm/java-17-openjdk-amd64`.
- **Database:** MySQL 8 (Ubuntu package), socket at `/var/run/mysqld/mysqld.sock`. App user `jotpage@localhost` scoped to the `jotpage` database; root uses `auth_socket` (no password — OS root authenticates by socket).
- **Whisper:** venv at `/opt/whisper/venv` (owned by `deploy`), symlinked at `/usr/local/bin/whisper`. Model cache pre-populated at `/var/lib/tomcat/.cache/whisper/base.pt` so the first transcription doesn't pay the download cost.
- **FFmpeg:** `/usr/bin/ffmpeg`, on PATH.
- **Firewall (UFW):** allow 22/80/443, deny everything else. Timezone `America/Chicago`.
- **User accounts:** `root` (setup only, key-only SSH), `deploy` (sudoer, scp target), `tomcat` (app runtime, nologin).
- **Build / deploy pipeline** — build locally, scp, drop into webapps as ROOT.war:
  1. `mvn clean package` (produces `target/jotpage.war` — `<finalName>` is still `jotpage`, rename happens at deploy time).
  2. `scp target/jotpage.war deploy@66.179.248.54:/home/deploy/jyrnyl/`
  3. On the server: `sudo cp /home/deploy/jyrnyl/jotpage.war /var/lib/tomcat10/webapps/ROOT.war && sudo chown tomcat:tomcat /var/lib/tomcat10/webapps/ROOT.war`
  4. Tomcat auto-redeploys in ~1 s; no restart required.
  5. Users may need one hard refresh — the service-worker cache version `v9` is bumped with each release so most clients pick up changes automatically.
- **Watch logs during deploy:** `sudo journalctl -u tomcat10 -f --since "30 seconds ago"`.
- **Properties file in prod:** `/var/lib/tomcat10/conf/jotpage.properties` (auto-resolved from `{catalina.base}/conf/`). `google.redirectUri = https://jyrnyl.com/oauth2callback`, `db.username = jotpage`, `ffmpeg.path` empty, `whisper.command = /usr/local/bin/whisper`.
- **Note on SSH quirk (Ubuntu 24.04):** MySQL client commands need `LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu` prefix to avoid an ABI trip, e.g. `LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu mysql --socket=/var/run/mysqld/mysqld.sock -u jotpage -p`.

---

## 8. What Changed (vs. `JYRNYL_PRODUCT_SUMMARY.md`)

Material changes since the first product summary was written:

### Branding & UX
- **New cover-landing state** on the dashboard — full-viewport leather desk with the book cover centered, no chrome, pulsing `"Tap the cover to open · swipe to turn the page"` hint. Previously book view opened directly on a spread.
- **Login page redesigned** — old card with a "Jyrnyl" serif wordmark + tagline + footer was replaced by the full-bleed `jyrnyl-logo-square.svg` card; sign-in button now floats as a separate element outside the card.
- **Book cover overhaul** — leather radial gradient with gold double-border frame and embossed inner frame, gold-stamped `jyrnyl-logo-square.svg` emblem (via `mix-blend-mode: screen + sepia filter`), and a footer (avatar + name + track count) that sits in the gap between the two frames.
- **List view demoted to "Sort pages" utility** — no longer a primary view. Accessed only through the bubble menu's "Sort pages" action, which lands on `?view=list&sort=1` and clears any active tag filter so drag-reorder is predictable. New top bar heading `"Sort your pages"` + italic subhead + **Done** button that returns to book view. The old view toggle (book/list) on the navbar is gone — the navbar is gone entirely.
- **Floating-UI overhaul.** Replaced navbar + top toolbar + FAB + slide-out panel with three floating pieces:
  - **Bubble menu (☰)** — draggable 56 px trigger on both dashboard and editor with a 5-action radial fan (New track, Sort pages, Filter by tag, Voice booth, Logout). Position persists to `localStorage('jyrnyl.menu.pos')`.
  - **Pen button (✏️)** — editor-only gold edge-snap button that toggles the drawing toolbar and positions it adjacent. Position persists to `localStorage('jyrnyl.pen.pos')`. Fades while actively drawing.
  - **Edge tabs** — left/right edge for first/prev/next/last, top-center for tag/delete. Save-then-navigate flow via MutationObserver on `#save-status`. Gold-glow pulse on hover, flash on tap, spinner while saving, invisible while drawing.
- **Vinyl vocabulary visible everywhere.** `"Drop a new track"` for the Add-Page CTA, `"N track"`/`"N tracks"` in the cover footer, `"Voice Booth"` as the voice page title, `"Speak or upload — we'll press it to vinyl."` subhead, `"Pressing your journal entries"` as a progress stage, `"The record's still spinning — we just can't reach the server right now."` on the offline page, `"Jyrnyl — Studio"` as the editor `<title>`.
- **Tool-preference persistence across the editor.** Color, thickness, and font point are now saved to `localStorage('jyrnyl.tool.prefs')` and restored on load.

### Voice & AI
- **`VoiceModeValidator` added** (new file `util/VoiceModeValidator.java`). Pre-flight heuristic per mode returns HTTP 422 with a user-facing message before spending a Claude call.
- **Whisper is no longer tier-gated** in `VoiceRecordServlet` — any tier can get server-side transcription when an audio file is uploaded. The AI reshaping step is what gates behind the 1-trial-per-mode rule; Verbatim with Whisper works for free users.
- **Progress overlay ticker** now cycles through vinyl-branded stages (**"Pressing your journal entries"**) instead of the older clinical copy.
- **`trialUsage` JSON** now counts only `complete` + `processing` jobs, so a failed run doesn't burn the free trial.

### Data model / migrations
- **`migration 004_add_pagetype_sort_order.sql`** — adds `page_types.sort_order` and back-fills it (system templates sorted by id; user templates by creation date + 100 offset). Powers the drag-reorder in the template modal.
- **`migration 005_add_image_layers.sql`** — adds `pages.image_layers MEDIUMTEXT NULL`. Image overlay tool now reads/writes this column.

### Tier / gating
- **Page deletion is now allowed on every tier.** Previously it was a Pro-only feature; `TierCheck` still carries a `FEATURE_EXPORT` constant but the deletion gate is fully removed. A vestigial `bubbleMenu.setActionVisible('delete', false)` call for non-Pro users remains in `editor.jsp` but is functionally moot.
- **Error-return code for bad AI input is HTTP 422** (not 400/403), distinguishing "your transcript doesn't match the mode" from "you're not allowed to use this mode."

### Infrastructure
- **Now live at `https://jyrnyl.com/`** as the root context (deployed on 2026-04-15). Previously the app was deployed under `https://superiorstate.biz/jotpage/` per the v1 summary.
- **New prod box** — IONOS DCD VPS at `66.179.248.54`, Ubuntu 24.04 LTS, dedicated to Jyrnyl. Cloudflare proxied with a 15-year Origin Certificate, nginx 1.24 → Tomcat 10.1.16 on 127.0.0.1:8080.
- **Hard cut from `/jotpage/*`.** The old path returns 404; no redirect grace period. All OAuth redirect URIs now point at `https://jyrnyl.com/oauth2callback`.
- **Service worker cache `v9`** (bumped from a lower version in v1; matches `?v=9` cache-bust on editor JS).

### Small UI / spec corrections vs. v1
- **Tablet immersive mode was slimmed down (Phase 5).** FAB, slide-out panel, reparented navbar/tag-bar, and toolbar auto-hide timer were removed. What remains: auto-activation, 30 s auto-save, gesture suppression, two-finger save-and-flip swipe.
- **Image tool is Pro-only by conditional rendering.** `editor.jsp` only emits the `#tool-image` button when `${isPro}`; non-Pro users don't see it at all.
- **Login page strings.** v1 showed "Jyrnyl / *Your personal liner notes* / Sign in with Google / *Drop the needle on a new thought.*" — current build shows only the logo card and the Google sign-in button.

---

## 9. Roadmap Items

### Short-term (next 30 days)

- **Rotate production secrets** exposed during chat-based setup on 2026-04-15: Google OAuth client secret, Anthropic API key, MySQL `jotpage` password.
- **Fix the first-word dedup bug** in `computeOverlapAppend` (`js/voice-recorder.js`). Short tokens (3–5 chars: "the", "and", "yes") slip through the `n >= 6` minimum overlap floor and get appended twice in the live transcript. Lower the floor to 2 chars and add a word-boundary last-token check. Documented in `.claude/memory/project_voice_booth_rethink.md`.
- **Investigate intermittent "logs out after a few clicks" on tablet.** Reproduces on freshly-loaded editor pages — not a stale-tab issue. Needs DevTools Network panel capture to see which request triggers the redirect to Google OAuth.
- **Reapply Phase 1/2/3 tablet work** (FAB drag/movability, tap-fallthrough fix, pen-tap IME fix) against the post-overhaul editor. The old Phase work was stashed when yesterday's dashboard/editor overhaul landed and needs to be re-done from scratch against the new code.
- **Fix book-view thumbnails for custom-background pages** — currently show blank because the dashboard JSON payload omits the base64 `backgroundData` for custom templates.
- **Legacy voice-page font-size compat** — pages created before the point-to-pixel scaling fix store raw-pixel `fontSize` values; they display correctly via a compat path, but the editor dropdown shows the wrong selection.
- **Touch drag-to-reorder in list view.** HTML5 DnD doesn't support touch natively; current reorder mode is desktop-only. Needs a touch polyfill or long-press drag.
- **Finish the export lock.** `FEATURE_EXPORT` exists in `TierCheck.java` with a user-facing message, but no export servlet yet.
- **Automated DB backups** — cron `mysqldump` → `/home/deploy/backups/` with retention.
- **Uptime monitoring / alerting** — no external check configured yet.

### Medium-term (60–90 days)

- **Stripe integration for Pro tier.** `user_subscriptions` schema is scaffolded with `stripe_customer_id`, `stripe_subscription_id`, `expires_at`, and `SubscriptionDao.isProUser()` already honors expiration — but there's no checkout flow, no webhook receiver, no billing portal. The "Upgrade coming soon!" hint in the voice card is placeholder copy.
- **Export / download pages.** Likely targets: per-page PNG, multi-page PDF of the current notebook, and a ZIP with ink/text JSON for full portability.
- **Voice Booth UX rethink.** Tabled on 2026-04-16 after the first compactness pass. The six-card mode grid is the root cause of the "too much on screen" feeling. When revisited, consider progressive disclosure of Pro-only modes, a two-column layout, or hiding the mode grid behind a collapsible section. Don't do incremental tweaks — start fresh.
- **Search across pages.** Full-text search over `text_layers` and `ai_jobs.output_text`; currently only tag filtering is available.
- **Proper admin dashboard.** Replace the `pro.emails` properties whitelist with a DB-backed admin console for tier flipping and usage inspection.
- **Alternate AI providers.** `ClaudeService.sendRequest()` was built to be easily swappable; adding OpenAI, a local Llama, or an open-source model behind the same interface is the natural next step.
- **More voice processing modes.** Candidates from user feedback: Email draft, Task list, Code review notes, Therapy reflection.
- **Audio-minutes quota tracking.** `UsageDao.incrementAudioMinutes()` and the `audio_minutes_processed` column are scaffolded but not written from code — wire them up and surface in the UI.
- **Multilingual Whisper.** Currently hard-coded `--language en`; promote to a per-request or user-preference setting.
- **Granular autosave + offline queue.** Save strokes to IndexedDB and sync when the network returns, so the offline page is a genuine working state rather than just a fallback.
- **CSRF tokens on mutation endpoints.** Currently all JSON mutation endpoints rely solely on session cookie — fine for now, worth hardening before wider launch.

### Long-term (6+ months)

- **Native iOS and Android apps.** Wrap the PWA to unlock Apple Pencil tilt, proper palm rejection, and OS-level file-open handlers for audio.
- **Desktop app.** Tauri or Electron shell around the web UI for dock/tray presence and a system-wide quick-capture hotkey.
- **Collaborative / shared notebooks.** Multi-user, per-page permissions, optional commenting.
- **Handwriting-to-text OCR.** Run ink-layer recognition to make drawn notes searchable alongside typed text.
- **End-to-end encrypted notebooks.** Optional zero-knowledge mode for journals; server stores ciphertext only.
- **Template marketplace.** User-submitted PNG templates with a gallery, featured collections, and revenue share.
- **Calendar / schedule integrations.** Link pages to calendar events; migration 003 removed the earlier calendar template rows, but the enum values are still in `page_types.background_type` for a re-introduction.
- **Voice entry in low-resource mode.** A browser-only pipeline path that skips Whisper entirely — useful if we ever open-source the stack, or for privacy-sensitive users.
- **Skins / theme packs.** Promote the existing CSS-variable theme into a user-selectable theme picker (warm Moleskine, dark leather, high-contrast, etc.). High perceived value for low effort.
- **B-side / locked pages surface.** The vinyl vocabulary reserved "B-side" for private/locked pages; not yet in UI.

---

*Generated from the current `main` branch source tree. Source documents: `JOTPAGE_FULL_PROJECT_DOC.md`, `.claude/memory/*.md`, and a full sweep of `src/main/java/com/jotpage/**` and `src/main/webapp/**` as of 2026-04-16.*

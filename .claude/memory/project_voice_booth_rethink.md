---
name: Voice Booth UX rethink is tabled
description: /app/voice-record feels too complicated — Kevin wants a future UX pass before adding more features there.
type: project
---

The Voice Booth page at `/app/voice-record` (JSP: `src/main/webapp/jsp/voice-record.jsp`) is functionally working but visually busy. On 2026-04-16 after the first compactness pass (smaller header, smaller mic, tighter mode cards) Kevin's feedback was: "may be smaller, it just seems too complicated a page, hard to understand all the features, needs a rethink, but we can table."

**Why it's tabled:** a UX rethink done now would compete with other higher-priority work and would likely have to be redone once the mode taxonomy (verbatim / study notes / meeting minutes / journal / outline / custom) is reconsidered.

**How to approach when resuming:** don't propose incremental tweaks to voice-record.jsp layout. Start with a fresh UX pass — consider progressive disclosure of the Pro-only mode cards, a simpler two-column layout, or hiding the mode grid behind a collapsible section. The current six-card grid is the root cause of the "too much on screen" feeling.

## Bugs closed on 2026-04-16 (commit history)

- ✅ **First-word doubling in live transcript dedup.** The `computeOverlapAppend` helper in `src/main/webapp/js/voice-recorder.js` had `n >= 6` as its minimum overlap length, so short first words (2–5 chars: "hello", "the", "and") slipped through and got appended twice on session restart. Fixed by lowering the floor to `n >= 2` AND requiring word boundaries on both sides of the overlap.
- ✅ **Pen-tap on text block didn't raise Android keyboard.** Fixed in `ink-engine.js` — added `inputmode/role=textbox/aria-multiline` on the contenteditable, plus a synthetic click after pointerup that re-enters Chrome's touch-focus IME path.
- ✅ **Accidental logout from bubble menu.** Not on voice-record, but a related tablet issue. Root cause diagnosed via Tomcat access log tail: `GET /logout` was actually firing because a single finger gesture that opened the ☰ radial could land on the Logout item as the radial slid into place under the finger. Fixed by gating radial items: they don't respond until a brand-new pointerdown lands. See `bubble-menu.js` `awaitingFreshPointer`.
- ✅ **Bubble menu was edge-snapped only and could overflow at corners.** Replaced `{edge, offset}` with free `{x, y}` position state. Radial layout now fans toward viewport center; if the 180° fan doesn't geometrically fit (any item would clamp to a viewport edge), falls back to a vertical column going whichever direction has more room.

## Open items for a future Voice Booth session

- UX rethink per paragraph 1 above.
- Server-side `VoiceModeValidator` ships sensible defaults but its thresholds and phrase lists are hand-tuned against a small sample of recordings. Worth revisiting after real usage data comes in.

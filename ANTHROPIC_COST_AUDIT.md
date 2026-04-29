# Anthropic API Cost Exposure Audit

**Prepared:** 2026-04-28  
**Model audited:** `claude-sonnet-4-20250514` (as configured in `ClaudeService.java`)  
**Scope:** Pure analysis — no code changes proposed in this document.

---

## Executive Summary

Jyrnyl currently has **zero enforcement guardrails for Pro users** on Anthropic API usage: no monthly job cap, no daily rate limit, no input-length ceiling, and no token logging. The cost-per-call ranges from ~$0.02 for a short verbatim transcript to ~$0.10 for a maximum-length recording on the worst-case mode, but these numbers are dwarfed by the nightmare scenario: the `browserTranscript` POST parameter accepts arbitrarily large text with no server-side size check, meaning a malicious Pro user can submit a 50,000-token fake "transcript" plus a long custom prompt and drive input costs to ~$18/call with no friction. A Pro subscription priced at $5–10/month breaks even against API costs at roughly 50–100 AI jobs/month with max-length recordings on custom mode — a threshold an aggressive user could hit in a single afternoon. The highest-priority fixes are input truncation, a customPrompt length cap, and a monthly AI job cap for Pro users; all three are small code changes with zero UX impact for typical users.

---

## Current Call Flow

```
POST /app/voice-record
│
├─ requireUser() ─── session check (authentication gate)
│
├─ TierCheck.isPro()
│   ├─ FREE USER → aiJobDao.countByUserIdAndJobType() ≤ 1 (per mode)
│   │              → blocked after 1 trial
│   └─ PRO USER  → *** NO FURTHER CHECKS *** (all limits bypassed)
│
├─ Multipart parse → audio temp file (max 25 MB enforced by @MultipartConfig)
│
├─ aiJobDao.create()  ← status = "processing", input_text NOT stored here
│
├─ WhisperService.transcribe(audioTempFile)
│   └─ Falls back to req.getParameter("browserTranscript")
│      *** NO LENGTH CAP on browserTranscript — unbounded POST param ***
│
├─ VoiceModeValidator.validate()
│   ├─ Checks CONTENT QUALITY (word minimums, signal words)
│   └─ Does NOT check maximum length or token count
│
├─ IF jobType != "verbatim":
│   └─ ClaudeService.process(transcript, jobType, customPrompt)
│       ├─ systemPromptFor() → concatenates hardcoded system + customPrompt
│       │  *** customPrompt is user-supplied, NO length cap ***
│       ├─ HTTP POST → api.anthropic.com/v1/messages
│       │   model: claude-sonnet-4-20250514
│       │   max_tokens: 4096 (ALL modes, hardcoded)
│       └─ Returns assistant text
│          *** usage.input_tokens / usage.output_tokens NEVER READ ***
│
├─ aiJobDao.updateStatus("complete", outputText, null)
│  *** No token counts stored. No cost stored. ***
│
└─ usageDao.incrementAiJobs() ← counter incremented but NEVER enforced for Pro
```

**Trigger summary:** Every non-verbatim voice submission by a Pro user fires one Anthropic API call synchronously on the servlet thread. No async queuing, no throttle, no circuit breaker.

---

## Token Economics Table

### Pricing basis: `claude-sonnet-4-20250514`
| Token type | Rate |
|---|---|
| Input | $3.00 / 1M tokens |
| Output | $15.00 / 1M tokens |

*Note: Verify current pricing at console.anthropic.com before making business decisions — rates are subject to change.*

### System prompt sizes (character-counted from `ClaudeService.java`)

| Mode | System prompt (approx tokens) | Notes |
|---|---|---|
| `study_notes` | ~75 | Fixed |
| `meeting_minutes` | ~55 | Fixed |
| `journal_entry` | ~55 | Fixed |
| `outline` | ~55 | Fixed |
| `custom` | ~17 + N (user-supplied) | **Unbounded** — user controls system prompt size |

### Input size assumptions
| Recording length | Approx words | Approx transcript tokens |
|---|---|---|
| Short (≤ 5 min) | ~750 words | ~1,000 tokens |
| Medium (25 min) | ~3,750 words | ~5,000 tokens |
| Long (60+ min / 25 MB max) | ~9,000 words | ~12,000 tokens |

The 25 MB `@MultipartConfig` ceiling is the only hard cap on audio size. At low bitrates (8 kHz mono), 25 MB can hold 90+ minutes of speech, pushing transcripts well above 12,000 tokens.

### Cost per call at Sonnet 4 pricing

**Built-in modes (study_notes / meeting_minutes / journal_entry / outline):**

| Input size | Total input tokens | Typical output (1,200 tok) | Worst-case output (4,096 tok) | Typical cost/call | Worst-case cost/call |
|---|---|---|---|---|---|
| Short (5 min) | ~1,060 | 1,200 | 4,096 | **$0.021** | **$0.065** |
| Medium (25 min) | ~5,060 | 1,200 | 4,096 | **$0.033** | **$0.077** |
| Long (60+ min) | ~12,060 | 1,200 | 4,096 | **$0.054** | **$0.097** |

**Custom mode — with a 2,000-token user prompt:**

| Input size | Total input tokens | Typical output | Worst-case output | Typical cost/call | Worst-case cost/call |
|---|---|---|---|---|---|
| Short | ~3,017 | 1,200 | 4,096 | **$0.027** | **$0.070** |
| Medium | ~7,017 | 1,200 | 4,096 | **$0.039** | **$0.082** |
| Long | ~14,017 | 1,200 | 4,096 | **$0.060** | **$0.103** |

**Custom mode — nightmare: 10,000-token prompt + 50,000-token fake browserTranscript:**

| Scenario | Total input tokens | Worst-case output | Cost/call |
|---|---|---|---|
| Large prompt + oversized transcript | ~60,017 | 4,096 | **~$0.242** |

*This scenario requires zero audio upload — the attacker POSTs `browserTranscript` directly as a form field. No server-side check prevents it today.*

### Note on `max_tokens = 4096`
`MAX_TOKENS` is a ceiling, not a guarantee. Actual output for `outline` is typically 200–500 tokens; for `journal_entry` 600–1,500 tokens; for `study_notes` 800–2,000 tokens. The 4,096 ceiling over-allocates budget for every mode except `custom`. Right-sizing would not change typical cost materially but eliminates the tail risk of paying for 4,096 tokens on a mode that rarely needs them.

---

## User Profile Cost Models

Pricing: $3.00/MTok input, $15.00/MTok output (Sonnet 4).

### Profile 1 — Light (5 AI jobs/month, short recordings, built-in modes)

| | Tokens | Cost |
|---|---|---|
| Input: 5 × 1,060 | 5,300 | $0.016 |
| Output: 5 × 1,200 (typical) | 6,000 | $0.090 |
| **Monthly total** | | **~$0.11** |

*Well within a $5/month Pro subscription. No problem here at all.*

### Profile 2 — Moderate (20 AI jobs/month, mixed lengths, built-in modes)

Assumed average: 3,060 input tokens (mix of 5-min and 25-min recordings), 1,500 output tokens.

| | Tokens | Cost |
|---|---|---|
| Input: 20 × 3,060 | 61,200 | $0.184 |
| Output: 20 × 1,500 | 30,000 | $0.450 |
| **Monthly total** | | **~$0.63** |

*Still well within a $5/month subscription. Comfortable margin.*

### Profile 3 — Heavy/Abusive (100 AI jobs/month, custom mode, 2K-token prompts, max-length recordings)

| | Tokens | Cost |
|---|---|---|
| Input: 100 × 14,017 | 1,401,700 | $4.205 |
| Output: 100 × 4,096 (worst case) | 409,600 | $6.144 |
| **Monthly total** | | **~$10.35** |

*Exceeds a $10/month Pro subscription. Breaks even with a $5/month subscription at roughly 50 jobs at this intensity.*

### Break-even analysis

| Pro price | Break-even (custom mode, max recordings, max output) |
|---|---|
| $5/month | ~50 AI jobs/month |
| $10/month | ~100 AI jobs/month |
| $15/month | ~145 AI jobs/month |

A determined abuser using the `browserTranscript` bypass (no audio file, 50K-token fake transcript, 10K custom prompt) could force ~$24/month in API costs from a single account, using a script that fires requests in parallel — the servlet has no concurrency limit per user.

---

## Guardrails Gap Analysis

### What exists today

| Control | Where | Applies to | Enforces? |
|---|---|---|---|
| Session authentication | `requireUser()` | All users | Yes — must be logged in |
| Free trial cap (1 per mode) | `VoiceRecordServlet.doPost()` | Free users only | Yes — hard block at 1 job/mode |
| 25 MB upload cap | `@MultipartConfig` | All users | Yes — Tomcat rejects oversized files |
| Content quality check | `VoiceModeValidator` | All non-verbatim | Yes — minimum word counts, content signals |
| `ai_jobs_run` tracking | `UsageDao.incrementAiJobs()` | All non-verbatim | Tracked, **never enforced for Pro** |
| `audio_minutes_processed` tracking | `UsageDao.incrementAudioMinutes()` | — | Column exists; **`incrementAudioMinutes()` is never called in `VoiceRecordServlet`** |
| HTTP timeout | `READ_TIMEOUT_MS = 120s` | API call | Yes — prevents hung threads, not abuse |

### What is absent

| Missing control | Impact |
|---|---|
| **Monthly AI job cap for Pro** | No ceiling on API spend from any single Pro account |
| **Daily or hourly rate limit** | A script can fire 100 jobs in a single session |
| **Max transcript length before Claude call** | `browserTranscript` is passed directly to Claude with zero truncation |
| **Max `customPrompt` length** | User-controlled system prompt with no upper bound |
| **Token counting / cost logging** | Zero visibility into per-call or per-user spend |
| **`usage.input_tokens` / `usage.output_tokens` capture** | The API response includes this data; `ClaudeService.sendRequest()` discards it entirely |
| **`ai_jobs.input_text` populated on creation** | `AiJobDao.create()` does not store the transcript — only `audio_file_path` |
| **Cost alerting** | No mechanism to detect runaway spend by a user or in aggregate |
| **Concurrent-request limit per user** | Multiple browser tabs / script threads = multiple simultaneous Claude calls |

### `TierCheck` for Pro: confirmed no-op
`TierCheck.isPro(user)` returns `true` → the check `if (!isPro)` in the servlet is bypassed entirely. `TierCheck.getMonthlyPageLimit()` returns `UNLIMITED` for Pro users. There is no equivalent `getMonthlyAiJobLimit()` method. The tier check is structurally correct for pages but simply does not exist for AI jobs on the Pro path.

---

## Risk Matrix

Likelihood: **1** (rare/theoretical) → **5** (near-certain at scale)  
Impact: **1** (negligible) → **5** (material financial loss or user-facing harm)

| Risk | Likelihood | Impact | Score | Notes |
|---|---|---|---|---|
| Single heavy Pro user exceeds subscription value | 3 | 3 | **9** | Plausible at 50–100 jobs/month with long recordings |
| Malicious actor uses `browserTranscript` bypass to send oversized inputs | 2 | 5 | **10** | No audio file needed; 50K token payload = ~$24/month/user |
| Long `customPrompt` amplifies cost on each call | 3 | 4 | **12** | Any Pro user can supply a 10K-token prompt; no cap |
| Script fires 100+ jobs/day from one account | 2 | 5 | **10** | No rate limit; each call ~$0.10 worst case |
| Stuck `processing` job (Tomcat restart mid-call) | 4 | 1 | **4** | Known open issue (#14 in JYRNYL-OPEN-QUESTIONS.md); low cost impact |
| `audio_minutes_processed` never incremented | 5 | 2 | **10** | Data quality issue — the column exists, `incrementAudioMinutes()` exists, but is never called in the servlet |
| No token data in `ai_jobs` limits future analytics | 5 | 2 | **10** | Can't build per-user cost reports without it |
| `custom` mode produces adversarial system prompts | 2 | 2 | **4** | Prompt injection risk is Anthropic-side; financial risk is the bigger concern |

**Highest combined risk:** Long `customPrompt` × no rate limit × no input truncation. These three gaps interact multiplicatively.

---

## Ranked Recommendations

Effort: **S** (small — hours) / **M** (medium — days) / **L** (large — weeks)  
Type: **Code** / **Config** / **Architecture**

### 1. Cap `customPrompt` length server-side — Priority: Critical | Effort: S | Type: Code

`VoiceModeValidator` already checks that `customPrompt` is ≥ 10 chars; add a symmetric upper bound (e.g., 2,000 characters ≈ ~500 tokens) before the Claude call. This is a single `if (cp.length() > MAX_CUSTOM_PROMPT_CHARS)` guard in `VoiceRecordServlet` or `VoiceModeValidator`. Without this, one Pro user with a large prompt and frequent submissions is the highest per-call cost amplifier.

### 2. Truncate transcript before sending to Claude — Priority: Critical | Effort: S | Type: Code

Add a `truncateToTokenBudget(String text, int maxWords)` call between `VoiceModeValidator.validate()` and `claudeService.process()` in `VoiceRecordServlet`. Recommended ceiling: **6,000 words ≈ ~8,000 tokens**. This caps worst-case input cost at ~$0.024 (input only) and silently trims rather than blocking the request. The `browserTranscript` parameter is the primary attack vector because it requires no audio file; truncation neutralizes it entirely.

### 3. Monthly AI job cap for Pro users — Priority: High | Effort: S | Type: Code

Add a `getMonthlyAiJobLimit(User user)` method to `TierCheck` (e.g., returns 100 for Pro, `UNLIMITED` for admin accounts). In `VoiceRecordServlet.doPost()`, check `usageDao.findOrCreateCurrentMonth().getAiJobsRun()` against this limit before calling Claude — exactly mirroring the existing free-tier page-cap check. The `usage_tracking.ai_jobs_run` column is already being incremented; this change purely adds an enforcement read. Suggested starting cap: **100 AI jobs/month** for Pro, revisable based on observed usage.

### 4. Daily rate limit — Priority: High | Effort: M | Type: Code

The current `usage_tracking` schema tracks monthly totals only. A daily rate limit requires either: (a) a new `daily_ai_jobs` column with a reset-date column, or (b) a `COUNT(*)` query against `ai_jobs WHERE user_id = ? AND created_at >= DATE(NOW())`. Option (b) requires no schema change and can be added to `AiJobDao` as `countTodayByUserId(userId)`. Suggested limit: **10 AI jobs/day** for Pro.

### 5. Capture token usage from API response — Priority: High | Effort: S | Type: Code

The Anthropic API response JSON includes a `usage` field:
```json
{"usage": {"input_tokens": 1247, "output_tokens": 892}}
```
`ClaudeService.sendRequest()` currently parses `content[]` but discards `usage` entirely. Returning a result object (or logging `input_tokens` + `output_tokens`) and storing them in `ai_jobs` (two new INT columns) would unlock all future cost analytics with no additional API cost. This is the foundation for recommendation #7.

### 6. Right-size `max_tokens` per mode — Priority: Medium | Effort: S | Type: Code

`MAX_TOKENS = 4096` is a constant that applies to every mode. Recommended per-mode ceilings based on expected output:

| Mode | Recommended `max_tokens` | Rationale |
|---|---|---|
| `outline` | 1,024 | Concise by design; 4K is ~5× excess |
| `meeting_minutes` | 2,048 | Structured but bounded |
| `journal_entry` | 2,048 | Prose doesn't need 4K |
| `study_notes` | 3,072 | Dense notes can be longer |
| `custom` | 4,096 | Keep full budget — output is unpredictable |

In practice, Claude rarely hits `max_tokens` on well-scoped inputs, so this change mainly reduces worst-case output cost rather than typical cost.

### 7. Per-user monthly cost alerting — Priority: Medium | Effort: M | Type: Code + Config

Once token logging (rec. #5) is in place, add a nightly or per-job check: `SUM(input_tokens * 0.000003 + output_tokens * 0.000015)` per user per month. Log a warning (and optionally email `ekevinmurphy@gmail.com`) when any user crosses a configurable threshold (e.g., $3.00/month ≈ 30% of a $10/month subscription). This is an operational monitoring layer, not a hard block.

### 8. Switch cheaper modes to Haiku — Priority: Medium | Effort: M | Type: Code + Config

Haiku 4.5 pricing is approximately **$0.80/MTok input, $4.00/MTok output** — roughly 1/4 the cost of Sonnet 4. `outline` and `study_notes` are strong candidates: the task is pattern extraction and reformatting, not nuanced reasoning, and Haiku performs well on both at a fraction of the cost.

| Mode | Sonnet 4 (typical/call) | Haiku 4.5 (estimated) | Savings |
|---|---|---|---|
| `outline` (medium input) | $0.033 | ~$0.009 | ~73% |
| `study_notes` (medium input) | $0.033 | ~$0.009 | ~73% |
| `journal_entry`, `custom` | Keep Sonnet | Keep Sonnet | — |

Implementation: add a `modelFor(String jobType)` method to `ClaudeService` or pass the model as a constructor/method argument; read per-mode model from `jotpage.properties` so it's configurable without a redeploy.

### 9. Keep Whisper local (no change) — Priority: Informational

OpenAI Whisper API costs $0.006/minute. For a moderate user doing 20 jobs/month at 15 minutes average: $0.006 × 15 × 20 = **$1.80/month in Whisper costs alone**, on top of Claude costs. The current local CLI subprocess costs nothing in API fees (only VPS CPU). Staying local is the correct economic choice for current traffic. The tradeoff is VPS CPU load and operational complexity, but neither justifies the Whisper API at this scale.

### 10. Fix `audio_minutes_processed` never being incremented — Priority: Low | Effort: S | Type: Code

`UsageDao.incrementAudioMinutes()` exists but is never called in `VoiceRecordServlet`. This means the column is always zero, making the data useless for any future capacity planning. The audio duration can be obtained from `WhisperService` if timed, or estimated from file size. Low urgency but trivially fixable.

---

## Summary Table

| # | Recommendation | Type | Effort | Priority |
|---|---|---|---|---|
| 1 | Cap `customPrompt` length | Code | S | **Critical** |
| 2 | Truncate transcript before Claude call | Code | S | **Critical** |
| 3 | Monthly AI job cap for Pro | Code | S | **High** |
| 4 | Daily rate limit | Code | M | **High** |
| 5 | Capture token usage from API response | Code | S | **High** |
| 6 | Right-size `max_tokens` per mode | Code | S | Medium |
| 7 | Per-user monthly cost alerting | Code + Config | M | Medium |
| 8 | Haiku for `outline` and `study_notes` | Code + Config | M | Medium |
| 9 | Keep Whisper local | No change | — | Informational |
| 10 | Fix `audio_minutes_processed` | Code | S | Low |

Items 1–3 can all be implemented in a single focused session and would eliminate the critical exposure surface before Pro subscriptions go live.

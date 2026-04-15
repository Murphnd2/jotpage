---
name: One step at a time
description: Kevin strongly prefers single-command instructions, not batched multi-step blocks
type: feedback
originSessionId: 148205c1-2b79-4d0c-932b-ebc64dbc6bac
---
When walking through a procedure (install, configure, deploy, migrate), give ONE command / action at a time and wait for confirmation before the next. Do NOT list 3–5 commands as a numbered block expecting the user to run them all.

**Why:** Kevin said verbatim: "please stop listing multiple steps, its always a waste as something prior fails". Earlier commands often error or need substitution — when that happens, later commands in the batch become wrong, and re-reading a batched block after a failure is higher-friction than receiving the next single command fresh.

**How to apply:**
- Prefer: single fenced code block, one shell command (or a short chained `&&` where steps are truly inseparable), then wait.
- Avoid: numbered lists like "1. Run X. 2. Run Y. 3. Verify Z." when each depends on the previous working.
- Exception: read-only verification bundles (e.g. "paste the output of `git status`, `git log`, `git diff`") where the commands are independent and failure of one doesn't invalidate the others.
- Also applies to file edits when doing a branding/refactor pass: edit one file, confirm, then next. Kevin said "one file at a time, confirm completion before moving on."

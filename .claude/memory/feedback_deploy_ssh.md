---
name: Deploy SSH sessions must be separate steps
description: Never combine ssh login with the remote command; SSH always prompts for a password interactively, so one-liners fail.
type: feedback
---

When walking Kevin through a production deploy to `66.179.248.54` (or any SSH target), always give `ssh deploy@...` as its OWN single-command step, and wait for confirmation that he's logged in before handing over the next command. Each subsequent remote command (e.g. `sudo cp ...`, `sudo chown ...`, `sudo systemctl ...`) is also its own separate step.

**Why:** The SSH connection requires an interactive password entry. A combined `ssh user@host "sudo cmd"` one-liner will hang or fail because the password prompt and the remote command can't both be handled in that form. Kevin has called this out multiple times.

**How to apply:** For any deploy / remote-admin walkthrough, emit commands in this cadence:
1. `ssh deploy@66.179.248.54` — wait for "done" / "logged in"
2. First remote command (e.g. `sudo cp /home/deploy/jyrnyl/jotpage.war /var/lib/tomcat10/webapps/ROOT.war`) — wait
3. Next remote command (e.g. `sudo chown tomcat:tomcat /var/lib/tomcat10/webapps/ROOT.war`) — wait
4. And so on.

Also pairs with the existing `feedback_pacing.md` rule — single-command steps, never batched multi-step blocks.

Same rule extends to `scp` uploads — give those as their own step too, since they also prompt for a password.

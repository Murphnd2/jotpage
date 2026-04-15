---
name: Production secrets exposed in chat — rotate before public launch
description: Three production credentials were pasted into a Claude Code chat on 2026-04-15 and need to be rotated
type: project
originSessionId: 148205c1-2b79-4d0c-932b-ebc64dbc6bac
---
Three production credentials were pasted into a Claude Code transcript on 2026-04-15 during initial server setup and are considered exposed. They must be rotated before Jyrnyl receives any real user traffic.

1. **Google OAuth client secret** — rotate at https://console.cloud.google.com/apis/credentials (pick the Jyrnyl OAuth client → Reset Secret). Update `google.clientSecret=` in `/etc/tomcat10/jotpage.properties`, then `sudo systemctl restart tomcat10`.

2. **Anthropic API key** (sk-ant-api03-...) — rotate at https://console.anthropic.com/ (API keys → create new, revoke old). Update `anthropic.apiKey=` in the same properties file.

3. **MySQL `jotpage@localhost` password** — currently weak (`Passw0rd!`) AND was pasted in chat. `sudo mysql` → `ALTER USER 'jotpage'@'localhost' IDENTIFIED BY '<new strong password>'; FLUSH PRIVILEGES;` then update `db.password=` in the properties file.

**Why:** Chat transcripts may be logged by the Claude Code harness or the user's terminal. MySQL user is scoped to `jotpage@localhost` so blast radius is limited to the box itself, but Anthropic key and Google secret are usable from anywhere.

**How to apply:**
- Do all three in one `nano /etc/tomcat10/jotpage.properties` pass, then one `sudo systemctl restart tomcat10` — minimizes downtime.
- Before recommending this to the user, check whether they've already done it — they may have rotated since 2026-04-15 without telling you. Grep the properties file for the exposed Anthropic prefix to confirm.
- If Kevin asks about secret rotation, confirm all three are done, not just one.

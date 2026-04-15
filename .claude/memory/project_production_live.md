---
name: Jyrnyl production deployment state
description: Current state of jyrnyl.com production — what's live, where it lives, and how to redeploy
type: project
originSessionId: 148205c1-2b79-4d0c-932b-ebc64dbc6bac
---
Jyrnyl went live on production as of 2026-04-15 at https://jyrnyl.com/.

**Infrastructure facts (verify before relying on):**
- Origin: IONOS DCD VPS at 66.179.248.54, Ubuntu 24.04 LTS
- Cloudflare proxied, SSL Full (Strict), 15-year Origin Certificate installed
- nginx 1.24 terminates TLS, proxies to Tomcat 10 on 127.0.0.1:8080
- WAR deployed as `/var/lib/tomcat10/webapps/ROOT.war` — context path `/`, NOT `/jotpage/`
- Old `/jotpage/*` paths return 404 (hard cut, no redirect)
- MySQL 8: `jotpage@localhost`, auth_socket for root
- Whisper venv: `/opt/whisper/venv`, symlinked at `/usr/local/bin/whisper`

**Why this state exists:**
Dedicated box so Jyrnyl isn't mixed in with other apps on superiorstate.biz. Root-context deploy was a deliberate choice made mid-setup — Kevin's direct quote: "i don't want the page to start at https://jyrnyl.com/jotpage i want it to be root". Hard cut (no redirect from `/jotpage/*`) chosen over grace period.

**How to apply:**
- When deploying, the WAR is built as `jotpage.war` locally but renamed to `ROOT.war` on the server. pom.xml `<finalName>` was NOT changed; rename happens at deploy time.
- All redirect URIs use `https://jyrnyl.com/oauth2callback` (no `/jotpage/` segment). The old one still exists in Google Cloud Console as a rollback.
- Full deploy procedure is documented in `JOTPAGE_FULL_PROJECT_DOC.md` under "Deploy Process" — use that as source of truth, not this memory.
- SSH requires key auth; `deploy` user is in `sudo` group and is the scp target.

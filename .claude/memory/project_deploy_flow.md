---
name: Jyrnyl deploy flow
description: Step-by-step deploy from Windows dev workstation to jyrnyl.com production, including SW cache quirks
type: project
---

**Full deploy, one command at a time** (matches Kevin's feedback_pacing):

1. **Build** (IntelliJ or PowerShell on the dev workstation):
   `mvn clean package`
   → produces `target/jotpage.war`

2. **Upload** (PowerShell on the dev workstation, NOT from an SSH session):
   `scp C:\Users\kevinmurphy\IdeaProjects\jotpage\target\jotpage.war deploy@66.179.248.54:/home/deploy/jyrnyl/`

3. **SSH in interactively** (not `ssh … 'cmd'` — sudo needs a TTY):
   `ssh deploy@66.179.248.54`

4. **Install to Tomcat** (on the server):
   `sudo cp /home/deploy/jyrnyl/jotpage.war /var/lib/tomcat10/webapps/ROOT.war && sudo chown tomcat:tomcat /var/lib/tomcat10/webapps/ROOT.war`
   → Tomcat auto-redeploys in ~1s.

5. **Hard-refresh the browser** on https://jyrnyl.com/ with Ctrl+Shift+R.

**Service worker cache gotcha:** `sw.js` uses stale-while-revalidate for static assets, so the old JS is served first and updated in the background. Two mitigations already baked in:
- `sw.js` has a `CACHE_VERSION` constant — bump it on every release that changes JS behaviour (current: `v4`).
- JS script tags in `editor.jsp` and `dashboard.jsp` include a `?v=N` query string — keep this in sync with `CACHE_VERSION`. Different URL → SW has no cached entry → guaranteed fresh fetch.

If users still see stale JS after a release: tell them **F12 → Application → Service Workers → Unregister**, then Ctrl+Shift+R. That's the nuclear option.

**Verifying what Tomcat is actually serving** (useful when diagnosing "it should be fixed but isn't"):
- WAR inside `/var/lib/tomcat10/webapps/ROOT.war` is what Tomcat extracts from.
- Exploded directory is `/var/lib/tomcat10/webapps/ROOT/` — Tomcat re-creates this on redeploy. Needs `sudo` to read.
- Quick sanity check from dev workstation: `ssh deploy@66.179.248.54 'sudo head -45 /var/lib/tomcat10/webapps/ROOT/js/<file>.js'` (ssh passes TTY when run without inline command).
- If exploded dir is stale after a WAR swap (rare): `sudo rm -rf /var/lib/tomcat10/webapps/ROOT && sudo systemctl restart tomcat10` forces a clean re-extract.

**Watching deploy logs:**
`sudo journalctl -u tomcat10 -f --since "30 seconds ago"`
→ Look for `Deployment of web application archive [/var/lib/tomcat10/webapps/ROOT.war] has finished in [NNN] ms`. The MySQL "abandoned connection cleanup" stacktrace that fires a few seconds later is from the OLD WAR shutting down, not an error in the new deploy.

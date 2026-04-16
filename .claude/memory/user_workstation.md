---
name: Kevin's role and workstations
description: Kevin Murphy is the solo developer of Jyrnyl; works across two Windows/IntelliJ workstations (home + business)
type: user
originSessionId: 148205c1-2b79-4d0c-932b-ebc64dbc6bac
---
**Who:** Kevin Murphy — solo developer of Jyrnyl (formerly JotPage). Builds end-to-end: backend (Java/servlets/JDBC), frontend (JSP + vanilla JS), infra (VPS, nginx, Tomcat, MySQL). Also does ops/deploy. Comfortable with bash and Linux system admin but may need reminders on exact syntax.

**Two workstations, switches back and forth:**

- **Home workstation** — Windows 11 Pro, working dir `C:\Users\kevinmurphy\IdeaProjects\jotpage`
- **Business workstation** — Windows 10 Pro, working dir `C:\Users\kevinmurphy.SUPERIORSTATE\IdeaProjects\jotpage`

Before assuming paths or OS specifics, check the current environment's `Primary working directory` / `OS Version` — whichever machine is active right now is the one to target.

**Shared across both:**
- Shell: Git Bash or PowerShell (both available — Kevin uses whichever is convenient)
- IDE: IntelliJ IDEA (implied by `.idea/` in `.gitignore`)
- Local dev DB: MySQL, user `root`, password `Passw0rd!` (per repo docs)
- Local jotpage.properties: `C:\ssa\jotpage.properties` — referenced via IntelliJ VM option `-Djotpage.config=C:\ssa\jotpage.properties`
- SSH key: `~/.ssh/id_ed25519` on each workstation (each machine has its own key; both public parts need to be in `/home/deploy/.ssh/authorized_keys` on 66.179.248.54)

**Home workstation SSH key** (as of 2026-04-16): pubkey comment is `kevinmurphy-homedev`, registered on the production box. If the home workstation loses its key or a new one is generated, the pubkey must be re-added to authorized_keys.

**Project memory lives in the repo** (`.claude/memory/`, tracked in git) specifically so it travels between the two workstations — do NOT write to the machine-local `~/.claude/projects/.../memory/` path.

**Setting up a fresh workstation's SSH access to prod** (the flow we used 2026-04-16):
1. On the new workstation: `Get-Content $HOME\.ssh\id_ed25519.pub` (generate with `ssh-keygen -t ed25519` first if it doesn't exist)
2. Copy the full pubkey line (format: `ssh-ed25519 AAA... comment`)
3. Get to a machine that already has SSH access — RDP into one, or use the IONOS DCD web console at https://dcd.ionos.com for KVM access
4. From that trusted machine, SSH to `deploy@66.179.248.54` and run:
   `echo "<pasted-pubkey-line>" >> ~/.ssh/authorized_keys`
5. From the new workstation test: `ssh deploy@66.179.248.54 'hostname'`
6. Note: password SSH auth is disabled on prod — the only way to bootstrap a brand-new workstation with no other access is via the IONOS KVM console.

**Setting up a fresh workstation from scratch:**
1. Clone https://github.com/Murphnd2/jotpage
2. Create `C:\ssa\jotpage.properties` from `src/main/resources/jotpage.properties.example` with local DB + Google OAuth credentials
3. Generate an ed25519 SSH key and register it with prod (see flow above)
4. Install Maven, JDK 17, MySQL 8, FFmpeg, Whisper (`pip install openai-whisper`) locally for dev parity

**How to apply:**
- Explain steps in terms Kevin already knows (JVM, servlets, bash, systemctl) rather than first-principles.
- Default to concrete commands and absolute paths, not abstract descriptions — Kevin prefers "run this" over "you could do X or Y".
- When giving paths, use the current workstation's path. Don't assume the other machine's layout applies.

---
name: Kevin's role and workstation context
description: Kevin Murphy is the solo developer of Jyrnyl; works on Windows with IntelliJ; may switch workstations
type: user
originSessionId: 148205c1-2b79-4d0c-932b-ebc64dbc6bac
---
**Who:** Kevin Murphy — solo developer of Jyrnyl (formerly JotPage). Builds end-to-end: backend (Java/servlets/JDBC), frontend (JSP + vanilla JS), infra (VPS, nginx, Tomcat, MySQL). Also does ops/deploy. Comfortable with bash and Linux system admin but may need reminders on exact syntax.

**Workstation layout:**
- OS: Windows 10 Pro, shell is Git Bash (use Unix syntax, not CMD)
- Working dir: `C:\Users\kevinmurphy.SUPERIORSTATE\IdeaProjects\jotpage`
- IDE: IntelliJ IDEA (implied by `.idea/` in `.gitignore`)
- Local dev DB: MySQL, user `root`, password `Passw0rd!` (per repo docs)
- Local jotpage.properties: `C:\ssa\jotpage.properties` — referenced via IntelliJ VM option `-Djotpage.config=C:\ssa\jotpage.properties`
- SSH key: `~/.ssh/id_ed25519` (ed25519, public part ends with `kevinmurphy@10.0.0.11`)

**Workstation switch in progress:**
On 2026-04-15 Kevin said he'll be switching workstations and needs to continue from there. When setting up a new workstation:
1. Clone https://github.com/Murphnd2/jotpage
2. Create `C:\ssa\jotpage.properties` from `src/main/resources/jotpage.properties.example` with local DB + Google OAuth credentials
3. Generate a new ed25519 SSH key, add the public key to `/home/deploy/.ssh/authorized_keys` on 66.179.248.54 (needs existing-workstation access to push it, or root-password fallback)
4. Install Maven, JDK 17, MySQL 8, FFmpeg, Whisper (`pip install openai-whisper`) locally for dev parity

**How to apply:**
- Explain steps in terms Kevin already knows (JVM, servlets, bash, systemctl) rather than first-principles.
- Default to concrete commands and absolute paths, not abstract descriptions — Kevin prefers "run this" over "you could do X or Y".

# JYRNYL-CLAUDE-ASSETS.md — Inventory of `.claude/` Contents
**Date:** 2026-04-25  
**Branch inventoried:** main (HEAD 4728642)

---

## Overview

`.claude/` contains one config file and one subdirectory of memory files. There are no skills, hooks, commands, or prompt files. The directory is tracked in git (`.claude/` is NOT in `.gitignore`) so all files travel between workstations with `git pull`.

---

## `.claude/settings.local.json`

| Property | Value |
|---|---|
| **Full path** | `.claude/settings.local.json` |
| **Type** | Config (Claude Code project-level permission allowlist) |
| **Last modified** | 2026-04-16 |
| **Touch count** | 4 commits |

**Summary:** Contains a `permissions.allow` array of pre-approved `Bash(...)` patterns so Claude Code does not prompt for confirmation before running those commands. Approved commands cover: `git add`, `git commit`, `git push`, `git checkout`; `mvn compile`, `mvn -q clean package -DskipTests`; specific one-off verification commands (`javac --version`, `where mvn`, `ls /c/apache-maven*`, `find /c -maxdepth 3 -name "mvn.cmd"`); `ssh deploy@66.179.248.54 '...'` with several hard-coded remote commands for verifying deployed files; `unzip -p` against the WAR; `xargs grep`. There is no `deny` section.

**Jyrnyl-specific?** Yes — the SSH host (`66.179.248.54`), the WAR path (`target/jotpage.war`), and the specific remote paths (`/home/deploy/jyrnyl/`, `/var/lib/tomcat10/webapps/ROOT/`) are all specific to this project's production server.

---

## `.claude/memory/MEMORY.md`

| Property | Value |
|---|---|
| **Full path** | `.claude/memory/MEMORY.md` |
| **Type** | Index (pointer file, not a memory itself) |
| **Last modified** | 2026-04-16 |
| **Touch count** | 3 commits |

**Summary:** A flat list of all memory files with one-line descriptions. Serves as the index Claude Code reads to locate memories. Currently lists 8 entries. No memory content is stored here directly.

**Jyrnyl-specific?** Yes — all pointers are to Jyrnyl-specific memory files.

---

## `.claude/memory/feedback_pacing.md`

| Property | Value |
|---|---|
| **Full path** | `.claude/memory/feedback_pacing.md` |
| **Type** | Feedback memory |
| **Last modified** | 2026-04-15 |
| **Touch count** | 1 commit |

**Summary:** Records that the user (Kevin) strongly prefers single-command walkthrough steps — never batched numbered lists — because earlier steps often fail and invalidate later ones. Also applies to multi-file editing passes: one file at a time, confirm before moving on. The one exception noted is read-only verification bundles where commands are independent.

**Jyrnyl-specific?** No — this is a collaboration-style preference that would apply to any project.

---

## `.claude/memory/feedback_deploy_ssh.md`

| Property | Value |
|---|---|
| **Full path** | `.claude/memory/feedback_deploy_ssh.md` |
| **Type** | Feedback memory |
| **Last modified** | 2026-04-16 |
| **Touch count** | 1 commit |

**Summary:** Records that SSH login must always be its own step, with confirmation awaited before handing over the next command. Combined `ssh user@host "cmd"` one-liners fail because of interactive password prompting. Every subsequent remote command (sudo cp, chown, systemctl) is also its own step. Host `66.179.248.54` is named explicitly.

**Jyrnyl-specific?** Mixed — the rule itself is generic SSH discipline; the specific host, user (`deploy`), and paths are Jyrnyl-specific.

---

## `.claude/memory/project_production_live.md`

| Property | Value |
|---|---|
| **Full path** | `.claude/memory/project_production_live.md` |
| **Type** | Project memory |
| **Last modified** | 2026-04-15 |
| **Touch count** | 1 commit |

**Summary:** Records the production deployment state as of 2026-04-15: live at `https://jyrnyl.com/`; IONOS VPS at `66.179.248.54`; Cloudflare-proxied with SSL Full (Strict); nginx → Tomcat 10; WAR deployed as `ROOT.war` (root context); MySQL 8 at localhost; Whisper venv at `/opt/whisper/venv`. Notes that old `/jotpage/*` paths return 404 with no redirect. Notes that `pom.xml` `<finalName>` was not changed — rename to `ROOT.war` happens at deploy time.

**Jyrnyl-specific?** Yes — entirely.

---

## `.claude/memory/project_deploy_flow.md`

| Property | Value |
|---|---|
| **Full path** | `.claude/memory/project_deploy_flow.md` |
| **Type** | Project memory |
| **Last modified** | 2026-04-16 |
| **Touch count** | 1 commit |

**Summary:** Step-by-step deploy procedure: (1) `mvn clean package`, (2) `scp` WAR to `/home/deploy/jyrnyl/`, (3) SSH in interactively, (4) `sudo cp` + `chown` to install WAR, (5) hard-refresh browser. Documents service-worker cache gotcha: `CACHE_VERSION` in `sw.js` and `?v=N` query strings on JS script tags must be kept in sync. States "current: v4" for CACHE_VERSION (now stale — `sw.js` shows `v9`). Also documents log-watching command and how to diagnose stale exploded WAR.

**Jyrnyl-specific?** Yes — paths, host, and SW cache approach are Jyrnyl-specific.

---

## `.claude/memory/project_secrets_rotation.md`

| Property | Value |
|---|---|
| **Full path** | `.claude/memory/project_secrets_rotation.md` |
| **Type** | Project memory |
| **Last modified** | 2026-04-15 |
| **Touch count** | 1 commit |

**Summary:** Records that three production credentials were pasted into a Claude Code chat on 2026-04-15 and must be rotated before public launch: (1) Google OAuth client secret, (2) Anthropic API key (`sk-ant-api03-…`), (3) MySQL `jotpage@localhost` password (noted as `Passw0rd!`). Provides rotation steps and locations for each. Recommends doing all three in one properties-file edit pass.

**Jyrnyl-specific?** Yes — entirely.

---

## `.claude/memory/project_voice_booth_rethink.md`

| Property | Value |
|---|---|
| **Full path** | `.claude/memory/project_voice_booth_rethink.md` |
| **Type** | Project memory |
| **Last modified** | 2026-04-16 |
| **Touch count** | 1 commit |

**Summary:** Records that the Voice Booth page (`/app/voice-record`) was considered visually too complex after a compactness pass on 2026-04-16 and a UX rethink was tabled. Records 4 bugs closed in the same session (first-word dedup in `voice-recorder.js`; Android keyboard focus in `ink-engine.js`; accidental logout from bubble menu in `bubble-menu.js`; bubble menu overflow fix). Also records two open items: the tabled UX rethink, and that `VoiceModeValidator` thresholds are hand-tuned against a small sample.

**Jyrnyl-specific?** Yes — references specific files and routes in this repo.

---

## `.claude/memory/reference_external_systems.md`

| Property | Value |
|---|---|
| **Full path** | `.claude/memory/reference_external_systems.md` |
| **Type** | Reference memory |
| **Last modified** | 2026-04-15 |
| **Touch count** | 1 commit |

**Summary:** Pointers to external systems: GitHub repo URL (`https://github.com/Murphnd2/jotpage`), Google Cloud Console OAuth credentials URL, Anthropic Console for API keys, Cloudflare dashboard for jyrnyl.com DNS/SSL, IONOS DCD console for VPS access. Notes that the local dev redirect URI still uses the `/jotpage/` context path. Notes the previous production host (`superiorstate.biz`) is no longer in use.

**Jyrnyl-specific?** Yes — all pointers are to Jyrnyl-specific external systems.

---

## `.claude/memory/user_workstation.md`

| Property | Value |
|---|---|
| **Full path** | `.claude/memory/user_workstation.md` |
| **Type** | User memory |
| **Last modified** | 2026-04-16 |
| **Touch count** | 2 commits |

**Summary:** Describes Kevin Murphy as the solo developer of Jyrnyl, working across two Windows workstations (home: Win 11, `C:\Users\kevinmurphy\IdeaProjects\jotpage`; business: Win 10, `C:\Users\kevinmurphy.SUPERIORSTATE\IdeaProjects\jotpage`). Records local dev toolchain: IntelliJ IDEA, MySQL, Maven, FFmpeg, Whisper. Records that the local `jotpage.properties` path is `C:\ssa\jotpage.properties`. Records home workstation SSH pubkey comment (`kevinmurphy-homedev`). Documents the flow to register a new workstation's SSH key on prod. Notes project memory lives in-repo to travel between workstations.

**Jyrnyl-specific?** Mixed — the workstation/path specifics are Jyrnyl-specific; the general guidance about explaining in terms Kevin knows (JVM, servlets, bash) is collaboration-style preference that might apply broadly.

# Memory index

- [One step at a time](feedback_pacing.md) — Kevin strongly prefers single-command instructions, not batched multi-step blocks.
- [Jyrnyl production deployment state](project_production_live.md) — Live at jyrnyl.com since 2026-04-15, deployed as ROOT on IONOS VPS behind Cloudflare + nginx.
- [Jyrnyl deploy flow](project_deploy_flow.md) — Step-by-step build → scp → install → SW cache gotchas → log watching.
- [Secrets to rotate before public launch](project_secrets_rotation.md) — Google client secret, Anthropic API key, MySQL password pasted in chat 2026-04-15.
- [Kevin's role and workstations](user_workstation.md) — Solo developer; switches between home (Win 11) and business (Win 10) workstations. Home workstation pubkey comment `kevinmurphy-homedev` registered on prod 2026-04-16.
- [External systems for Jyrnyl](reference_external_systems.md) — GitHub, Google Cloud Console, Anthropic Console, Cloudflare, IONOS.
- [Voice Booth UX rethink tabled; still-open bugs](project_voice_booth_rethink.md) — UX tabled; first-word dedup bug + reapply tablet phases against new editor + investigate unexpected logout.
- [SSH login separate from remote commands](feedback_deploy_ssh.md) — Always emit `ssh user@host` as its own step and wait; never combine it with the remote command.

---
name: External systems for Jyrnyl
description: Where to look for auth credentials, DNS, hosting, and code outside this repo
type: reference
originSessionId: 148205c1-2b79-4d0c-932b-ebc64dbc6bac
---
- **GitHub repo:** https://github.com/Murphnd2/jotpage (branch `main`, still named `jotpage` — repo NOT renamed during Jyrnyl rebrand)
- **Google Cloud Console (OAuth):** https://console.cloud.google.com/apis/credentials — the Jyrnyl OAuth 2.0 Client ID owns `google.clientId` / `google.clientSecret` and the authorized redirect URIs. Current URIs: `https://jyrnyl.com/oauth2callback` (prod), `http://localhost:8080/jotpage/oauth2callback` (local dev — note `/jotpage/` still on dev since local WAR deploys at that context)
- **Anthropic Console (Claude API):** https://console.anthropic.com/ → API keys. Current model in use: `claude-sonnet-4-20250514` (see `ClaudeService.java`).
- **Cloudflare dashboard:** https://dash.cloudflare.com — jyrnyl.com zone. DNS records point A @ and A www to 66.179.248.54. SSL/TLS mode: Full (Strict). Origin cert generated via SSL/TLS → Origin Server (15-year cert).
- **IONOS DCD (hosting):** the VPS (66.179.248.54, Ubuntu 24.04) is provisioned through IONOS. Check IONOS billing/console for server-level access if SSH is ever broken.
- **Previous production host:** superiorstate.biz — old JotPage home, still has the superceded OAuth redirect URI. No longer in use for Jyrnyl.

**How to apply:**
- When a user mentions the OAuth client, Anthropic key, or DNS, default to these systems rather than guessing.
- If the user asks "where do I find X credential," point them to these URLs.

# Properties Update — Per-Mode Claude Model Selection

Add the following lines to `jotpage.properties` on both local dev
(`C:\ssa\jotpage.properties`) and production (`/etc/tomcat10/jotpage.properties`).

No Tomcat restart is required beyond the normal WAR deploy — these properties
are read at call time via `AppConfig.get()`, not cached at startup.

```properties
# Per-mode Claude model override (optional — defaults to claude-sonnet-4-20250514)
claude.model.study_notes=claude-haiku-4-5-20251001
claude.model.outline=claude-haiku-4-5-20251001
# claude.model.meeting_minutes=claude-sonnet-4-20250514
# claude.model.journal_entry=claude-sonnet-4-20250514
# claude.model.custom=claude-sonnet-4-20250514
```

## What each line does

| Property | Effect |
|---|---|
| `claude.model.study_notes` | Routes Study Notes jobs to Haiku (~75% cost reduction) |
| `claude.model.outline` | Routes Outline jobs to Haiku (~75% cost reduction) |
| Commented-out lines | Document the available keys; Sonnet is the default so no entry needed |

## Reverting a mode back to Sonnet

Either comment out the line or set it explicitly:

```properties
claude.model.study_notes=claude-sonnet-4-20250514
```

## Adding a global default override

To switch all modes to a different model without listing each one:

```properties
claude.model.default=claude-sonnet-4-20250514
```

`modelFor()` checks `claude.model.<jobType>` first, then `claude.model.default`,
then falls back to the hard-coded `DEFAULT_MODEL` constant in `ClaudeService.java`.

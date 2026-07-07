---
summary: "Fable provider notes: Organized AI fleet leaderboard + live Claude limits from the fable-cal API."
read_when:
  - Adding or modifying the Fable provider
  - Debugging fable-cal API fetches or endpoint overrides
  - Adjusting Fable menu labels or leaderboard mapping
---

# Fable Provider

The Fable provider surfaces the **Organized AI Fable stack** in the menu bar: live Claude
rate-limit meters plus a fleet model leaderboard aggregated from real transcripts across the
fleet (Claude Code JSONL, Codex sessions, and local LLM runtimes).

Companion dashboard: <https://visual.organizedai.vip/fable>

## Features

- **5h block meter**: `five_hour` utilization from `GET /api/limits`, mapped to the session window
  (300-minute window, reset countdown included).
- **Weekly meter**: `seven_day` utilization mapped to the weekly window with its reset timestamp.
- **Fleet leaderboard**: top models by 7-day token volume from `GET /api/usage/leaderboard`,
  rendered on the provider card as the account line, e.g. `👑 gpt-5.5 5.7M · opus-4-8 1.1M`.
- **Dashboard link**: the provider's dashboard URL opens the full Fable ladder (build map,
  model picker, tokenomics inventory, leaderboard).

## Data source

Both endpoints are served by the `fable-cal` Cloudflare Worker
(`https://fable-cal.jordan-691.workers.dev` by default):

| Endpoint | Payload |
|---|---|
| `/api/limits` | `{updated_at, source, limits:{five_hour, seven_day, five_hour_resets_at, seven_day_resets_at}}` |
| `/api/usage/leaderboard` | `{rows:[{model, runtime, machines, in_tokens, out_tokens, tokens, sessions, updated_at}]}` |

Data is pushed to the worker by collectors running on fleet machines (30-minute launchd cadence):
CodexBar CLI or the Claude OAuth usage API for limits, and transcript parsers for the leaderboard.

## Auth

None. The API is public read-only; the provider is available as soon as its toggle is enabled
(Settings → Providers → **Show Fable fleet usage**). No cookies, tokens, or Keychain access.

## Endpoint override

Set `FABLE_API_BASE` in the environment to point at a different deployment:

```bash
FABLE_API_BASE="https://my-fable-cal.example.workers.dev" open -a CodexBar
```

Trailing slashes are trimmed. When unset, the default worker URL is used.

## Mapping notes

- `five_hour` → `UsageSnapshot.primary` (session), `seven_day` → `secondary` (weekly);
  both clamped to 0–100.
- The leaderboard summary lives in `ProviderIdentitySnapshot.loginMethod` so it renders in the
  card's account line without new UI. Model names are shortened (`claude-` prefix and date
  suffixes stripped); token counts use compact `k`/`M` formatting.
- Missing or partial payloads degrade gracefully: absent limits produce no windows, an
  unreachable leaderboard just omits the summary line (`FableUsageFetcherTests` covers both).

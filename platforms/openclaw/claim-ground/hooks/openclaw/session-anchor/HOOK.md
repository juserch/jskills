---
name: claim-ground-session-anchor
description: "Restore verified-fact anchors / unverified seen_paths / hard constraints at agent bootstrap"
homepage: https://github.com/juserai/forge
metadata:
  {
    "openclaw":
      {
        "emoji": "🎯",
        "events": ["agent:bootstrap"],
        "install": [{ "id": "forge", "kind": "plugin", "label": "forge plugin" }]
      }
  }
---

# Claim Ground — Session Anchor Hook

OpenClaw mirror of [skills/claim-ground/hooks/session-anchor.sh](../../../../../skills/claim-ground/hooks/session-anchor.sh) (Claude Code bash).

## What It Does

Fires on `agent:bootstrap` event before workspace files are injected. Reads `~/.forge/claim-ground-anchors.json` and emits up to three context blocks:

1. **`<CLAIM_GROUND_ANCHORS>`** — verified-fact anchors from prior sessions (model ID, CLI version, etc.); marks anchors with `verified_at > 24h` ago as `needs_reconfirm:true`
2. **`<CLAIM_GROUND_SEEN_PATHS>`** — paths seen in past tool outputs but **never independently verified** (R8 anchor pollution prevention)
3. **`<CLAIM_GROUND_HARD_CONSTRAINTS>`** — user-expressed hard constraints still in effect (R14)

## Configuration

```bash
openclaw hooks enable claim-ground-session-anchor
```

## Shared State

Reads from `~/.forge/claim-ground-anchors.json` (cross-platform shared with Claude Code session-anchor.sh).

## Event Mapping

| Claude Code | OpenClaw |
|---|---|
| `SessionStart` (startup/resume/clear) | `agent:bootstrap` |

## Defensive Behaviors

- File missing → silent skip
- JSON corruption → silent skip
- `last_updated > 7 days` → silent skip (stale)
- Empty data → no blocks emitted

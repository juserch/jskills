---
name: claim-ground-prompt-gate
description: "Detect ambiguity / hard constraints / scope-collapse in user messages and inject reminder context"
homepage: https://github.com/juserai/forge
metadata:
  {
    "openclaw":
      {
        "emoji": "🎯",
        "events": ["message:received"],
        "install": [{ "id": "forge", "kind": "plugin", "label": "forge plugin" }]
      }
  }
---

# Claim Ground — Prompt Gate Hook

OpenClaw mirror of [skills/claim-ground/hooks/prompt-gate.sh](../../../../../skills/claim-ground/hooks/prompt-gate.sh) (Claude Code bash).

## What It Does

Fires on `message:received` event. Reads user's incoming message content; runs 3 categories of regex matchers (loaded from `references/matchers.json`) and injects bilingual reminder blocks (loaded from `references/reminders.json`):

- **Ambiguity** (R8/R9): path/env reference, vague pronoun, fuzzy quantifier, vague preference, missing-param strong action, missing framework
- **Hard constraint capture** (R14): "don't / never / must not / 不要 / 别 / 禁止" → write to `~/.forge/claim-ground-anchors.json` `hard_constraints[]`
- **Scope collapse** (R15): "latest / strongest / official / 最新 / 最强 / 官方" → require WebSearch instead of system-prompt-only

## Self-invocation guard + mutual yield

Skips silently if:
- Message starts with `/claim-ground` (manual invocation)
- Message matches epistemic-pushback regex (let pushback hook handle)
- Message matches frustration regex (let block-break frustration handle)

## Configuration

```bash
openclaw hooks enable claim-ground-prompt-gate
```

## Shared State

Writes to `~/.forge/claim-ground-anchors.json` `hard_constraints[]` (cross-platform shared with Claude Code, single-writer atomic mv).

## Event Mapping

| Claude Code | OpenClaw |
|---|---|
| `UserPromptSubmit` | `message:received` (context.content = user prompt) |

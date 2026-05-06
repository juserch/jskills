---
name: claim-ground-epistemic-pushback
description: "Detect user pushback (multilingual challenge regex) and inject re-verification reminder"
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

# Claim Ground — Epistemic Pushback Hook

OpenClaw mirror of [skills/claim-ground/hooks/epistemic-pushback-trigger.sh](../../../../../skills/claim-ground/hooks/epistemic-pushback-trigger.sh) (Claude Code bash).

## What It Does

Fires on `message:received` event. Tests user's incoming message against multilingual pushback regex (loaded from `references/matchers.json` `yield_to_pushback` field):

- 中文：真的吗 / 不对吧 / 你确定 / 已经更新 / 我以为
- English: really? / are you sure / I thought / wait / hold on
- Plus 9 other languages: ja/ko/es/fr/de/ru/ar/pt-BR/hi

When matched, emits `<CLAIM_GROUND_ACTIVATED>` reminder block requiring **re-verification** instead of rephrasing the prior answer.

## Self-invocation guard

Skips silently if message starts with `/claim-ground` (manual invocation may contain pushback regex as data).

## Configuration

```bash
openclaw hooks enable claim-ground-epistemic-pushback
```

## Event Mapping

| Claude Code | OpenClaw |
|---|---|
| `UserPromptSubmit` (pushback matcher) | `message:received` (regex on context.content) |

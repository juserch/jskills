# Add skill-lint S34 — help-card-flag-coverage

> 这次 change 解决的张力：argument-hint 与 help card 内容**没有锁步**——help-mode spec 只规定 help card 必须存在，没规定它要列全 argument-hint 的 flag。审计 9 个 skill 发现 3 个 crucible/quench skill 的 family 契约 flag (`--no-save`) 没在 help card 出现，1 个 hammer skill 的核心调用入口 (`L0-L4` / `<task>`) help card 漏列。**用户跑 `/<skill> help` 看不到关键 flag**，必须读 frontmatter 才能发现。

## Why

实勘证据：

1. **`--no-save` 在 3 个 skill 漏列**：
   - [skills/council-fuse/SKILL.md:12](../../../skills/council-fuse/SKILL.md#L12) `argument-hint: "[question or task] [--no-save]"`，但 [Help 段 line 19-32](../../../skills/council-fuse/SKILL.md#L19-L32) 完全没出现 `--no-save`
   - [skills/news-fetch/SKILL.md:12](../../../skills/news-fetch/SKILL.md#L12) `argument-hint: "[topic] [time-range] [--no-save]"`，但 Help 段同样没列
   - [skills/insight-fuse/SKILL.md:13](../../../skills/insight-fuse/SKILL.md#L13) argument-hint 含 11 个 flag，但 Help 段 "Key flags" 只列 4 个（type / depth / sections / merge），漏 7 个含 `--no-save`

2. **block-break 入口分裂**：
   - [README.md](../../../README.md) 文档了 3 种调用 `/block-break` / `/block-break L2` / `/block-break <task>`
   - [skills/block-break/SKILL.md Help 段](../../../skills/block-break/SKILL.md) 只列 `(no args)` + `help`，**漏列另外 2 种入口**

3. **`--no-save` 是 forge crucible/quench 族的家族契约**：[platform-parity/spec.md](../../specs/platform-parity/spec.md) (c) 项 family resemblance 强调跨族一致，help card 漏列等于让用户认知错位。

三类共享同一根因：**没有结构化检查能在 PR 阶段挡住 help-card 与 argument-hint 漂移**。本 change 加入 lint S34 把"未来再漏"从纪律问题升级为 lint 强制。

## What Changes

**新增 lint 规则**：

- **S34 help-card-flag-coverage**：解析 SKILL.md frontmatter `argument-hint` 中所有以 `--` 开头的 flag，与 `## Help` 段第一个 code block 内出现的 `--flag` 集合对比；缺失即报。
  - **canonical + platform mirror 同等约束**（platform mirror 含 Help 段时一并扫）
  - **子命令模式豁免**：argument-hint 仅含 `[setup|run|...]` 子命令枚举（无 `--flag`）时跳过
  - **初期 severity = warn**（观察期 ≥ 7 天 + 现有 4 个已知问题修完后，PR 升级到 error）

**`.skill-lint.json` 新增字段**：

```json
"verify-help-card-flag-coverage": "warn"
```

三态配置：`off` / `warn` / `error`，与现有 [verify-docs-version-drift](../../../.skill-lint.json) (`warn`) / [require-help-section](../../../.skill-lint.json) (`warn`) / [verify-archived-spec-merge](../../../.skill-lint.json) (`warn`) 同一三态分级。

**skill-lint 自身 minor bump**：v1.0.0 → v1.1.0（新增非破坏性 lint 规则；同时 CHANGELOG 补 S29-S33 的 backfill 记录——这些规则 commit `cf79b1d` / `f0a91e9` 静默合入，CHANGELOG 一直未追平 v1.0.0）。

## Non-goals

- **本 change 不修复任何 skill 的 help card 不一致**：S34 上线后 lint 输出会暴露 4 个已知问题（council-fuse / news-fetch / insight-fuse 各漏 `--no-save`、block-break 漏 `L0-L4` 入口）；这些**留给 follow-up RFC `fix-help-card-flag-coverage`** 批量修复，本 change 只引入工具不动业务。
- **不引入 argument-hint 必填检查**：block-break / claim-ground / skill-lint 三个 skill 没有 frontmatter argument-hint 字段——argument-hint 是 Claude Code 可选字段，本 change 不强制必填，缺字段时 S34 直接跳过该 skill。
- **不改 help-mode spec**：help card 的具体内容契约（必须列哪些 flag）由 lint 规则定义，不上升到 spec（spec 只定 L1/L2 触发与无副作用契约）。
- **不延伸到 description / Examples 段一致性**：Examples 内是否使用了 hint 中的全部 flag 不是本 change 的检查范围；只查 Usage / 参数说明类内容（即 help card 第一个 code block）。
- **peer-fuse 不在修复范围**：peer-fuse v0.1.0 的 3 个 flag 在 help card 全列了，已合规，本 change 不动。

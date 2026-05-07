# Version Governance — SSOT in marketplace.json + lockstep across help-card / CHANGELOG

> 这次 change 解决的张力:forge 仓库目前**没有 skill 版本号的 SSOT 锁步机制**——`marketplace.json` 是事实来源,但 SKILL.md 正文 / 描述 / help card / 文档里各自维护版本字面量,没有锁步。运行时已发现两处真实飘移(`insight-fuse` 与 `claim-ground`),且 8 个 skill 中 6 个的 help card 完全不打版本号。
>
> **架构注释(2026-05-07 修订)**:本 change 早期版本曾把 SKILL.md frontmatter `version:` 字段定为 SSOT。实施时发现 Claude Code 官方 skill schema **不支持** `version` 字段(IDE 实测告警:"Attribute 'version' is not supported in skill files"),顶层与嵌套 metadata 子字段都被拒绝。架构 pivot 后,**SSOT 落到 [`.claude-plugin/marketplace.json`](../../../.claude-plugin/marketplace.json) `plugins[].version`**,SKILL.md frontmatter 不持有 version;help-card / CHANGELOG / platform mirror 的版本号字面量都通过 lint S29/S30/S31 比对 marketplace SSOT。本 proposal 反映 pivot 后的最终架构。

## Why

证据驱动的三类问题:

1. **SSOT 锁步缺位** —— 修改 `marketplace.json` plugin version 时,help-card / CHANGELOG / platform mirror 无强制锁步,容易漏改。 [openspec/specs/repo-invariants/spec.md § SKILL.md 精简原则](../../specs/repo-invariants/spec.md) 定义的合法 frontmatter 字段集为 `name / description / license / argument-hint / user-invokable / metadata`,**不含 `version`**——这本身没问题(Claude Code schema 也不支持),但意味着 lint 必须以 marketplace 为 SSOT 比对 help-card / CHANGELOG。

2. **已观测到的飘移**——

   - **insight-fuse**:`marketplace.json` 锁在 `3.3.0`,但 [skills/insight-fuse/SKILL.md:3](../../../skills/insight-fuse/SKILL.md#L3) frontmatter description / [L16](../../../skills/insight-fuse/SKILL.md#L16) H1 标题 / 正文 12+ 处皆已升至 `v3.4`。git log `cf79b1d feat(insight-fuse): v3.4 ...` 已合入 main,**marketplace 漏更**。
   - **claim-ground**:[skills/claim-ground/SKILL.md:3](../../../skills/claim-ground/SKILL.md#L3) description 是 `v1.2`,[L23](../../../skills/claim-ground/SKILL.md#L23) help card body 仍打 `Claim Ground v1.1` —— 同一文件内部飘移。

3. **Help 不打版本** —— `block-break / council-fuse / news-fetch / ralph-boost / skill-lint / tome-forge` 6 个 skill 的 help card 完全不显示版本号,用户运行 `/<skill> help` 无法判断当前装的是哪一版。

三类问题共享同一根因:**版本号没有 lint 强制锁步**。本 change 把 SSOT 锚定到 marketplace.json,并扩展 `skill-lint` 在自检三命令中强制三点一致(marketplace ↔ help-card ↔ CHANGELOG)。

## What Changes

**新增契约**(4 份 spec delta):

- `repo-invariants`:SSOT 定为 `marketplace.json plugins[].version`;SKILL.md frontmatter MUST NOT 含 `version` 字段(Claude Code schema 拒绝);仓库根 MUST 持有 `/CHANGELOG.md` 且各 skill 段 top entry MUST 等于 marketplace SSOT
- `skill-lifecycle` 的场景 B(修改 skill)追加 version bump 触发规则与 SemVer 2.0.0 语义,bump 操作目标改为 marketplace.json + help-card + CHANGELOG 三处同步
- `help-mode` 的 help card 模板 A/B 追加第一行 `<Skill Name> v<X.Y.Z> — <tagline>` 格式约束,版本号字面量 = marketplace SSOT
- `platform-parity`:platform mirror frontmatter 同样不持 version 字段(regression guard);若含 Help 段,help-card 第一行版本号 MUST 等于 marketplace SSOT

**新增 lint 规则**(写入 [.skill-lint.json](../../../.skill-lint.json) 与 [skills/skill-lint/scripts/skill-lint.sh](../../../skills/skill-lint/scripts/skill-lint.sh)):

- **S29 version-lockstep**:marketplace.json `plugins[].version` MUST 是 SemVer 2.0.0;SKILL.md frontmatter MUST NOT 含 `version:` 字段(canonical + platform mirror 都查;regression guard);error 级
- **S30 help-card-version-line**:SKILL.md `## Help` 段(含 `## Help (...)` 变体)内 help card 第一行 MUST 匹配 `<Name> v<X.Y.Z> — <tagline>`;`X.Y.Z` 字面量 MUST 等于 marketplace.json 对应 plugin `version`;canonical + 每个 platform mirror 同等约束(若 mirror 含 Help 段);error 级
- **S31 changelog-entry**:每个 skill 在 `marketplace.json plugins[].version` 的版本号 MUST 等于根 [/CHANGELOG.md](../../../CHANGELOG.md) `## <skill-name>` 段下的 top-most `### [X.Y.Z]` 条目;error 级

**一次性数据修复**:

- `insight-fuse`:marketplace.json 升 `3.3.0 → 3.4.0`(让事实落到 SSOT;行为已在 v3.4 commit 合入)
- `claim-ground` canonical + openclaw mirror:help card body `v1.1 → v1.2.0`
- 7 个 canonical help card 第一行补版本号 + 3 个 openclaw mirror help card(claim-ground / insight-fuse / tome-forge,其余 5 个 mirror 无 Help 段不在本 change 范围,由 [openclaw-drift-fix](../openclaw-drift-fix/proposal.md) 处理)
- 新建根 [/CHANGELOG.md](../../../CHANGELOG.md):Keep-a-changelog 1.1.0 风格,8 个 skill 各一节,seed 当前版本 + 历史可考的关键 bump
- `marketplace.json` 全量重算 SHA-256([scripts/recalc-all-hashes.sh](../../../scripts/recalc-all-hashes.sh))

## Non-goals

- **不为集合级 plugin.json 引入独立 version 治理** —— [plugin.json](../../../plugin.json) / [.claude-plugin/plugin.json](../../../.claude-plugin/plugin.json) 的 1.0.0 双份一致由 [repo-invariants § Plugin metadata 双份一致](../../specs/repo-invariants/spec.md) 已覆盖,本 change 不动其规则;follow-up RFC `collection-version-policy` 单独处理。
- **不引入 per-skill / per-platform CHANGELOG** —— 用户决策选 root 单文件;per-skill changelog 留作后续观察期决定。
- **不引入运行时模板替换** —— help card 用静态字面量 + lint 校对,不用 `{{VERSION}}` 占位符(避免破坏零依赖)。
- **不向后追溯 git tag** —— 本 change 不为 8 个 skill 补 v1.0.0 / v1.1.0 等历史 tag。
- **不为 5 个无 Help 段的 openclaw mirror 强制添加 Help 段** —— S30 仅在 Help 段存在时校验;补齐 Help 段由 [openclaw-drift-fix](../openclaw-drift-fix/proposal.md) 处理。
- **不在 SKILL.md frontmatter 引入 version 字段** —— Claude Code 官方 schema 拒绝;尝试嵌套到 metadata.version 也被拒(实测 verified)。SSOT 仅在 marketplace.json。

# Repo-Invariants Spec Delta — Skill version SSOT 与 CHANGELOG 强制登记

> **架构注释(2026-05-07 修订)**:本 delta 早期版本曾把 `skills/<n>/SKILL.md` frontmatter `version:` 字段定为 SSOT。实施时发现 Claude Code 官方 skill schema **不支持** `version` 字段(IDE 实测告警:"Attribute 'version' is not supported in skill files. Supported: argument-hint, compatibility, description, disable-model-invocation, license, metadata, name, user-invokable.")。架构 pivot 后,**SSOT 移到 [`.claude-plugin/marketplace.json`](../../../../.claude-plugin/marketplace.json) `plugins[].version`**,SKILL.md frontmatter 不持有任何 version 字段(顶层与嵌套 metadata 子字段均被 schema 拒绝)。本 delta 以下 Requirements 反映 pivot 后的最终架构。

## ADDED Requirements

### Requirement: SKILL.md frontmatter MUST NOT 含 `version` 字段(regression guard)

每个 `skills/<n>/SKILL.md` 与每个 `platforms/<p>/<n>/SKILL.md` 的 frontmatter MUST NOT 含名为 `version` 的字段(无论顶层还是嵌套于任何子结构如 `metadata.version`)。

理由:Claude Code 官方 skill schema 仅支持 `argument-hint / compatibility / description / disable-model-invocation / license / metadata / name / user-invokable` 八个顶层字段;`version` 不在其中,触发 IDE / 验证器告警。Skill 版本号的合法承载位置是 `.claude-plugin/marketplace.json` `plugins[].version`(Claude Code marketplace 元数据 schema 显式支持)。

skill-lint 规则 S29 SHALL 在 lint 阶段扫描所有 SKILL.md 文件 frontmatter,任一含 `version:` 字段(顶层或嵌套)即报 error,作为防御性 regression guard——避免未来贡献者无意中重新加入该字段。

#### Scenario: SKILL.md frontmatter 含顶层 `version` 字段

- **WHEN** `skills/<some-skill>/SKILL.md` frontmatter 含 `version: 1.0.0` 顶层字段
- **THEN** S29 报 error: "skills/<some-skill>/SKILL.md frontmatter contains `version:` field (Claude Code schema rejects it; SSOT is marketplace.json)"
- **AND** 修复 SHALL 为删除该字段;skill 版本号通过 `.claude-plugin/marketplace.json` `plugins[].version` 承载

#### Scenario: 平台 mirror frontmatter 含 `version` 字段

- **WHEN** `platforms/openclaw/<some-skill>/SKILL.md` frontmatter 含 `version:` 字段
- **THEN** S29 报 error: "platforms/openclaw/<some-skill>/SKILL.md frontmatter contains `version:` field (forbidden)"
- **AND** 修复 SHALL 为删除该字段(平台 mirror 同样不持有独立 version,共享 canonical 的 marketplace SSOT)

#### Scenario: frontmatter 嵌套于 metadata 的 version 也被拒绝

- **WHEN** `skills/<some-skill>/SKILL.md` frontmatter 含 `metadata:\n  version: 1.0.0`(嵌套形式)
- **THEN** S29 同样报 error(IDE schema 验证器拒绝任何位置的 `version` 字段)
- **AND** 移到 metadata 子结构**不能**绕过 schema 限制(实测 verified)

### Requirement: SSOT = `.claude-plugin/marketplace.json` `plugins[].version`(SemVer 2.0.0)

每个 skill 的版本号 SSOT SHALL 是 [`.claude-plugin/marketplace.json`](../../../../.claude-plugin/marketplace.json) 中对应 plugin entry 的 `version` 字段。该字段 MUST 为 SemVer 2.0.0 格式(三段十进制数字、点分隔,可选 pre-release / build metadata 后缀,示例 `1.2.0` / `3.4.0-beta+exp.sha.5114f85`)。

下列衍生位置 MUST 字面量等于 SSOT:
- canonical `skills/<n>/SKILL.md` 内 `## Help` 段 code block 第一行的版本号(详见 [help-mode delta](../help-mode/spec.md))
- 平台镜像 `platforms/<p>/<n>/SKILL.md` 内 `## Help` 段 code block 第一行的版本号(若 Help 段存在)
- 仓库根 [`/CHANGELOG.md`](../../../../CHANGELOG.md) 中 `## <skill-name>` H2 段下的 top-most `### [X.Y.Z]` 条目

skill-lint 规则 S29 SHALL 强制 marketplace.json 各 plugin `version` 是 SemVer 2.0.0 格式,违反报 error。

#### Scenario: marketplace.json plugin version 是 SemVer 2.0.0

- **WHEN** `.claude-plugin/marketplace.json` 含 `{"name": "claim-ground", "version": "1.2.0"}`
- **THEN** S29 通过该 plugin 的 SemVer 校验

#### Scenario: marketplace.json plugin version 非 SemVer

- **WHEN** marketplace.json 含 `"version": "v1.2"`(前缀 v + 两段)或 `"version": "1.2.3.4"`(四段)
- **THEN** S29 报 error: "marketplace.json plugin '<n>' version='<x>' is non-SemVer-2.0.0 format"
- **AND** 修复 SHALL 为改为 `MAJOR.MINOR.PATCH` 三段格式

#### Scenario: 集合级 plugin.json 不在本 SSOT 范围

- **WHEN** 修改 [plugin.json](../../../../plugin.json) 与 [.claude-plugin/plugin.json](../../../../.claude-plugin/plugin.json) 中的集合 `version`
- **THEN** S29 SHALL 不检查这两份文件(它们是集合级元数据,非 skill 级)
- **AND** 这两份文件继续受现有 [repo-invariants § Plugin metadata 双份一致](../../../specs/repo-invariants/spec.md) 规则约束(仅要求两份字面量相等)

### Requirement: marketplace integrity 锁步范围 MUST 同时含 hash 与 version

[scripts/recalc-all-hashes.sh](../../../../scripts/recalc-all-hashes.sh) 的职责保持单一(仅重算 SHA-256);版本锁步通过 lint S29/S30/S31 强制(fail-loud),不通过脚本 silent-sync。修改 SKILL.md 后开发者 MUST 跑:

```bash
bash scripts/recalc-all-hashes.sh                # 重算 hash
bash skills/skill-lint/scripts/skill-lint.sh .   # 校验 SemVer + frontmatter regression guard + help-card + CHANGELOG + 其余规则
```

任意一项不通过 = 变更未完成。该约定 SHALL 反映在 [CLAUDE.md § 自检三命令](../../../../CLAUDE.md) 中。

#### Scenario: 开发者 bump 了 marketplace.json version 但忘了改 help-card / CHANGELOG

- **WHEN** 开发者改动 `.claude-plugin/marketplace.json` 把 `claim-ground.version` 从 `1.2.0` 改为 `1.3.0`
- **AND** 未改 `skills/claim-ground/SKILL.md` 的 `## Help` 段第一行(仍 `Claim Ground v1.2.0 — ...`)
- **AND** 未在 `/CHANGELOG.md` `## claim-ground` 段顶部插入 `### [1.3.0]`
- **THEN** S30 报 error("help-card v1.2.0 ≠ marketplace v1.3.0")
- **AND** S31 报 error("frontmatter ... — wait, S31 直接比对 marketplace v1.3.0 ≠ CHANGELOG top v1.2.0")
- **AND** PR 阻塞,开发者必须同步 help-card + CHANGELOG

### Requirement: 仓库根 MUST 持有 `/CHANGELOG.md`,每次 marketplace.json version 变化 MUST 同步登记

仓库根 MUST 持有单个 `/CHANGELOG.md` 文件作为所有 skill 的版本变更登记。该文件 SHALL 满足:

- 顶层标题 `# Forge Changelog`
- 每个 skill 一个 `## <skill-name>` H2 段(skill-name 与 `skills/<n>/` 目录名一致,匹配 [.skill-lint.json](../../../../.skill-lint.json) `naming-pattern` 正则 `^[a-z]+-[a-z]+$`)
- 每个版本一个 `### [<X.Y.Z>] — <YYYY-MM-DD>` H3 段(date 可选;允许只写 `### [<X.Y.Z>]`)
- 每个 skill 段下的**第一个** `### [X.Y.Z]` 条目即"latest",其版本字面量 MUST 等于该 skill 的 `.claude-plugin/marketplace.json` `plugins[].version`

每次 PR 改动 marketplace.json 的 plugin `version`(MAJOR / MINOR / PATCH 任一)MUST 在同 PR 内于 CHANGELOG.md 该 skill 段顶部插入新的 `### [<new-version>]` 条目;条目内容 SHOULD 简明描述 Added / Changed / Deprecated / Removed / Fixed / Security 子节(参 [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/)),并 SHOULD 含一行 "Reference: openspec/changes/<id>/proposal.md" 指向相应 RFC。

skill-lint 规则 S31 SHALL 在 lint 阶段强制 marketplace plugin version 与 CHANGELOG top entry 一致,违反报 error。CHANGELOG.md 缺失视为整体 fail("S31: CHANGELOG.md missing at repo root")。

CHANGELOG.md 格式 SHALL 选 Keep-a-changelog 风格(非 forge 自创格式),理由:
- 业界通用,新贡献者无学习成本
- 工具链生态丰富(release-please / changelog-from-prs / 等),为未来自动化留口
- 结构化(### sub-headings)便于 lint 解析

#### Scenario: 新增 skill 时 CHANGELOG.md MUST 含对应段

- **WHEN** 新增 skill `<new>`,marketplace.json 加入 `{"name": "<new>", "version": "1.0.0"}`
- **AND** `/CHANGELOG.md` 不含 `## <new>` H2 段
- **THEN** S31 报 error: "CHANGELOG.md has no `## <new>` section ..."
- **AND** PR 阻塞;修复 SHALL 为追加 `## <new>` 段 + `### [1.0.0]` 条目

#### Scenario: bump version 但忘了加 CHANGELOG entry

- **WHEN** 改 marketplace.json `claim-ground.version: 1.2.0 → 1.3.0`
- **AND** 未在 CHANGELOG.md `## claim-ground` 段顶部插入 `### [1.3.0]`
- **THEN** S31 报 error: "skills/claim-ground: marketplace v1.3.0 ≠ CHANGELOG top entry v1.2.0 (add `### [1.3.0]` under `## claim-ground`)"

#### Scenario: CHANGELOG.md 整体不存在

- **WHEN** 仓库根 `/CHANGELOG.md` 不存在
- **AND** `.skill-lint.json` 启用 `verify-changelog-entry: true`
- **THEN** S31 报 error: "CHANGELOG.md missing at repo root (required when verify-changelog-entry is enabled)"
- **AND** 该 error 仅出现一次(整体 fail),不 per-skill 重复

#### Scenario: 历史条目可选不含 date

- **WHEN** `## news-fetch` 段下条目为 `### [1.0.0]`(无 `— YYYY-MM-DD` 后缀)
- **THEN** S31 SHALL 仍认可该条目为合法 latest
- **AND** date 字段属于 SHOULD 而非 MUST

#### Scenario: top entry 必须置顶,不允许倒序

- **WHEN** `## insight-fuse` 段下条目顺序为 `### [3.3.0]` 在前 / `### [3.4.0]` 在后(time-asc 错误)
- **THEN** S31 SHALL 把第一个出现的 `### [3.3.0]` 视作 top entry
- **AND** marketplace v3.4.0 ≠ top v3.3.0 → 报 error
- **AND** 修复 SHALL 为重排 entries 至 time-desc 顺序(latest 置顶,Keep-a-changelog 标准实践)

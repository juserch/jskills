# Platform-Parity Spec Delta — Help-card 版本号 MUST 同步 marketplace SSOT

> **架构注释(2026-05-07 修订)**:本 delta 早期版本曾要求 `platforms/<p>/<n>/SKILL.md` frontmatter `version` 字段同步 canonical frontmatter。架构 pivot 后(因 Claude Code 官方 schema 拒绝 `version` frontmatter 字段),**两侧 frontmatter 都不持有 `version` 字段**。Platform mirror 的版本同步现在仅约束:(a) help-card 第一行 `v<X.Y.Z>` 等于 marketplace SSOT;(b) frontmatter 不出现 version 字段(由 [repo-invariants delta](../repo-invariants/spec.md) S29 regression guard 强制)。本 delta 反映 pivot 后的最终架构。
>
> **policy 协同**:description 措辞放宽政策(允许 platform-aware wording,如 claim-ground openclaw description 用 `message:received / agent:bootstrap` 替代 Claude Code 五 hook 名)由独立 change [openspec/changes/openclaw-drift-fix](../../openclaw-drift-fix/proposal.md) 的 [platform-parity delta](../../openclaw-drift-fix/specs/platform-parity/spec.md) 处理。本 delta 仅约束版本号同步。

## ADDED Requirements

### Requirement: 平台 SKILL.md help-card 第一行 MUST 同步 marketplace.json plugin version

若 `platforms/<p>/<n>/SKILL.md` 含 `## Help` 段(heading 允许 `## Help` 严格形式或 `## Help <variant>`,例如 `## Help (no arguments)`),其内 code block 第一行 MUST 匹配 `^[A-Z][A-Za-z0-9 -]+ v(\d+\.\d+\.\d+) — .+$` 且捕获组版本字面量等于 `.claude-plugin/marketplace.json` 中对应 plugin entry 的 `version`(canonical SSOT,详见 [repo-invariants delta](../repo-invariants/spec.md))。

skill-lint 规则 S30 SHALL 强制此契约,违反报 error。若 `platforms/<p>/<n>/SKILL.md` 不含 `## Help` 段,S30 SHALL 跳过该 (platform, skill) 对而不报 error(补齐 Help 段属于 platform-parity 现有契约范围,非 S30 责任)。

#### Scenario: openclaw mirror 含 Help 段且版本号同步 marketplace

- **WHEN** `platforms/openclaw/insight-fuse/SKILL.md` `## Help` 段 code block 第一行为 `Insight Fuse v3.4.0 — Systematic multi-source research engine (8-stage pipeline)`
- **AND** `.claude-plugin/marketplace.json` `insight-fuse.version: 3.4.0`
- **THEN** S30 通过

#### Scenario: openclaw mirror 含 Help 段但版本号过期

- **WHEN** `platforms/openclaw/claim-ground/SKILL.md` `## Help` 段 code block 第一行为 `Claim Ground v1.1.0 — Epistemic constraint engine ...`
- **AND** marketplace.json `claim-ground.version: 1.2.0`
- **THEN** S30 报 error,提示 "platforms/openclaw/claim-ground: help-card v1.1.0 ≠ marketplace v1.2.0"
- **AND** 修复 SHALL 为升 mirror help-card 至 marketplace SSOT

#### Scenario: 变体 heading `## Help (no arguments)` 仍受检

- **WHEN** [platforms/openclaw/tome-forge/SKILL.md L107](../../../../platforms/openclaw/tome-forge/SKILL.md#L107) heading 为 `## Help (no arguments)`(非严格 `## Help`)
- **AND** code block 第一行为 `Tome Forge v1.1.0 — Personal Knowledge Base Engine`
- **AND** marketplace.json `tome-forge.version: 1.1.0`
- **THEN** S30 SHALL 识别该段为 Help 段(用 `^##\s+Help\b` 正则)
- **AND** 版本号字面量与 marketplace 比对通过即视为 PASS

#### Scenario: 平台 mirror 无 Help 段则跳过

- **WHEN** `platforms/openclaw/<some-mirror>/SKILL.md` 不含任何 `## Help` 段
- **THEN** S30 SHALL 跳过该 (platform, skill) 对
- **AND** 不报 "missing Help section" 类 error(此责任归属 [openclaw-drift-fix](../../openclaw-drift-fix/tasks.md) Task 2 与 platform-parity 现有契约;非 S30 责任)

### Requirement: 平台 mirror frontmatter 共享 canonical 的 frontmatter 不持 version 约束

`platforms/<p>/<n>/SKILL.md` frontmatter MUST NOT 含 `version:` 字段(顶层或嵌套于任何子结构)。理由与 canonical 相同——Claude Code 官方 schema 不支持 `version` 字段。

skill-lint 规则 S29 SHALL 在 lint 阶段对 platform mirrors 运行同样的 frontmatter regression guard,违反报 error。

#### Scenario: 平台 mirror frontmatter 含 version 字段

- **WHEN** `platforms/openclaw/<some-skill>/SKILL.md` frontmatter 含 `version: 1.0.0` 顶层字段
- **THEN** S29 报 error: "platforms/openclaw/<some-skill>/SKILL.md frontmatter contains `version:` field (forbidden)"
- **AND** 修复 SHALL 为删除该字段;skill 版本号通过 marketplace.json 承载,help-card 反映

### Requirement: 改 marketplace.json plugin `version` 时 platform mirror help-card MUST 在同 PR 内同步

[openspec/specs/skill-lifecycle/spec.md § 场景 B](../../../specs/skill-lifecycle/spec.md) 的修改 skill 审计清单 SHALL 增补:若 `.claude-plugin/marketplace.json` 中 `plugins[name=<n>].version` 被改动,**且** `platforms/<p>/<n>/SKILL.md` 含 `## Help` 段,该 PR 内 MUST 同步 platform mirror help-card 第一行版本字面量。

不允许"先合 canonical,平台 follow-up"分阶段同步——这种模式正是当前 marketplace.json 与 SKILL.md 飘移的根因(canonical 升了但下游元数据漏更)。

#### Scenario: 升 marketplace.json version 但忘改 platform mirror help-card

- **WHEN** PR 改 `.claude-plugin/marketplace.json` `insight-fuse.version: 3.4.0 → 3.5.0`
- **AND** 改了 `skills/insight-fuse/SKILL.md` Help 段第一行至 `v3.5.0`
- **AND** 未改 `platforms/openclaw/insight-fuse/SKILL.md` Help 段第一行(仍 `v3.4.0`)
- **THEN** `bash skills/skill-lint/scripts/skill-lint.sh .` 报 S30 error: "platforms/openclaw/insight-fuse: help-card v3.4.0 ≠ marketplace v3.5.0"
- **AND** PR 阻塞,作者必须在同 PR 内升 platform mirror help-card

#### Scenario: 平台 mirror 当前不存在 Help 段,canonical bump 时是否要补 Help

- **WHEN** PR 升 `.claude-plugin/marketplace.json` `block-break.version: 1.0.0 → 1.1.0`
- **AND** `platforms/openclaw/block-break/SKILL.md` 当前无 Help 段(early state)
- **THEN** S30 自动跳过 platform mirror Help-card 检查(无 Help 段)
- **AND** PR 不要求作者补 Help 段(非本 spec delta 责任;由 [openclaw-drift-fix](../../openclaw-drift-fix/tasks.md) Task 2 处理 5 个 mirror 的 Help 段补齐)

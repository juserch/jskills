# Help-Mode Spec Delta — Help card 第一行 MUST 含版本号

> **架构注释(2026-05-07 修订)**:本 delta 早期版本曾把 SKILL.md frontmatter `version:` 字段定为 SSOT,help-card 版本号比对 frontmatter。架构 pivot 后(因 Claude Code 官方 schema 拒绝 `version` frontmatter 字段),**SSOT 改为 `.claude-plugin/marketplace.json` `plugins[].version`**,help-card 版本号字面量直接比对 marketplace。本 delta 反映 pivot 后的最终架构。

## MODIFIED Requirements

### Requirement: SKILL.md `## Help` 段 code block 第一行 MUST 是 `<Skill Name> v<X.Y.Z> — <one-line tagline>`

[openspec/specs/help-mode/spec.md § SKILL.md `## Help` 段落模板](../../../specs/help-mode/spec.md) 的模板 A 与模板 B 在 code block 第一行 MUST 含版本号字面量。版本号字面量 SHALL 等于 `.claude-plugin/marketplace.json` `plugins[].version` 字段(SSOT,详见 [repo-invariants spec delta](../repo-invariants/spec.md))。

格式 SHALL 严格匹配正则:

```regex
^[A-Z][A-Za-z0-9 -]+ v\d+\.\d+\.\d+ — .+$
```

skill-lint 规则 S30 SHALL 在 lint 阶段检测:

1. 该 SKILL.md 的 `## Help` 段(heading 允许 `## Help` 严格形式或 `## Help <variant>` 如 `## Help (no arguments)`)是否含 code block
2. 该 code block 第一行是否匹配上述正则
3. 捕获组中的版本号字面量是否等于 marketplace.json 中对应 plugin 的 `version`

S30 同时校验 canonical [skills/<n>/SKILL.md](../../../../skills) 与每个平台镜像 [platforms/<p>/<n>/SKILL.md](../../../../platforms);若平台 mirror 不含 Help 段,S30 SHALL 跳过该 (platform, skill) 对(详见 [platform-parity delta](../platform-parity/spec.md))。

任一不满足即报 error。允许第一行后跟空行 + Usage 段(与现状一致),不允许在版本号前插入装饰字符(如 emoji / 引导词)。

#### Scenario: 模板 A 含版本号

- **WHEN** `skills/insight-fuse/SKILL.md` 的 `## Help` 段 code block 第一行为 `Insight Fuse v3.4.0 — Systematic multi-source research engine (8-stage pipeline)`
- **AND** marketplace.json `insight-fuse.version: 3.4.0`
- **THEN** S30 通过

#### Scenario: 模板 B 含版本号

- **WHEN** `skills/block-break/SKILL.md` 的 `## Help` 段 code block 第一行为 `Block Break v1.0.0 — Behavioral constraint engine (L0-L4 pressure escalation)`
- **AND** marketplace.json `block-break.version: 1.0.0`
- **THEN** S30 通过

#### Scenario: help card 与 marketplace 飘移

- **WHEN** marketplace.json `claim-ground.version: 1.2.0`
- **AND** help card 第一行为 `Claim Ground v1.1.0 — Epistemic constraint engine ...`(假想飘移)
- **THEN** S30 报 error,提示 "skills/claim-ground: help-card v1.1.0 ≠ marketplace v1.2.0"
- **AND** 修复方式 SHALL 为升 help card 字面量至 SSOT,不允许反向降 marketplace

#### Scenario: 缺少版本号

- **WHEN** `skills/tome-forge/SKILL.md` 的 `## Help` 段 code block 第一行为 `Tome Forge — Personal Knowledge Base Engine`(无 v 字段,early pre-version-governance 状态)
- **THEN** S30 报 error,提示 "skills/tome-forge/SKILL.md help-card first line does not match `<Name> v<X.Y.Z> — <tagline>` pattern"
- **AND** 修复方式 SHALL 为追加 `v<marketplace-version>` 至 Skill Name 之后

#### Scenario: 历史叙述行豁免

- **WHEN** SKILL.md 正文(非 `## Help` 段 code block 内)出现 `v1.1 新增 Stage 6.5` / `v3.4 引入 C18` 等历史叙述行
- **THEN** S30 SHALL 不检查该行
- **AND** 仅 `## Help` 段 code block 第一行受 S30 约束
- **AND** 历史叙述行的版本号正确性由 reviewer 人工核对

#### Scenario: vX.Y 简写不匹配

- **WHEN** help card 第一行为 `Claim Ground v1.2 — ...`(缺 PATCH 段)
- **AND** marketplace.json `claim-ground.version: 1.2.0`
- **THEN** S30 报 error,提示 "first line does not match `<Name> v<X.Y.Z> — <tagline>` pattern"(正则要求三段 SemVer)
- **AND** 修复方式 SHALL 为补全为 `v1.2.0`(与 SSOT 完全字面量一致)

#### Scenario: 平台 mirror Help 段变体 heading

- **WHEN** [platforms/openclaw/tome-forge/SKILL.md](../../../../platforms/openclaw/tome-forge/SKILL.md) heading 为 `## Help (no arguments)`(不严格等于 `## Help`)
- **AND** code block 第一行为 `Tome Forge v1.1.0 — Personal Knowledge Base Engine`
- **AND** marketplace.json `tome-forge.version: 1.1.0`
- **THEN** S30 SHALL 用 `^##\s+Help\b` 正则识别该段为 Help 段,版本号比对通过即 PASS
- **AND** 该规则同样适用 canonical;允许 wording 变体提高灵活性

### Requirement: help-mode spec 模板 A/B 的示例 SHALL 反映新格式

[openspec/specs/help-mode/spec.md](../../../specs/help-mode/spec.md) 的「模板 A」与「模板 B」示例 code block 第一行 SHALL 由 `<Skill Name> — <one-line purpose>` 升级为 `<Skill Name> v<X.Y.Z> — <one-line purpose>`。模板说明文字 SHALL 标注:

- 版本号 SSOT 来源为 `.claude-plugin/marketplace.json` `plugins[].version`(**不是** SKILL.md frontmatter)
- 必须使用三段 SemVer 字面量(不允许 vX.Y 简写)
- skill-lint S30 校验该行格式
- canonical 与 platform mirror(若含 Help 段)同等校验

#### Scenario: 新 skill 作者按模板创建 SKILL.md

- **WHEN** 新 skill `<example>` 作者复制模板 A
- **AND** 填入 `## Help` 段 code block 第一行 `Example Skill v0.1.0 — Demo for new contributors`
- **AND** 同 PR 在 marketplace.json 加入 `{"name": "<example>", "version": "0.1.0"}`
- **AND** 同 PR 在 CHANGELOG.md 加 `## <example>` + `### [0.1.0]` 条目
- **THEN** S29 / S30 / S31 全部通过
- **AND** 用户运行 `/<example>-skill help` 看到的第一行包含版本号 v0.1.0

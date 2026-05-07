# Platform-Parity Spec Delta — Description 措辞放宽 + metadata.permissions 仍严格

## MODIFIED Requirements

### Requirement: Description / metadata.permissions 同步规则差异化

[openspec/specs/platform-parity/spec.md](../../../specs/platform-parity/spec.md) §"平台版与规范版的关系" 现行 L60 措辞为:

> "修改规范版的 description / metadata.permissions 时 MUST 同步平台版"

该措辞将 description 与 metadata.permissions 一并要求 MUST 字面量同步,与 platform-aware 适配现实冲突。本 spec delta 把它拆分为两条差异化规则:

**(a) description 语义/范畴 MUST 一致;允许 platform-specific wording**

修改规范版 SKILL.md 的 `description` 字段时,平台版的 description 字段 SHALL 保持**语义/范畴一致**(skill 用途、覆盖的功能集、目标场景描述一致),但**允许 platform-specific wording** 反映本平台实际事件名 / 工具名 / 命令名 / 触发器名 / 安装命令名等运行时差异。Platform mirror SHALL NOT 引入 canonical 不存在的能力声明(避免暗藏分支行为);也 SHALL NOT 删除 canonical 已声明的核心能力(以免规避平台-parity 笛卡尔积要求)。

**(b) metadata.permissions MUST 字面量同步**

修改规范版 SKILL.md 的 `metadata.permissions` 字段(`network` / `filesystem` / `execution` / `tools`)时,平台版的相同字段 MUST 字面量同步。permissions 是能力契约,飘移会改变安全模型。skill-lint 持续强制此契约(S22 platform-parity 子句已覆盖此判据)。

#### Scenario: claim-ground description 合理 platform-aware 分化

- **WHEN** canonical [skills/claim-ground/SKILL.md L3](../../../../skills/claim-ground/SKILL.md#L3) description 含 "dispatches across UserPromptSubmit / PreToolUse / PostToolUse / SessionStart hooks"(Claude Code 五 hook 名)
- **AND** platform mirror [platforms/openclaw/claim-ground/SKILL.md L3](../../../../platforms/openclaw/claim-ground/SKILL.md#L3) description 含 "dispatches across message:received / agent:bootstrap events on OpenClaw"(openclaw 二 event 名)
- **THEN** description 语义一致("跨多 hook/event 触发认知约束"),仅 wording 反映各自平台实际事件名,本规则 PASS
- **AND** 不强制要求两侧 description 字面量相等

#### Scenario: 不允许 platform mirror 引入 canonical 没有的能力声明

- **WHEN** canonical description 不包含 "auto-fixes destructive bash patterns" 字样
- **AND** 假想 platform mirror description 加入 "auto-fixes destructive bash patterns"
- **THEN** 本规则 VIOLATION — 该能力 canonical 没声明,mirror 不能单独引入
- **AND** 修复 SHALL 为先在 canonical 加该能力 + 实现,然后 mirror 可同步声明

#### Scenario: 不允许 platform mirror 删除 canonical 核心能力

- **WHEN** canonical description 含 "5 hook surfaces"
- **AND** 假想 platform mirror description 删除该短语,只写 "constraint engine"
- **THEN** 本规则 VIOLATION — 删除核心能力声明等于 platform mirror 暗示能力子集化,违反笛卡尔积底线
- **AND** 修复 SHALL 为补回核心能力短语(可改写 wording,但语义/范畴必须保留)

#### Scenario: metadata.permissions 字面量同步

- **WHEN** canonical [skills/claim-ground/SKILL.md L9-12](../../../../skills/claim-ground/SKILL.md#L9) `permissions: { network: false, filesystem: read-write, execution: none, tools: [Read, Write, Bash, Grep] }`
- **AND** [platforms/openclaw/claim-ground/SKILL.md L9-12](../../../../platforms/openclaw/claim-ground/SKILL.md#L9) `permissions: { network: false, filesystem: read-write, execution: none, tools: [Read, Write, Bash, Grep] }`
- **THEN** 本规则 PASS

#### Scenario: metadata.permissions 飘移触发 violation

- **WHEN** canonical permissions filesystem: read-write
- **AND** platform mirror permissions filesystem: read-only(假想飘移)
- **THEN** 本规则 VIOLATION(严重),提示 "platforms/openclaw/<skill>: permissions.filesystem read-only ≠ canonical read-write"
- **AND** 修复 SHALL 为升 platform 同步至 canonical(SSOT 方向不变)

### Requirement: by-design 平台适配的合规判定

平台 mirror **MAY** 通过显式 SKILL.md body 段落声明的 by-design 适配,在 metadata.permissions 同步规则之外保留功能等价但实现不同的偏离。判据:

- 必须在 platform mirror SKILL.md 主体含明确段落(标题级 H2 或 H3)说明 by-design 偏离与平台等价实现策略
- 偏离 SHALL NOT 改变能力契约的"是否可用",只能改变"如何实现"
- by-design 段落 SHALL 含至少一行 verbatim 解释(描述平台实际机制),并参引 [docs/design/cross/openclaw-capability-gap-design.md](../../../../docs/design/cross/openclaw-capability-gap-design.md)(如该 design 文档存在)

#### Scenario: ralph-boost openclaw 用 bash 脚本替代 Agent

- **WHEN** canonical ralph-boost frontmatter `tools: [Read, Write, Bash, Agent]`
- **AND** platform mirror frontmatter `tools: [Read, Write, Bash]`(缺 Agent)
- **AND** [platforms/openclaw/ralph-boost/SKILL.md L22-24](../../../../platforms/openclaw/ralph-boost/SKILL.md#L22) 含 "此版本适配无 Agent 工具的平台(如 OpenClaw)。循环通过 bash 脚本 `boost-loop.sh` 驱动"
- **THEN** 这是 by-design 适配,**不**触发 metadata.permissions 同步 violation
- **AND** 偏离合法,因为(a)有显式 SKILL.md body 段落说明、(b)能力 "autonomous dev loop" 在两平台都可用,只是实现不同

#### Scenario: council-fuse openclaw 用 in-context 三轮独立推理替代 multi-agent spawn

- **WHEN** canonical council-fuse `tools: [Agent, Read, Write, Glob, Edit]`
- **AND** platform mirror `tools: [Read, Write, Glob, Edit]`(缺 Agent)
- **AND** [platforms/openclaw/council-fuse/SKILL.md L128-130](../../../../platforms/openclaw/council-fuse/SKILL.md#L128) 含表格 "并行: 3 个独立 Agent 并行 spawn(canonical) | 单 agent 内三轮独立推理(openclaw)"
- **THEN** by-design 适配,合规

#### Scenario: 缺少 by-design 说明则不能豁免

- **WHEN** 某假想 platform mirror frontmatter 偏离 canonical metadata.permissions
- **AND** SKILL.md 主体**没有**对应 by-design 说明段落
- **THEN** 本规则 VIOLATION,触发 metadata.permissions 同步检查
- **AND** 修复 SHALL 为(a)补 by-design 段落 + 引用 design doc,或(b)同步 frontmatter 至 canonical

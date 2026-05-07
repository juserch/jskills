# Design

> 影响分类:cross(跨 5 platforms/openclaw skill mirror + 1 schema-template + 1 lint script + 1 spec + 1 design doc;不归属任何单一 forge 4 分类)

## 决策 1 — skill-lint openclaw mirror 选 byte-identical wholesale 同步,不增量 patch

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A(采纳)** | `cp skills/skill-lint/scripts/skill-lint.sh platforms/openclaw/skill-lint/scripts/skill-lint.sh`(byte-identical 覆盖) | 简单;mirror 不应有 platform-specific 改动(skill-lint 本身是仓库级工具,其行为在两平台上语义一致);避免增量 patch 时的边界条件 |
| B | 仅同步 S29/S30/S31 增量(~190 行 + 3 CFG vars + 3 解析行) | **拒绝**:mirror 与 canonical 之间已有的 211 行差异(806 vs 1017)说明历史飘移积累;增量 patch 无法保证未来不再积累 |

**反例验证**:[diff -q skills/skill-lint/scripts/skill-lint.sh platforms/openclaw/skill-lint/scripts/skill-lint.sh](../../../skills/skill-lint/scripts/skill-lint.sh) 应返回空表示 byte-identical。如果未来 openclaw 需要平台特定行为,再考虑分叉,而不是从飘移开始反推。

**落实**:Step 1。

## 决策 2 — 5 个 mirror Help 段:复制 canonical + 保留 platform-aware hook 引用

canonical Help 段大量提到"Auto via UserPromptSubmit hook" 等 Claude Code 特定术语。openclaw 上要不要照抄?

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A(采纳)** | 复制 canonical Help 段;保留 "How it normally activates" 段中 Claude Code hook 名(因为该信息描述 canonical 行为,对 openclaw 用户也是有用的对照) | Help 段本质是"Skill 是干什么的、怎么用的"信息,不强绑定运行时;一致 wording 降低维护成本 |
| B | 把 Help 段中 Claude Code hook 名替换为 openclaw event 名 | **拒绝**:5 个 mirror 各自微调 Help 文本会引入新的飘移点;且 5 个 mirror 中 4 个对应的 canonical hook 在 openclaw **无等价**(per [docs/design/cross/openclaw-capability-gap-design.md](../../../docs/design/cross/openclaw-capability-gap-design.md)),改写也无法说清 |
| C | 在 Help 段顶部加一行 "On OpenClaw, see § 平台 hook 等价位置 below" | **拒绝**:增加结构复杂度;新读者要追第二段才理解 |

**反例验证**:[platforms/openclaw/claim-ground/SKILL.md L18-50](../../../platforms/openclaw/claim-ground/SKILL.md#L18) 的 Help 段已经是 canonical 的近似复制(只 v1.1 → v1.2.0 这种版本更新),实际产品上没造成混淆。

**落实**:Step 2(5 个 SKILL.md 各 Edit 一次)。

## 决策 3 — tome-forge schema-template 选 byte-identical wholesale 覆盖

理由同决策 1。schema-template 是数据契约文档,不应有 platform-aware 内容。

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A(采纳)** | byte-identical 覆盖 | 简单,降低未来漂移可能 |
| B | 增量 patch 缺失的 "Maturity Transitions" 段 + 字段描述 | 同 G2,无理由增量 |

**落实**:Step 3。

## 决策 4 — D1 description 政策放宽,新增 MODIFIED Requirement 而非全文重写 spec

[openspec/specs/platform-parity/spec.md L60](../../../openspec/specs/platform-parity/spec.md#L60) 现行措辞:"修改规范版的 description / metadata.permissions 时 MUST 同步平台版"。本 change 通过 spec delta 引入 MODIFIED Requirement,**保留 metadata.permissions MUST 字面量同步**,**放宽 description 为语义/范畴一致**。

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A(采纳)** | spec delta MODIFIED Requirement,差异化处理 description vs metadata.permissions | 不动 metadata.permissions 严格性(由 S29 强制 — 注:S29 现已迁移到 marketplace SSOT,不再校验 frontmatter version,但仍然 transitively 校验权限同步通过其他规则);放宽 description 字面同步要求,允许 platform-aware wording |
| B | 整体放宽"description / metadata.permissions"两个字段 | **拒绝**:metadata.permissions 是能力契约,不能放宽;权限飘移会改变安全模型 |
| C | 整体维持严格 | **拒绝**:claim-ground description 现实上已经合理分化,再要求严格同步等于强迫消除 platform-specific 信息 |

**反例验证**:claim-ground openclaw description 把"dispatches across UserPromptSubmit / PreToolUse / PostToolUse / SessionStart hooks"替换为"dispatches across message:received / agent:bootstrap events on OpenClaw"——这是 truthful 的 platform-aware 措辞,canonical 与 openclaw 各反映自己平台实际能力。

**落实**:Step 4(写 [specs/platform-parity/spec.md](specs/platform-parity/spec.md) delta)。

## 决策 5 — design doc 落 [docs/design/cross/](../../../docs/design/cross/) 命名空间

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A(采纳)** | `docs/design/cross/openclaw-capability-gap-design.md` | 跨 8 skill + 跨 platform-parity / skill-lifecycle / repo-invariants 多个 spec 主题,符合 cross 命名空间(per [openspec/specs/repo-invariants/spec.md](../../../openspec/specs/repo-invariants/spec.md) "横向设计文档") |
| B | `platforms/openclaw/README.md` | **拒绝**:platforms/ 目录下放设计文档与 SKILL.md 镜像混淆;且 design 文档应在 docs/design/ 单一入口 |

**反例验证**:[docs/design/cross/](../../../docs/design/cross/) 已存在(由 [.skill-lint.json](../../../.skill-lint.json) `protect-cross-namespace: true` + S26 lint 守护 cross- 命名空间不与任何 skill 重名)。

**落实**:Step 5。

## 风险与回滚

- **R1 byte-identical 同步抹掉了 platform-specific 修改** — 若 openclaw skill-lint 历史上有人加过 platform-specific 行为(unlikely 但 possible),覆盖会丢失。
  **缓解**:Step 1 前 grep `git log -p platforms/openclaw/skill-lint/scripts/` 看 history;无 platform-specific commits 则 wholesale 覆盖安全。

- **R2 5 mirror Help 段大量 Claude Code hook 引用** — openclaw 用户读到"Auto via UserPromptSubmit hook"会困惑(本平台无此机制)。
  **缓解**:design doc § 4 by-design 适配清单 + § 5 永久豁免列表清楚解释;Help 段内 "How it normally activates" 仅描述 canonical 行为,不影响功能调用。Follow-up RFC 可在该段加一句 "On OpenClaw, see § 平台 hook 等价位置"。

- **R3 D1 spec 放宽后,description 平台分化无界** — 是否会演化成"两份 description 完全不一样"?
  **缓解**:spec delta 明确"语义/范畴 MUST 一致",lint 没有自动检查但 reviewer 在 PR review 时可比对;follow-up RFC `S32 platform-content-parity` 可加自动结构相似度检查。

- **回滚路径**:每 Step 都是独立改动,失败则 `git checkout -- <file>` 单步回滚。

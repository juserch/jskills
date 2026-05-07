# OpenClaw Capability Gap — Design Reference

> 长期参考文档。目的:为新 skill 设计、contributor onboarding、follow-up RFC 提供 openclaw 与 Claude Code(canonical)的能力差异事实。本文档**不引入新规则**——规则在 [openspec/specs/platform-parity/spec.md](../../../openspec/specs/platform-parity/spec.md) 与各 change spec deltas 中。
>
> 创建于 2026-05-07,随 [openspec/changes/archive/openclaw-drift-fix](../../../openspec/changes/archive/openclaw-drift-fix/proposal.md) 落地。

## 1. OpenClaw 一句话定义

**OpenClaw** 是 forge 仓库 [platforms/openclaw/](../../../platforms/openclaw/) 镜像所对应的目标运行时:**事件驱动的 hook 系统**,使用 TypeScript handler 文件 + `HOOK.md` 元数据声明,通过命名事件(如 `message:received` / `agent:bootstrap`)派发逻辑。

与 Claude Code 的核心架构差异:

| 维度 | Claude Code(canonical) | OpenClaw |
|---|---|---|
| Hook 实现语言 | Bash 脚本(`*.sh`) | TypeScript(`handler.ts`)+ 编译产物 `handler.js` |
| Hook 注册 | 仓库级 `hooks/hooks.json` 集中注册 | 每个 hook 自含 `HOOK.md` frontmatter `metadata.openclaw.events[]` 声明事件 |
| 事件层级 | 工具/会话/输入层(UserPromptSubmit / PreToolUse / PostToolUse / SessionStart / Stop) | 消息/会话/网关/命令层(message:* / session:* / agent:bootstrap / gateway:startup / command:*) |
| Sub-agent spawn | 通过 `tools: [Agent]` 工具 + `Task` 调度 | 无原生 sub-agent spawn 机制(skill 用其他模式适配,如三轮独立推理 / bash 脚本驱动) |
| 安装/启用 | `claude plugin add <repo>` | `openclaw plugins install <repo>` + `openclaw hooks enable <hook-name>` |
| 运行时依赖 | bash + POSIX 标准工具(零依赖原则) | Node.js(handler.js 执行环境);零 npm 包依赖 |

## 2. Claude Code 五 hook → OpenClaw event 对照表

事实来源:[platforms/openclaw/claim-ground/hooks/openclaw/](../../../platforms/openclaw/claim-ground/hooks/openclaw)(已镜像 3 hook 的 verbatim handler.ts + HOOK.md)。

| Claude Code Hook | OpenClaw 等价 event | 镜像状态 | 已镜像的 skill |
|---|---|---|---|
| **UserPromptSubmit**(用户输入) | `message:received` | ✓ 可镜像 | claim-ground:`prompt-gate` / `epistemic-pushback` |
| **SessionStart**(会话启动 / resume / clear) | `agent:bootstrap` | ✓ 可镜像 | claim-ground:`session-anchor` |
| **PreToolUse**(工具执行前) | **(无原生等价)** | ✗ 永久豁免 | claim-ground 的 `pre-tool-gate` 已声明"无等价机制可用" |
| **PostToolUse**(工具执行后) | **(无原生等价)** | ✗ 永久豁免 | claim-ground 的 `evidence-reminder` / block-break 的 `failure-detector` 已声明 |
| **Stop**(会话结束) | (未调研) | — | 当前无 skill 使用 |

**OpenClaw 完整 event 集**(参 [platforms/openclaw/claim-ground/hooks/openclaw/*/HOOK.md](../../../platforms/openclaw/claim-ground/hooks/openclaw)):
`agent:bootstrap` / `gateway:startup` / `message:received` / `message:sent` / `message:transcribed` / `message:preprocessed` / `session:patch` / `command` / `command:new` / `command:reset`

claim-ground v1.2 仅用其中 2 个(`message:received` / `agent:bootstrap`)。

## 3. 8 个 skill 的镜像状态矩阵(post openclaw-drift-fix)

| Skill | canonical 文件数 | mirror 文件数 | mirror 完备度 | 飘移点 |
|---|---|---|---|---|
| **block-break** | 10 | 6 | 中 | 4 个 hook 全标"无等价机制可用"豁免(已文档化);[platforms/openclaw/block-break/SKILL.md L103-115](../../../platforms/openclaw/block-break/SKILL.md#L103) 含完整等价位置段 |
| **claim-ground** | 13 | 16 | 高 | hook 系统重组(canonical bash + hooks.json → openclaw handler.ts + HOOK.md 子目录);3/5 hook 已镜像,2/5(pre-tool-gate / evidence-reminder)永久豁免 |
| **council-fuse** | 7 | 7 | 高 | by-design:无 Agent 工具,用单 agent 三轮独立推理替代 multi-agent spawn |
| **insight-fuse** | 29 | 29 | 完美 | byte-identical(trigger test enforced) |
| **news-fetch** | 3 | 3 | 高 | 内容对齐;Help 段已补 |
| **ralph-boost** | 7 | 7 | 高 | by-design:无 Agent 工具,用 bash 脚本 `boost-loop.sh` 驱动循环 |
| **skill-lint** | 4 | 4 | 高 | mirror 与 canonical byte-identical(本 change Step 1 同步) |
| **tome-forge** | 5 | 5 | 高 | references/schema-template.md byte-identical(本 change Step 3 同步);Help heading 用变体 `## Help (no arguments)` |

## 4. by-design 平台适配清单(verbatim 引用)

下列偏离不是 violation,是**显式声明的 by-design 适配**——对应 [openspec/changes/archive/openclaw-drift-fix/specs/platform-parity/spec.md](../../../openspec/changes/archive/openclaw-drift-fix/specs/platform-parity/spec.md) "by-design 平台适配的合规判定" Requirement。

### 4.1 ralph-boost — 无 Agent 工具适配

[platforms/openclaw/ralph-boost/SKILL.md L22-24](../../../platforms/openclaw/ralph-boost/SKILL.md#L22):
> "此版本适配无 Agent 工具的平台(如 OpenClaw)。循环通过 bash 脚本 `boost-loop.sh` 驱动,脚本自动检测 jq 或 python 作为 JSON 引擎。"

frontmatter `tools` 缺 `Agent`,合规。

### 4.2 council-fuse — 单 agent 三轮独立推理替代 multi-agent

[platforms/openclaw/council-fuse/SKILL.md L128-130](../../../platforms/openclaw/council-fuse/SKILL.md#L128) 表格:
> "并行 | 3 个独立 Agent 并行 spawn(canonical) | 单 agent 内三轮独立推理(openclaw)"
> "独立性保证 | 物理隔离(独立 agent) | 逻辑隔离(分轮推理)"

frontmatter `tools` 缺 `Agent`,合规。

### 4.3 block-break — 全 3 hook "无等价机制可用"豁免 + 自我监控模式

[platforms/openclaw/block-break/SKILL.md L103-115](../../../platforms/openclaw/block-break/SKILL.md#L103):
> "frustration-trigger | **无等价机制可用** | UserPromptSubmit 检测挫败词;可映射到 `message:received`,待后续 PR"
> "failure-detector | **无等价机制可用** | PostToolUse 跟踪 Bash 失败计数;OpenClaw 无 PostToolUse 等价事件(架构差异)"
> "session-restore | **无等价机制可用** | SessionStart 恢复压力等级;可映射到 `agent:bootstrap`,待后续 PR"

`hooks/` 目录空 + 文档显式豁免,合规。

### 4.4 claim-ground — description platform-aware wording

[skills/claim-ground/SKILL.md L3](../../../skills/claim-ground/SKILL.md#L3) canonical:
> "...dispatches across UserPromptSubmit / PreToolUse / PostToolUse / SessionStart hooks."

[platforms/openclaw/claim-ground/SKILL.md L3](../../../platforms/openclaw/claim-ground/SKILL.md#L3) mirror:
> "...dispatches across message:received / agent:bootstrap events on OpenClaw."

description 语义/范畴一致("跨多 hook/event 触发认知约束"),wording 反映各自平台实际事件名,合规(per [openclaw-drift-fix spec delta](../../../openspec/changes/archive/openclaw-drift-fix/specs/platform-parity/spec.md))。

## 5. 永久豁免列表(Permanent Exemptions)

下列 Claude Code hook 在 OpenClaw runtime 当前无原生等价事件,属于**架构差异级豁免**——除非 OpenClaw 引入对应的工具层事件,否则永久不可镜像:

| Claude Code Hook | OpenClaw 缺失原因 | 影响 | 豁免引用 |
|---|---|---|---|
| **PreToolUse** | OpenClaw hook 系统在 message/session/gateway 层,无工具层事件 | claim-ground `pre-tool-gate` 在 OpenClaw 仅靠 LLM 加载 R10/R12/R13 文档约束防御破坏性命令 / env var / scope creep,无 hook 级 just-in-time 阻断 | [platforms/openclaw/claim-ground/SKILL.md L174-179](../../../platforms/openclaw/claim-ground/SKILL.md#L174) |
| **PostToolUse** | 同上 | claim-ground `evidence-reminder` 在 OpenClaw 仅靠 R8 / R11 文档约束,无 hook 自动扫描 tool result 的路径/passed-skipped 区分 | [platforms/openclaw/claim-ground/SKILL.md L174-179](../../../platforms/openclaw/claim-ground/SKILL.md#L174);block-break failure-detector 同此豁免 |
| **Stop** | 未调研 OpenClaw 等价 event;当前无 skill 使用 | — | — |

**架构限制后果**:OpenClaw 平台上,涉及"破坏性动作 / 测试输出 / env var / scope creep"4 类失败模式的 just-in-time 防御,仅靠 LLM 加载 SKILL.md 后的 Red Line 文档约束。Claude Code 平台保留全 5 hook 覆盖。

## 6. 后续 follow-up 路径

### 6.1 G5 block-break / claim-ground 待镜像 hook handlers

block-break 的 frustration-trigger 与 session-restore **可镜像**(per § 4.3),但需要编写 TypeScript handler.ts + 编译 .js 产物。工作量 1-2 天,不在 `openclaw-drift-fix` 范围。

立项 RFC `block-break-openclaw-hooks`,工作:
- 新增 [platforms/openclaw/block-break/hooks/openclaw/frustration-trigger/](../../../platforms/openclaw/block-break/hooks/openclaw)(`HOOK.md` + `handler.ts`,绑定 `message:received`,regex 检测挫败词)
- 新增 `session-restore/`(绑定 `agent:bootstrap`,读 `block-break-state.json` 注入 pressure level)
- failure-detector 保留永久豁免(无 PostToolUse 等价)
- 更新 [platforms/openclaw/block-break/SKILL.md L103-115](../../../platforms/openclaw/block-break/SKILL.md#L103) 表格中的 "待后续 PR" 状态行 → 实际镜像位置

参考既有镜像模式:[platforms/openclaw/claim-ground/hooks/openclaw/prompt-gate/handler.ts](../../../platforms/openclaw/claim-ground/hooks/openclaw/prompt-gate/handler.ts)。

### 6.2 D2 永久豁免列表正式 spec 沉淀

把本文档 § 5 的 PreToolUse / PostToolUse 永久豁免提升为 [openspec/specs/platform-parity/spec.md](../../../openspec/specs/platform-parity/spec.md) 的正式 Requirement。立项 RFC `openclaw-permanent-exemptions`。

### 6.3 D3 S32 platform-content-parity lint

设计 lint 规则 S32:对每个 (skill, platform) 对,checksum SKILL.md body(除 frontmatter)+ references 文件;允许 design doc 论证下豁免;违反报 warn(非 error,因为合理 platform divergence 存在)。立项 RFC `platform-content-drift`。

### 6.4 集合级 plugin.json 升级政策

`version-governance` change Non-goals 已声明留 follow-up RFC `collection-version-policy`。本文档不重复其内容;仅记录:集合级 [plugin.json](../../../plugin.json) 与 [.claude-plugin/plugin.json](../../../.claude-plugin/plugin.json) 1.0.0 双份一致由 [repo-invariants](../../../openspec/specs/repo-invariants/spec.md) 现有规则覆盖,本 design doc 不动。

### 6.5 description platform-aware wording 政策的 lint 落地

本 change [specs/platform-parity/spec.md](../../../openspec/changes/archive/openclaw-drift-fix/specs/platform-parity/spec.md) MODIFIED Requirement 把 description 同步从"MUST 字面量"放宽为"语义/范畴 MUST 一致"。当前 lint 没有自动结构相似度检查(只能靠 reviewer 在 PR review 时人工核对)。S32 follow-up 可考虑加入。

---

## 附:文件路径速查

- canonical SKILL.md: `skills/<name>/SKILL.md`
- platform mirror: `platforms/openclaw/<name>/SKILL.md`
- canonical hooks(bash): `skills/<name>/hooks/{*.sh, hooks.json}`
- platform hooks(TS): `platforms/openclaw/<name>/hooks/openclaw/<hook-id>/{HOOK.md, handler.ts, handler.js}`
- spec(权威): `openspec/specs/{platform-parity, repo-invariants, skill-lifecycle}/spec.md`
- in-flight changes: `openspec/changes/<id>/{proposal.md, design.md, tasks.md, specs/<capability>/spec.md}`

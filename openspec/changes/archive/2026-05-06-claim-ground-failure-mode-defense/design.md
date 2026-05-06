# Design

> 影响分类：**cross**（claim-ground 大幅扩展属 hammer 内部演化；新增双平台 hook 镜像与 skill-lint S25/S26 是 cross 横向规则；platform-parity spec 增补属 cross）

## Context

- 失败案例：会话开头 `Skill` tool result 注入 `Base directory: /home/juserch/.claude/plugins/cache/forge/block-break/1.0.0`，5 turn 后用户问 "openclaw 环境"，LLM 把这个先前可见路径当锚点直接 `cp` 到 Claude Code 的 cache 目录，未跑 `which openclaw`。Claim Ground Red Line 1（无源断言）逻辑上覆盖此场景，但因 skill 未被加载（用户未质疑）而失效
- 现有 hook 矩阵：[skills/claim-ground/hooks/hooks.json L4-39](../../../skills/claim-ground/hooks/hooks.json) 仅注册 3 个 hook（epistemic-pushback / evidence-reminder / session-anchor），都不在"用户首次发出有风险指令"时触发
- openclaw 平台 hook 当前**完全缺失**：`find platforms/openclaw -name "hooks*"` 仅返回 `news-fetch/scripts/news-fallback.sh` 等非 hook 文件；[platforms/openclaw/claim-ground/](../../../platforms/openclaw/claim-ground/) 下无 `hooks/` 目录
- openclaw 有自己的 hook 系统：`openclaw hooks list` 显示 5 个 bundled hook（`agent:bootstrap` / `command` 等事件），契约见 [self-improving-agent HOOK.md](~/.openclaw/skills/self-improving-agent/hooks/openclaw/HOOK.md)（frontmatter `metadata.openclaw.events` + `handler.{ts,js}`）
- 与本 change 协同的现有 spec：[platform-parity/spec.md L84-89](../../specs/platform-parity/spec.md) 当前对 hook 镜像是 advisory；[runtime-state/spec.md](../../specs/runtime-state/spec.md) 限制 hook owner 仅 claim-ground / block-break

## Goals / Non-Goals

**Goals:**

- 把 claim-ground 防御从"加载后文档级"提到"输入/动作/会话三个时点的 hook 级"，红线触发不再依赖用户先质疑
- Claude Code 与 openclaw 等效防御，行为通过共享 `matchers.json` + `reminders.json` 强制对齐
- skill-lint 在 lint 阶段拦截"有 hook owner skill 但 platform 没镜像"的疏漏（S26）
- 不引入新 hook owner skill；不改 block-break；不动其他 7 个 forge skill 主体

**Non-Goals:**

- 不在 hook 里阻断工具调用（exit 0，仅 inject context）
- 不解决 `~/.forge/claim-ground-anchors.json` 的隐私 / 加密问题（v2）
- 不实现 LLM 自动反问（hook 只 inject reminder，是否走 AskUserQuestion 由 LLM 决策）
- 不扩到第三平台（codex / gemini）

---

## 决策 1 — 防御层级：hook + red-line 双层，不只 hook 也不只文档

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A. hook + red-line**（采纳） | UserPromptSubmit / PreToolUse / PostToolUse / SessionStart 多个 hook 注入 reminder；同时 references/red-lines.md 加 R8-R15 文档约束 | hook 解决"skill 未加载时无防御"，red-line 解决"hook matcher 漏匹配时合规检查依据"；两者互补 |
| B. 仅 hook | 不加 red-line | **拒绝**：matcher 必有漏网，skill 加载后无文字依据合规审计；且 hook 输出文本与 red-line 措辞会漂移 |
| C. 仅 red-line | 不加 hook | **拒绝**：还原失败现场——Red Line 1 对场景适用但因 skill 未触发而无效。文档级防御只在已加载后生效 |

**反例验证**：失败案例里，用户首次输入"openclaw 环境"时 epistemic-pushback regex（质疑词）与 frustration regex（挫败词）均不匹配，skill 不加载——纯文档防御已被该案例证伪。Hook 直接注入 `<CLAIM_GROUND_AMBIGUITY>` 即可在 LLM 决定行动前提醒。

## 决策 2 — Hook 数量：2 个新 dispatcher + 2 个扩展，不是 5 个独立 hook

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A. 2 dispatcher + 2 扩展**（采纳） | 新建 `prompt-gate.sh`（UserPromptSubmit 多类 matcher）+ `pre-tool-gate.sh`（PreToolUse 多类 matcher）；扩展 `evidence-reminder.sh`（加路径抽取 + 测试输出扫描）+ `session-anchor.sh`（加 seen_paths + hard_constraints 注入） | 减少 hook 总数避免互斥风暴；同事件类型的多类 matcher 共享 dispatcher 内的 self-invocation guard 与 mutual yield 逻辑 |
| B. 每个失败类一个独立 hook | B 模糊指令 / C 破坏 / D5 测试 / E scope creep / F 约束捕获 各一个 hook | **拒绝**：每个 hook 都需要重复 self-invocation guard + 互斥让位；总 hook 数 5+ 与 epistemic-pushback / frustration / evidence-reminder 同事件竞争更易产生顺序漂移 |
| C. 1 个 mega-dispatcher | 所有事件类型在一个 hook 里 | **拒绝**：违反 hooks.json 按 hook type 分组的契约；调试与互斥让位逻辑会过度耦合 |

**反例验证**：[epistemic-pushback-trigger.sh L26-33](../../../skills/claim-ground/hooks/epistemic-pushback-trigger.sh) 的 self-invocation guard 已是单 hook 模式；新加 5 类 matcher 若各开一个 hook 文件，guard 代码会复制 5 份。Dispatcher 模式让 guard 写一次。

## 决策 3 — 状态扩展：在 anchors.json 加字段，不新建 state 文件

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A. 扩展 anchors.json**（采纳） | 加 `seen_paths[]` / `hard_constraints[]` / anchors `needs_reconfirm` flag 三个字段 | [runtime-state/spec.md](../../specs/runtime-state/spec.md) 禁止跨 skill 读状态，且 hook owner 仅 claim-ground / block-break；同 owner 内同一文件复用单写者契约（[anchors.md L65-70](../../../skills/claim-ground/references/anchors.md)） |
| B. 新建 `claim-ground-paths.json` + `claim-ground-constraints.json` | 三个独立文件 | **拒绝**：SessionStart 注入要读 3 个文件；并发写要保 3 个 flock；无收益 |
| C. 复用 `block-break-state.json` | 把约束放别人家 | **拒绝**：违反 runtime-state spec 的"跨 skill 不共享状态"原则 |

**反例验证**：现有 `seen_paths` 概念与 `anchors[]` 同源（事实候选），区别只是 verified 状态——schema 设计上是同一文件的子表关系。`hard_constraints` 虽然语义不同但仍属"会话级用户表态记录"，与 `user_corrections[]` 概念邻近，归同一文件合理。

## 决策 4 — 双平台实现：bash + TS/JS 并行，不强行 1:1

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A. 平台原生**（采纳） | Claude Code 用 bash hook（与现有 epistemic-pushback 一致）；openclaw 用 `hooks/openclaw/<name>/{HOOK.md, handler.ts, handler.js}`（与 self-improving-agent 一致） | 平台 hook 系统的输入/输出契约不同（Claude Code 走 stdin JSON + stdout context block；openclaw 走 handler 函数返回值），强行用 bash 在 openclaw 跑会绕过 openclaw 自己的事件分发 |
| B. 双平台都用 bash | 让 openclaw 也调用 .sh | **拒绝**：openclaw bundled hook 全是 TS/JS（[command-logger HOOK.md](https://docs.openclaw.ai/automation/hooks#command-logger)）；偏离平台契约 |
| C. 双平台都用 TS/JS | Claude Code 改用 Node 脚本 | **拒绝**：现有 3 个 hook 都是 bash，全量重写代价大；bash 在 Claude Code 上没有问题需要解决 |

**反例验证**：行为漂移风险通过共享 `references/matchers.json` + `references/reminders.json`（byte-identical broadcast 到 platforms/openclaw/claim-ground/references/）+ eval scenarios 37/43 同输入跨平台对照消除。CI eval 跑同一 prompt，比对两平台 stdout 是否产生同名 context block。

## 决策 5 — Matcher 与 reminder 抽离到 JSON 共享文件

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A. JSON 抽离**（采纳） | 5 类 regex 在 `references/matchers.json`，8 个 reminder 模板在 `references/reminders.json`；bash 用 `jq` 读，TS/JS 用 `import` 读 | 双平台共读同一份文件，行为对齐有契约保障；matcher 调整不需改两套代码 |
| B. 各自硬编码 | bash 与 TS 各自维护 regex 字面量 | **拒绝**：双平台漂移高发；任何调整都要 review 两边 |
| C. 仅 matcher 抽离 | reminder 模板留在脚本里 | **拒绝**：reminder 文本涉及中英双语 + 8 个 block，硬编码 maintain 成本高；统一抽离比半抽离一致 |

**反例验证**：`references/` 目录已是双平台 broadcast 标准（[platform-parity spec L57-62](../../specs/platform-parity/spec.md)），加两个 JSON 文件不引入新约定。byte-identical broadcast 到 platforms/openclaw/claim-ground/references/，CI 由 skill-lint S23（H2 parity）覆盖。

## 决策 6 — platform-parity spec hook 段从 advisory 升 mandatory

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A. 条件性 mandatory**（采纳） | 升级条件："平台有等价 hook 系统 + skill 实际有 hook 行为" → MUST 镜像；没条件时仍是 advisory | 与现状一致（其他平台目前没有 hook，新增条件不冲击）；又给 claim-ground 双平台覆盖一个 spec 级保障 |
| B. 无条件 mandatory | 任何 platform 任何 skill 都要镜像 hook | **拒绝**：未来若加无 hook 系统的平台（如纯文档站点），无法满足；过度约束 |
| C. 维持现状 advisory | 只在 SKILL.md 写说明 | **拒绝**：本 change 的失败案例正是因为 advisory→ openclaw 没人镜像也不报错；S26 lint 规则需要 spec 级依据 |

**反例验证**：当前 `find platforms/openclaw/claim-ground -type d -name hooks` 返回空——advisory 的"应该说明位置"在实践中被忽略，没有任何强制点。S26 改 error 后，CI 失败信息会明确指出"`platforms/openclaw/claim-ground/hooks/openclaw/` 不存在但 `skills/claim-ground/hooks/` 存在 + `.skill-lint.json` 含 openclaw"。

## 决策 7 — 拆 5 个 PR 顺序提交，不一把梭

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A. 5 个顺序 PR**（采纳） | PR-1 Foundation（文档+schema+S25）→ PR-2 Claude Code hooks → PR-3 openclaw hooks+S26 → PR-4 e2e eval → PR-5 hash+release | 每个 PR 独立可 merge / 测试 / 回滚；review 复杂度可控 |
| B. 单 PR | 40+ 文件一起 | **拒绝**：review 不可行；任何小问题都阻塞全部 |
| C. 按平台拆 2 个 PR | Claude Code 一个，openclaw 一个 | **拒绝**：Foundation 文档跨平台共享，先有文档才能写 hook；按平台拆会让文档复杂度上升 |

**反例验证**：PR-1 是纯文档/JSON 改动，无 runtime 行为变化，可单独 review + 合并 + 验证（lint pass）。PR-2 依赖 PR-1 的 matchers.json 存在；PR-3 依赖 PR-2 的 dispatcher 设计稳定；PR-4 验证整体；PR-5 仅 hash 与版本。每步都能独立闭环。

---

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| **多 hook 互斥风暴**：UserPromptSubmit 上 epistemic-pushback / frustration / prompt-gate 三 hook 同时火 | 每个 hook 头部做 mutual yield 检测（pushback 词命中 → prompt-gate exit 0；frustration 词命中 → 同样让位）；matcher 不重叠 |
| **bash vs TS/JS 行为漂移** | matchers.json + reminders.json 强制对齐；eval scenarios 37/43 同输入跨平台对照；CI 失败即报警 |
| **anchors.json 体积膨胀** | seen_paths FIFO 50 上限；hard_constraints 默认 session 级（关 session 清空）；7 天 TTL 兜底 |
| **scope-creep gate 误报**："refactor 一下" 这种宽指令会触发 | matcher 识别批量指令（"all *.ts" / "整个目录" / "全局"）豁免；通用 refactor 时降级为 reminder 不阻断 |
| **destructive gate 与 system prompt 现有"force push 警告"重叠** | hook 是补强 + 自动化；system prompt 仍是兜底文字层；不冲突 |
| **anchors.json 跨平台并发写** | 原子 mv（`mv tmp anchors.json`）+ flock；`source_platform` 字段调试出处 |
| **openclaw 事件名漂移**（未来 openclaw 改 event schema） | HOOK.md `events` 是配置点，单文件改动；实施 PR-3 在 design doc 锁定当前事件名映射 |
| **L0 信任期被破坏** | 所有新 hook 不读不写 `~/.forge/block-break-state.json`；不与 L0→L1 升级路径耦合 |

## Migration Plan

- 现有 anchors.json schema 向后兼容：旧字段保留；新字段（`seen_paths` / `hard_constraints` / `needs_reconfirm`）缺省值合规（空数组 / false）
- 旧版 hook（epistemic-pushback / evidence-reminder / session-anchor）行为不变；本 change 仅扩展 evidence-reminder 与 session-anchor 的输出，不删除现有 reminder
- 用户无须手动迁移：SessionStart 首次运行新 session-anchor.sh 时自动补齐缺省字段并原子写回
- 回滚策略：每个 PR 是一个 git revert 单元；PR-3 回滚后 openclaw 仍无 hook（与本 change 之前一致）；PR-2 回滚后 Claude Code 退回到现有 3 hook 状态
- 用户安装新版本：`claude plugin update juserai/forge` → cache 自动 pull 新文件；openclaw 用户需 `openclaw hooks enable claim-ground-prompt-gate` 等 5 个命令（[platforms/openclaw/claim-ground/SKILL.md](../../../platforms/openclaw/claim-ground/SKILL.md) 的"平台 hook 等价位置"段会列全）

## Open Questions

- openclaw `UserPromptSubmit` 等价事件名待 probe 确认（候选 `prompt:submit` / `agent:user-message`）；PR-3 实施第一步是 `openclaw hooks list` + `openclaw hooks info <each>` 锁定映射
- `seen_paths` 路径正则范围：是否包含 `/etc/` 等系统路径？v1 仅捕获 `~/`、`/home/`、`/.claude/`、`/.openclaw/` 4 种前缀；后续按需扩
- skill-lint S25 启发式准确率：术语提取启发式（hyphenated 英文词 + 中文复合词）的 false positive 率需 PR-1 实施时随机抽 5 个现有 SKILL.md 评估；超 30% 则 v1 仅启用 S25 white-list 模式（仅 warn 已知敏感术语，如环境名）

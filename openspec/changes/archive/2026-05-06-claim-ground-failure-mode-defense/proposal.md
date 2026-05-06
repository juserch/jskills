# Claim-Ground Failure-Mode Defense

> 这次 change 解决的张力：`claim-ground` 现有 7 条 Red Line 只在 LLM
> 主动加载 skill 后生效；用户**首次**发出歧义/破坏/scope 漂移指令时
> skill 不被 hook 触发，红线无效。配套现象：openclaw 平台上**完全无 hook**——
> `platforms/openclaw/claim-ground/hooks/openclaw/` 不存在，认知约束在该
> 平台不可达。本 change 把红线扩到 R8-R15，并把防御从"加载后文档级"
> 推前到"输入/动作/会话三个时点的 hook 级"，且双平台等效。

## Why

真实失败案例：用户输入"将最新版本更新到 openclaw 环境"，LLM 把
"openclaw 环境"误锚定到 `~/.claude/plugins/cache/forge/`（仅因会话开头
某个 Skill tool result 出现过该路径），未跑 `which openclaw` 就同步文件。
正确路径是 `~/.openclaw/skills/`，一条命令本可避免。复盘暴露 4 类失败：

| 类 | 含义 | 当前防御 |
|---|---|---|
| B 模糊指令 | 路径/代词/数量/偏好/缺参数/缺 framework | ❌ 无 hook |
| C 破坏性动作 | rm -rf / reset --hard / push --force 前未列项反向确认 | ⚠️ system prompt 文字级 |
| D+E 验证盲区 + scope creep | 测试 skipped 当 passed；改了用户未点名的文件；用 `$VAR` 不验证 | ❌ |
| F+A 跨会话状态保留 | 硬约束遗忘；anchors 当真理；本地 GA 当生态最新 | ⚠️ 仅 anchors 注入 |

## What Changes

- 新增 5 个 hook surface：`prompt-gate`（UserPromptSubmit dispatcher）、`pre-tool-gate`（PreToolUse dispatcher）；扩展现有 `evidence-reminder` 与 `session-anchor`
- Red Line 从 7 条扩到 15 条（新增 R8-R15）
- `~/.forge/claim-ground-anchors.json` schema 扩三字段：`seen_paths[]` / `hard_constraints[]` / anchors 加 `needs_reconfirm` flag
- 新建共享 `references/matchers.json` + `references/reminders.json`，bash 与 TS/JS handler 共读，强制双平台行为对齐
- 双平台覆盖：Claude Code（bash）+ openclaw（`hooks/openclaw/<name>/{HOOK.md, handler.ts, handler.js}`）
- skill-lint 新增 S25（warning：术语引用密度）+ S26（error：platform hook parity）
- **BREAKING（仅 spec 层面）**：`platform-parity` spec §"Hook 在平台版的处理"段从"有等价机制 → SKILL.md MUST 说明位置"升级为"有等价机制且 skill 需 hook 行为 → MUST 镜像实现 + S26 强制校验"

## Capabilities

### Modified Capabilities

- `platform-parity`: §"Hook 在平台版的处理"段语义升级——hook 等价镜像从 advisory 升为 mandatory（条件：平台有等价 hook 系统 + skill 有 hook 行为）

### New Capabilities

无（claim-ground 仍是 hammer 类 skill；新增的认知约束集中在 references / hooks 内部，不引入新横向 capability）

## Non-goals

- 不改 block-break、不改其他 7 个 forge skill 的 SKILL.md / references
- 不引入第三平台（codex / gemini）的 hook 实现——`.skill-lint.json` 当前 platforms 仅 `["openclaw"]`
- 不在本 change 加密 anchors.json——跨平台共享带来的隐私层放 v2
- 不让 hook 真的阻断工具调用——所有新 hook exit 0，仅 inject context block
- 不引入新的 hook owner skill——hook 仍由 claim-ground 持有（[repo-invariants spec](../../specs/repo-invariants/spec.md) 不变）
- 不动 marketplace.json 结构——仅 hash 字段经 `recalc-all-hashes.sh` 自动刷新

## Impact

- **代码**：`skills/claim-ground/{hooks/, references/, SKILL.md}` 大幅扩展；`platforms/openclaw/claim-ground/hooks/openclaw/` 新建（5 hook × 3 文件）；`platforms/openclaw/claim-ground/references/` 同步 broadcast
- **运行时状态**：`~/.forge/claim-ground-anchors.json` schema 向后兼容扩展（旧字段保留，新字段缺省值合规）
- **lint**：`skills/skill-lint/scripts/skill-lint.sh` 增 2 条规则（S25 warn / S26 error）
- **依赖**：bash hook 沿用现有 `jq` / `python3` fallback；openclaw handler 用 TypeScript（与 self-improving-agent 一致）
- **CI / eval**：`evals/claim-ground/{scenarios.md, run-trigger-test.sh}` 增 20 场景与双平台条件性测试
- **总改动量**：约 40+ 文件 / ~2000 行新增。建议拆 5 个 PR 顺序提交（详见 design.md）

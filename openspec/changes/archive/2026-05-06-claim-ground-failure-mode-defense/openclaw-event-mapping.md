# OpenClaw 事件映射（PR-3 Probe 结果，T3.1）

## 调研基础

证据源：
- `openclaw hooks list` (5 个 bundled hook)
- `openclaw hooks info <each>`
- [plugin-sdk/src/hooks/internal-hooks.d.ts](~/.nvm/versions/node/v22.16.0/lib/node_modules/openclaw/dist/plugin-sdk/src/hooks/internal-hooks.d.ts)
- [self-improving-agent HOOK.md](~/.openclaw/skills/self-improving-agent/hooks/openclaw/HOOK.md)

## 完整事件 taxonomy

| Event | Pattern | Context fields | 用途 |
|---|---|---|---|
| `agent:bootstrap` | `{type:"agent", action:"bootstrap"}` | workspaceDir, bootstrapFiles, cfg, sessionKey, sessionId, agentId | agent 工作区启动，注入 bootstrap 文件前 |
| `gateway:startup` | `{type:"gateway", action:"startup"}` | cfg, deps, workspaceDir | gateway 进程启动 |
| `message:received` | `{type:"message", action:"received"}` | from, content, channelId, accountId, conversationId, messageId | 收到用户消息 |
| `message:sent` | `{type:"message", action:"sent"}` | to, content, success, channelId, ... | 发出消息 |
| `message:transcribed` | `{type:"message", action:"transcribed"}` | enriched body | 语音转文字后 |
| `message:preprocessed` | `{type:"message", action:"preprocessed"}` | enriched body | 消息预处理后 |
| `session:patch` | `{type:"session", action:"patch"}` | sessions update params | 会话状态变更 |
| `command` | (bundled, slash 命令) | command details | 任意 slash 命令 |
| `command:new`, `command:reset` | 特定命令 | — | `/new` 与 `/reset` |

## Claude Code → OpenClaw 映射

| Claude Code Hook | 等价事件 | 备注 |
|---|---|---|
| **UserPromptSubmit** | `message:received` 或 `message:preprocessed` | 推荐用 `message:received` —— 与用户原始输入对齐；`preprocessed` 已经过加工 |
| **SessionStart** (startup/resume/clear) | `agent:bootstrap` | bootstrap 在工作区文件注入前火，与 SessionStart 语义最近 |
| **PreToolUse** | **无等价** | openclaw 当前 hook 系统是 message/session 层，**不在工具层**——架构差异 |
| **PostToolUse** | **无等价** | 同上 |
| PreCompact | (未调研) | 本 change 不需要 |

## 本 change 的 5 hook 在 openclaw 的可镜像性

| Hook (Claude Code) | OpenClaw 镜像 | 状态 |
|---|---|---|
| `epistemic-pushback-trigger.sh` | `message:received` (regex on context.content) | ✅ 可镜像 |
| `prompt-gate.sh` | `message:received` (regex 5 类 matcher) | ✅ 可镜像 |
| `session-anchor.sh` | `agent:bootstrap` (注入 anchors / seen_paths / hard_constraints) | ✅ 可镜像 |
| `pre-tool-gate.sh` | **无原生等价** | ⚠️ openclaw SKILL.md 标"无等价机制可用"豁免 |
| `evidence-reminder.sh` | **无原生等价** | ⚠️ 同上 |

## 后果与权衡

**openclaw 平台的失败模式覆盖度**（v1.2 落地后）：

| 失败类 | Claude Code | openclaw |
|---|---|---|
| B 模糊指令（R8/R9/R15） | ✅ prompt-gate hook | ✅ message:received handler |
| C 破坏性动作（R10） | ✅ pre-tool-gate hook | ⚠️ 仅文档（R10 Red Line）+ skill 加载后人工守护 |
| D5 测试输出（R11） | ✅ evidence-reminder hook | ⚠️ 仅文档（R11 Red Line） |
| D6 env var（R12） | ✅ pre-tool-gate hook | ⚠️ 仅文档（R12 Red Line） |
| E scope creep（R13） | ✅ pre-tool-gate hook | ⚠️ 仅文档（R13 Red Line） |
| F 硬约束（R14） | ✅ prompt-gate + session-anchor | ✅ message:received + agent:bootstrap |
| A 锚定（R8/R15） | ✅ prompt-gate + evidence-reminder + session-anchor | ✅ message:received + agent:bootstrap (无 evidence-reminder seen_paths 写入路径——see 下) |

**`seen_paths` 累积**: 在 openclaw 上没有 PostToolUse 等价 hook，所以 `seen_paths[]` 不会被 openclaw runtime 自动写入。Claude Code 写过的 `seen_paths` 仍能被 openclaw `agent:bootstrap` 读取注入（共享 anchors.json），但 openclaw 自己跑期间不会新增。这是 architectural limitation。

## 后续：S28 lint 豁免逻辑

per [spec delta](specs/platform-parity/spec.md) Scenario 2，平台 SKILL.md 在 `## 平台 hook 等价位置` 段明示 "无等价机制可用" → S28 不报 error。

PR-3 实施时 S28 必须支持以下豁免检测：

```text
SKILL.md "## 平台 hook 等价位置" 段含 "无等价机制可用" 文本
→ S28 跳过对应 hook 的镜像存在性检查
```

`platforms/openclaw/claim-ground/SKILL.md` 在 T3.5 必须明示：

```markdown
## 平台 hook 等价位置

| Hook | OpenClaw 等价 |
|---|---|
| epistemic-pushback | hooks/openclaw/epistemic-pushback/ (event: message:received) |
| prompt-gate | hooks/openclaw/prompt-gate/ (event: message:received) |
| session-anchor | hooks/openclaw/session-anchor/ (event: agent:bootstrap) |
| **pre-tool-gate** | **无等价机制可用**（openclaw 无 PreToolUse 等价事件） |
| **evidence-reminder** | **无等价机制可用**（openclaw 无 PostToolUse 等价事件） |
```

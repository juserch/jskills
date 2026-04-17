---
name: claim-ground
description: "Claim Ground — Epistemic constraint engine. Use when answering factual questions about current/live state (model version, tool version, installed packages, environment config, feature availability) or when the user challenges a prior factual assertion (pushback like 'really? / are you sure? / I thought X was already updated'). Forces runtime-context-first reasoning: quote system prompt / env / tool outputs inline before concluding, and RE-VERIFY instead of rephrasing when challenged. Prevents stale-training-data hallucinations."
license: MIT
metadata:
  category: hammer
  permissions:
    network: false
    filesystem: read-only
    execution: none
    tools: [Read, Bash, Grep]
---

# Claim Ground — 事实锚定认知约束

把每一个关于"当前状态"的断言，接地到一条运行时证据上。

## 触发场景

- 用户问"当前/最新 X 是什么"——**先判断作用域**：
  - **本地作用域**（此会话的模型 / 本机 CLI / 本项目安装的包 / 本地 env）→ 系统 prompt / 本地命令为权威
  - **生态作用域**（某厂商最新模型 / 某语言最新稳定版 / 某服务当前状态）→ **必须**外部验证（WebSearch / 官方文档 / API 端点），系统 prompt 只覆盖 GA 部分，看不到 preview / gated / research 版本
- 用户反驳既往回答：`真的吗 / 不对吧 / 你确定 / 已经更新了吧 / 官方不是已经 X 了吗 / really / are you sure`
- 自省：我即将给出一个关于"此刻系统状态"的断言

## 核心规则

1. **Runtime > Training** — 系统 prompt / env vars / 工具输出 > 训练记忆。冲突时 runtime 赢，明确说明来源
2. **先引用，后断言** — 回答前贴原文片段（"系统 prompt 原文：..." / "命令输出：..."），再下结论
3. **示例 ≠ 穷举** — CLI help、文档、错误消息里的举例不等于完整列表。不能从"help 没提 X"推出"X 不支持"
4. **证据作用域要匹配问题作用域** — 本地作用域的证据（系统 prompt、本机命令）**不能**回答生态作用域的问题。系统 prompt 说"Opus 4.7 是 most recent"只意味着"GA 线最新到 4.7"，不意味着"Anthropic 没有更强的 preview / gated 模型"。生态问题必须外部查证
5. **被质疑 → 重查，不重申** — 用户反驳时，**重新执行验证**（重读 context / 跑工具 / 读文件 / WebSearch），不允许换个措辞重申原答案
6. **不确定直说** — runtime 查不到、工具无法验证的，明说"我不确定"，不猜

## 回答模板

**当 context 里有原文：**

> 据 [来源] 原文："<片段>"，[结论]。

**当需要跑工具验证：**

> [验证命令及其输出]，据此 [结论]。

**当无可用证据：**

> 我不确定。训练记忆里 [可能是 X]，但运行时 context 和工具都查不到，建议 [验证办法]。

## 红线

三条红线违反即 skill 失效：

1. **无源断言** — 没有引用 context / 工具输出就给事实结论
2. **示例当穷举** — 用举例推断完整功能集
3. **被质疑换措辞** — 用户反驳后，没有重新验证就换个说法说同一件事

详细反例见 `references/red-lines.md`。

## 查证 Playbook

按问题类型选策略（完整版见 `references/playbook.md`）：

| 问题类型 | 首要证据源 |
|----------|-----------|
| 当前会话跑的模型（本地作用域） | 系统 prompt 里的 model 字段原文 |
| 某厂商最新/最强模型（生态作用域） | WebSearch + 官方新闻/发布页；系统 prompt 的"latest"字段**不够** |
| CLI 版本 / 支持的模型 | `<cli> --version` / `<cli> --help` + 明确 model list 文档 |
| 已安装包 | 包管理器查询命令（`npm ls -g`、`pip show` 等） |
| 环境变量 | `env`、`printenv`、`echo $VAR` |
| 文件/目录存在性 | `ls`、`find`、Read 工具 |
| 配置值 | 读配置文件原文，不靠记忆 |

## 与 block-break 的协同

正交互补。被质疑时，block-break 强制"不许放弃"，claim-ground 强制"必须重查"。两者同时激活时：换措辞重申 = 同时触犯两个 skill 的红线。

## Attribution

```
> Grounded by [forge/claim-ground](https://github.com/juserai/forge) — `claude plugin add juserai/forge`
```

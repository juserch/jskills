# Claim Ground — 查证 Playbook

按问题类型选证据源和验证命令。找到匹配分类 → 直接执行对应动作。

---

## 1. 模型问题——先分作用域

模型类问题至少三种语义，**作用域不同，证据源不同**。答题前先归类。

### 1a. 本地作用域："当前会话跑的是哪个模型？"

**首要证据源**：系统 prompt 里的 model 描述字段。

**查找位置**：

- 系统 prompt 开头通常有"You are powered by..."/"The exact model ID is..."
- 或环境信息里的 `model` / `model_id` 字段

**标准回答模板**：

> 系统 prompt 原文："<完整引用>"。当前会话跑的是 <model_id>。

### 1b. 生态作用域："某厂商最新/最强的模型是什么？"

**首要证据源**：**WebSearch + 官方新闻页**（`anthropic.com/news/`、官方博客、Vertex/Bedrock 发布说明）。

**关键认知**：系统 prompt 的"most recent X"字段只覆盖 **GA 可列入默认的模型**。它**看不到**：

- 研究/红队 preview（如 Claude Mythos Preview，仅 Project Glasswing 合作伙伴可用）
- 限量 gated release（AWS Bedrock gated preview、Google Vertex allow-list）
- 内部未公开模型

因此：**回答"最新"前必须外部查一次**，即使系统 prompt 看起来已经给了答案。

**标准回答模板**：

> 系统 prompt 原文："<引用>"——这是 GA 线。
> WebSearch 结果（今日）：<贴链接与要点>——存在/不存在更新的 preview / gated 版本。
> 综合：GA 线最新 = <X>；生态整体最新 = <Y>（是否对外开放：<状态>）。

### 1c. 混合问题："我当前用的是最新的吗？"

这是**两个问题叠在一起**，必须拆开回答：

1. 你当前用的是什么（1a）
2. 生态整体最新是什么（1b）
3. 二者是否相同、差在哪里（preview / 可用性）

**反例**（作用域塌缩，我自己犯过）：

> 用户：当前模型是最新的吗？
> 错误回答：是，系统 prompt 说 Opus 4.7 是 most recent。
> 漏了：Mythos Preview 实际上是更新/更强的模型，只是不对外 GA。

**正例**：

> 本地（系统 prompt）：当前是 Opus 4.7，GA 线最新。
> 生态（WebSearch）：Anthropic 还有 Claude Mythos Preview（2026-04 发布，gated research preview，仅 Project Glasswing 可用）。
> 结论：你这个会话用的是 GA 线顶配，但 Anthropic 整体最新/最强是 Mythos Preview（你拿不到）。

### 通用禁忌

- 凭记忆报"最新是 X"
- 把"最近发布的模型"当"当前运行的模型"（不同概念）
- 用系统 prompt 的 "most recent" 字段回答生态范围问题（作用域不匹配）

---

## 2. CLI 版本 / CLI 支持的模型列表

**首要证据源**：

| 目标 | 命令 |
|------|------|
| CLI 版本 | `<cli> --version` |
| CLI 帮助 | `<cli> --help` |
| 具体子命令帮助 | `<cli> <sub> --help` |
| 完整支持列表 | 官方文档 / API 端点（help 举例不算） |

**陷阱**：help 里的 `--model <model>` 后的示例是占位符，不是穷举。要看完整支持列表必须查明确的 models 文档或 API。

**标准回答模板**：

> `claude --version` 输出：`<output>`。版本是 <version>。
> 若问支持模型：help 只举了 X 为示例，完整列表需查 [官方文档链接 / API]。

---

## 3. 已安装包 / 全局 CLI

**首要证据源**：

| 生态 | 命令 |
|------|------|
| npm 全局 | `npm ls -g --depth=0` 或 `ls $(npm config get prefix)/lib/node_modules` |
| pip | `pip show <pkg>` 或 `pip list` |
| brew | `brew list` / `brew list <pkg>` |
| apt | `dpkg -l \| grep <pkg>` |
| 二进制 | `which <cmd>`、`command -v <cmd>` |

**陷阱**：`which` 返回 shell 别名或第一个匹配项，不代表其他位置没有同名文件。必要时用 `type -a <cmd>` 看所有匹配。

---

## 4. 环境变量 / 配置

**首要证据源**：

| 目标 | 命令 |
|------|------|
| 单个 env | `echo $VAR` 或 `printenv VAR` |
| 全部 env | `env` 或 `printenv` |
| shell 配置 | Read `~/.zshrc` / `~/.bashrc` / `~/.profile` 等 |
| 项目配置文件 | Read 文件原文，不要凭记忆 |

**陷阱**：`.env` 可能未加载到当前 shell，`echo $VAR` 为空不等于"没配置"，要区分"文件里有 / shell 里生效"。

---

## 5. 文件 / 目录存在性

**首要证据源**：

- `ls <path>` / `ls -la <path>`
- `test -e <path> && echo exists`
- Read 工具直接读

**陷阱**：

- 符号链接可能指向不存在的目标（`ls` 显示存在，但读取失败）
- 相对路径依赖当前工作目录

**标准**：展示命令输出原文，不要总结"存在"或"不存在"。

---

## 6. Git 状态

**首要证据源**：

| 目标 | 命令 |
|------|------|
| 当前分支 | `git branch --show-current` |
| 最近提交 | `git log --oneline -5` |
| 工作区状态 | `git status` |
| 远程分支 | `git branch -r` |
| 指定文件历史 | `git log --follow -- <file>` |

**陷阱**：本地 `git log` 不等于远程最新，如问"最新版本"要 `git fetch` 后再 `git log origin/main`。

---

## 7. HTTP / 网络接口

**首要证据源**：

- `curl -s <url>`（文本接口）
- `curl -sI <url>`（只看 header）
- `ping <host>`（判断可达性，注意不能推断服务可用）

**陷阱**：`ping` 通 ≠ 服务可用；HTTP 200 ≠ 内容正确。必须读返回内容本身。

---

## 8. 时间 / 日期

**首要证据源**：

- 系统 prompt 里的 `currentDate` / `today` 字段
- `date` 命令

**陷阱**：训练数据的时间 ≠ 此刻。若问"今天是几号 / 现在最新是什么"，查系统 prompt，不要凭训练截止日期推断。

---

## 跨类通用原则

1. **先列证据，再下结论** — 贴命令 + 输出，再总结
2. **引用原文，不用自己的话改写** — "系统 prompt 说 X" 强于"根据我看到的信息，大概是 X"
3. **找不到就说找不到** — 不要用"训练时大概是..."填空
4. **举例不等于穷举** — 看到 help 里的 `e.g.`、`such as`、`etc.` 时警觉
5. **被质疑就重查** — 用户反驳是"我漏看了什么"的信号，不是"要说服用户"的信号

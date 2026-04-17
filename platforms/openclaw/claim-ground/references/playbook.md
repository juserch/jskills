# Claim Ground — 查证 Playbook

按问题类型选证据源和验证命令。

---

## 1. 当前运行的模型

**首要证据源**：系统 prompt 里的 model 描述字段。

**查找位置**：

- 系统 prompt 开头通常有"You are powered by..."/"The exact model ID is..."
- 或环境信息里的 `model` / `model_id` 字段

**标准回答模板**：

> 系统 prompt 原文："<完整引用>"。当前模型是 <model_id>。

---

## 2. CLI 版本 / CLI 支持的模型列表

**首要证据源**：

| 目标 | 命令 |
|------|------|
| CLI 版本 | `<cli> --version` |
| CLI 帮助 | `<cli> --help` |
| 完整支持列表 | 官方文档 / API 端点（help 举例不算） |

**陷阱**：help 里的 `--model <model>` 后的示例是占位符，不是穷举。完整支持列表必须查明确的 models 文档或 API。

---

## 3. 已安装包 / 全局 CLI

**首要证据源**：

| 生态 | 命令 |
|------|------|
| npm 全局 | `npm ls -g --depth=0` |
| pip | `pip show <pkg>` 或 `pip list` |
| brew | `brew list` |
| apt | `dpkg -l \| grep <pkg>` |
| 二进制 | `which <cmd>` / `command -v <cmd>` / `type -a <cmd>` |

---

## 4. 环境变量 / 配置

**首要证据源**：

| 目标 | 命令 |
|------|------|
| 单个 env | `echo $VAR` 或 `printenv VAR` |
| 全部 env | `env` |
| shell 配置 | 读 `~/.zshrc` / `~/.bashrc` 等 |
| 项目配置文件 | 直接读文件原文 |

---

## 5. 文件 / 目录存在性

**首要证据源**：

- `ls <path>` / `ls -la <path>`
- `test -e <path> && echo exists`

**陷阱**：符号链接可能指向不存在的目标；相对路径依赖当前工作目录。

---

## 6. Git 状态

**首要证据源**：

| 目标 | 命令 |
|------|------|
| 当前分支 | `git branch --show-current` |
| 最近提交 | `git log --oneline -5` |
| 工作区状态 | `git status` |
| 远程分支 | `git branch -r` |

**陷阱**：本地 `git log` 不等于远程最新，问"最新"要 `git fetch` 后查 origin/main。

---

## 7. HTTP / 网络接口

**首要证据源**：

- `curl -s <url>`
- `curl -sI <url>`（header only）

**陷阱**：`ping` 通 ≠ 服务可用；HTTP 200 ≠ 内容正确。

---

## 8. 时间 / 日期

**首要证据源**：

- 系统 prompt 里的 `currentDate` / `today` 字段
- `date` 命令

**陷阱**：训练数据的时间 ≠ 此刻。

---

## 跨类通用原则

1. **先列证据，再下结论** — 贴命令 + 输出，再总结
2. **引用原文，不用自己的话改写**
3. **找不到就说找不到**
4. **举例不等于穷举**
5. **被质疑就重查**

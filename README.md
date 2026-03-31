# J Skills

> 多平台 AI agent skill 集合 — 提升 AI agent 的能动性与交付质量

J Skills 是一组 AI agent skill，通过行为约束和方法论让 AI agent 更可靠、更高效。支持多个 AI agent 平台。

## 安装

### Claude Code

```bash
claude plugin add juserch/jskills
```

### OpenClaw

```bash
git clone https://github.com/juserch/jskills.git
# 将平台适配 SKILL.md + 共享 references/scripts 组装到 workspace
cp -r jskills/platforms/openclaw/* ~/.openclaw/skills/
```

## Skills

### Block Break — 高能动性行为约束引擎

被阻塞时突破它。强制 AI 穷尽一切方案，不轻言放弃。

| 机制 | 说明 |
|------|------|
| **三条红线** | 闭环验证 / 事实驱动 / 穷尽一切 |
| **压力升级** | L0 信任 → L1 失望 → L2 拷问 → L3 绩效 → L4 毕业 |
| **五步方法论** | 闻味道 → 揪头发 → 照镜子 → 新方案 → 复盘 |
| **7项检查清单** | L3+ 强制完成的诊断清单 |
| **抗合理化表** | 14 种常见借口的识别与封堵 |
| **Hooks** | 自动挫败检测 + 失败计数 + 状态持久化 |

**使用**：

```text
/block-break              # 激活 Block Break 模式
/block-break L2           # 从指定压力等级启动
/block-break fix the bug  # 激活后立即执行任务
```

也可通过自然语言触发：`try harder`、`别偷懒`、`又错了`、`stop spinning` 等（由 hooks 自动检测）。

### Skill Lint — Claude Code Skill 校验工具

校验 Claude Code plugin 项目中 skill 文件的结构完整性和语义质量。Bash 脚本做结构检查，AI 做语义检查，互补覆盖。

| 检查类型 | 说明 |
|----------|------|
| **结构检查** | frontmatter 必填字段 / 文件存在性 / references 引用 / marketplace 条目 |
| **语义检查** | description 质量 / name 一致性 / command 路由 / eval 覆盖度 |

**使用**：

```text
/skill-lint              # 激活，显示说明
/skill-lint .            # 校验当前项目
/skill-lint /path/to/plugin  # 校验指定路径
```

### News Fetch — 新闻获取工具

指定主题和时间段，获取新闻清单。内置三级网络降级策略，确保不同网络环境下都能工作。

| 特性 | 说明 |
|------|------|
| **三级降级** | L1 WebSearch → L2 WebFetch 国内源 → L3 curl |
| **去重合并** | 同一事件多来源自动合并，保留最高分条目 |
| **相关性打分** | AI 根据主题匹配度打分排序 |
| **概要补全** | 无摘要时自动抓取正文生成 |

**使用**：

```text
/news-fetch AI                    # 本周 AI 新闻
/news-fetch AI today              # 今日 AI 新闻
/news-fetch 机器人 month          # 本月机器人新闻
/news-fetch climate 2026-03-01~2026-03-31  # 指定时间段
```

*更多 skill 持续添加中...*

## 项目结构

```text
jskills/
├── shared/                        # 通用内容（所有平台共享）
│   └── <skill>/
│       ├── references/            # 方法论、检查清单等
│       ├── scripts/               # 辅助脚本
│       └── agents/                # Sub-agent 定义
├── skills/                        # Claude Code 平台（SKILL.md + symlink → shared/）
│   └── <skill>/
│       ├── SKILL.md               # Claude Code 适配版
│       ├── references/ → symlink  # 指向 shared/<skill>/references/
│       ├── scripts/ → symlink
│       └── agents/ → symlink
├── platforms/                     # 其他平台适配层
│   └── openclaw/
│       └── <skill>/
│           ├── SKILL.md           # OpenClaw 适配版
│           ├── references/ → symlink
│           └── scripts/ → symlink
├── .claude-plugin/                # Claude Code marketplace 元数据
├── hooks/                         # Claude Code 平台 hooks
├── evals/                         # 跨平台评估场景
├── docs/                          # 跨平台文档
└── plugin.json                    # 集合级元数据
```

**设计原则**：
- **通用内容写一次**：references/scripts/agents 放 `shared/`，各平台通过 symlink 引用
- **平台并列不互相依赖**：`skills/`（Claude Code）与 `platforms/openclaw/` 各自独立
- **Skill 相互独立**：每个 skill 的变更不影响其他 skill
- **可扩展**：新增 skill = `shared/` + 各平台 SKILL.md；新增平台 = `platforms/<name>/` + symlink

## 贡献新 Skill

1. `shared/<name>/references/` — 通用内容（方法论、规则等）
2. `skills/<name>/SKILL.md` — Claude Code 适配版 + symlink 到 shared
3. `platforms/openclaw/<name>/SKILL.md` — OpenClaw 适配版 + symlink 到 shared
4. `evals/<name>/scenarios.md` + `run-trigger-test.sh` — 评估场景
5. `.claude-plugin/marketplace.json` — `skills` 数组追加
6. 如需 hooks，在根 `hooks/hooks.json` 中添加

详见 [CLAUDE.md](CLAUDE.md) 开发规范。

## License

[MIT](LICENSE) - [juserch](https://github.com/juserch)

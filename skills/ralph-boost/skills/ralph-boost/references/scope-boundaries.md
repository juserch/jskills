# ralph-boost — 能力边界

## 定位

- **分类**：hammer（行为约束，驱动自主循环）
- **触发**：`/ralph-boost setup` / `run` / `status` / `clean` 显式子命令
- **本质**：自主开发循环 + 内建 block-break L0-L4 压力升级，从"3 轮放弃"到"6-7 轮渐进自救"

## ✅ 能解决的问题

| 问题类型 | 机制 | 典型案例 |
|---------|------|---------|
| 自主循环收敛失败 | Circuit breaker + L0-L4 压力 | "无限 spinning" → L3+ 强制换方案 |
| 无 graceful exit | L4 产出 handoff report | 失败时生成结构化交接文档而非裸 crash |
| 跨轮状态丢失 | 统一 state.json | 循环间保留压力等级 / 已试方案 |
| 手动 loop 重启开销 | `/ralph-boost run` 一键继续 | 会话重开后 session-restore 读 state |
| "逼自己" 与 "逼 agent" 混杂 | block-break 内建 + Agent loop 分离 | 行为约束和循环控制解耦 |

## ❌ 不能解决的问题

### 设计边界内（故意不管）

| 问题 | 为什么不管 |
|------|-----------|
| 模糊需求 | Loop without goal = churn；ralph-boost 要求任务目标清晰 |
| 架构级判断 | 需要人工权衡（性能 vs 可读性等），loop 不做这种选择 |
| 多 agent 协调 | 单 loop 设计，不处理并行 agent 竞争 |

### 超出设计能力（接不住）

| 问题 | 为什么接不住 |
|------|-------------|
| 实时外部状态变化 | 流水线假定稳态；API 突然 rate-limit 会让 loop 卡住 |
| 跨 session 真正上下文延续 | state.json 只保存机械状态，不保存语义上下文 |
| 并发环境竞争 | 同时两个 loop 跑同一 `.ralph-boost/` 会污染状态 |

## 🚫 不应使用场景

- **交互式调试**：太重，直接 `/block-break` 更合适
- **一次性任务**：setup/run/clean 开销 > 收益
- **需频繁人工 checkpoint 的工作**：loop 会绕过你；应该用单步对话

## 一句话定位

> ralph-boost 是**带收敛保证的自主循环引擎**——它把 block-break 的"别放弃"嵌进 loop，让 agent 能在无人值守下跑几小时而不空转，但它需要**清晰的目标**和**稳态环境**才能真正收敛。

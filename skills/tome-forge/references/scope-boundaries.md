# tome-forge — 能力边界

## 定位

- **分类**：crucible（融合产出，LLM 编纂 wiki）
- **触发**：`/tome-forge init` / `capture` / `ingest` / `query` / `lint` / `compile` 子命令
- **本质**：双层 KB（原始素材不可变 + wiki 层 LLM 编纂），含 My Understanding Delta 人类保护区

## ✅ 能解决的问题

| 问题类型 | 机制 | 典型案例 |
|---------|------|---------|
| 个人 KB 构建 | init + capture + ingest | 把散落笔记编成结构化 wiki |
| LLM 自动编纂 | compile 阶段重新交叉引用 | 新素材自动链到相关页面 |
| 人类洞察保护 | My Understanding Delta sacred | LLM 永不覆盖人工写的见解 |
| 零基础设施 | 纯 Markdown + Git | 不需要数据库 / embedding / server |

## ❌ 不能解决的问题

### 设计边界内（故意不管）

| 问题 | 为什么不管 |
|------|-----------|
| 团队协作 / 实时同步 | 设计为个人 KB，不处理 merge conflict |
| 加密 / 密级内容 | 纯 Markdown，全文可见 |
| 事务性数据 | KB 是知识存储不是业务存储 |

### 超出设计能力（接不住）

| 问题 | 为什么接不住 |
|------|-------------|
| 自动刷新 stale 源 | compile 需手动触发，不做定期扫描 |
| 审批流内容 | 没有 review/approve 机制 |
| 跨 KB 全局查询 | query 限定在当前 KB，不跨目录联合 |

## 🚫 不应使用场景

- **ad-hoc 笔记**：结构负担过重，直接写 Markdown 就够了
- **事务性数据库**：用 SQLite / Postgres
- **需要 approval workflow 的内容**：没有权限 / 审批机制

## 一句话定位

> tome-forge 是**LLM 为你编纂的私人图书馆**——它让你把散材变结构化 wiki 而保留人类洞察，但只为个人设计、不做实时同步、不做权限控制。

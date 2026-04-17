# skill-lint — 能力边界

## 定位

- **分类**：anvil（承托定型，输出 pass/fail 判定）
- **触发**：`/skill-lint <path>` 显式命令
- **本质**：Claude Code skill plugin 的结构 + 语义校验器，输出 errors / warnings / passed JSON

## ✅ 能解决的问题

| 问题类型 | 机制 | 典型案例 |
|---------|------|---------|
| 结构合规 | S01-S08 core rules | SKILL.md 缺 description / plugin.json 缺失 |
| 约定一致性 | S09-S17 extended rules（配置驱动） | 命名不符 noun-verb / category 不在允许列表 |
| Integrity hash 校验 | S19 + SHA-256 比对 | marketplace.json 的 hash 与 SKILL.md 不一致 |
| i18n 覆盖 | S15-S16 | 新 skill 漏了某语言 README |
| 平台适配 | S14 | openclaw 镜像缺 references 文件 |

## ❌ 不能解决的问题

### 设计边界内（故意不管）

| 问题 | 为什么不管 |
|------|-----------|
| skill 运行时行为正确性 | 静态校验，不跑 skill；用 `evals/` 的 trigger-test 兜 |
| AI 语义判断精度 | M01-M05 语义检查由 AI 做，非 100% 准确 |

### 超出设计能力（接不住）

| 问题 | 为什么接不住 |
|------|-------------|
| 约定演进的历史版本 | 只看当前 `.skill-lint.json`；老 skill 按新规则会挂 |
| License 合规 | 只校验 frontmatter 的 license 字段存在，不做法律审计 |
| 代码安全审计 | 不扫 `scripts/*.sh` 的 shell injection / 权限滥用 |

## 🚫 不应使用场景

- **非 plugin 项目**：core rules 依赖 SKILL.md / plugin.json 结构，跑在普通项目会报一堆无关 error
- **生产代码质量评审**：不是 linter、不是 type checker、不是 security scanner
- **许可证法律评审**：不做 license compatibility 分析

## 一句话定位

> skill-lint 是**Claude Code plugin 的结构 CI**——它保证"符合约定、hash 一致、文件齐全"，但不保证"skill 运行时真的能跑"，也不取代代码质量 / 安全 / 许可证评审。

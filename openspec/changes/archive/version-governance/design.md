# Design

> 影响分类:cross(跨 8 个 skill 的 SKILL.md / marketplace.json / skill-lint / 4 份 spec / CHANGELOG.md / 8 个 platform mirror,不归属任何单一 forge 4 分类)

## 决策 1(修订) — SSOT 锁定到 marketplace.json `plugins[].version`,不放 SKILL.md frontmatter

**架构 pivot 背景**:本决策最初采纳 SKILL.md frontmatter `version:` 作为 SSOT。实施时(2026-05-07)经 IDE 实测 verified,Claude Code 官方 skill schema 仅支持 `argument-hint / compatibility / description / disable-model-invocation / license / metadata / name / user-invokable` 八个顶层字段,**`version` 不在其中**。尝试嵌套到 `metadata.version` 也被 schema 拒绝(IDE 持续告警同一信息)。

修订后的最终决策:

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A'(采纳,pivot 后)** | SSOT = `.claude-plugin/marketplace.json plugins[].version`(Claude Code marketplace 元数据 schema 显式支持);SKILL.md frontmatter MUST NOT 含 `version` 字段(regression guard) | 与 Claude Code 官方 schema 兼容;lint 仍能 fail-loud 校验 help-card / CHANGELOG;skill 编辑者通过 help-card 第一行字面量看到版本号 |
| ~~A(早期采纳,已弃)~~ | ~~SSOT = SKILL.md frontmatter `version:`~~ | **被否决**:Claude Code schema 不支持 |
| B | SSOT = 独立 `VERSION` 文件 | **拒绝**:8 个 skill = 8 个 VERSION 文件,反而增加镜像点 |

**反例验证**:[skills/insight-fuse/SKILL.md:16](../../../skills/insight-fuse/SKILL.md#L16) H1 已是 `v3.4`、commit `cf79b1d feat(insight-fuse): v3.4 ...` 已合入,但 [marketplace.json L107](../../../.claude-plugin/marketplace.json#L107) 之前停在 `3.3.0` —— 这是"marketplace 没跟着升"的活例,**修复方向**是把 marketplace 升至 SSOT(本 change 已修正),不是把版本搬到 frontmatter。

**SSOT 可见性补偿**:版本号在 SKILL.md 内通过两个位置可见:
1. `## Help` 段 code block 第一行 `<Skill Name> v<X.Y.Z> — <tagline>`(由 S30 强制等于 marketplace SSOT)
2. description 字段(可选含 `v<X.Y>` 字面量,decoration 性质,不强制)

AI 编辑 SKILL.md 时通过 ## Help 段看到版本号,自然带版本意识。

## 决策 2 — SemVer 2.0.0 语义,bump 规则贴进 skill-lifecycle 场景 B

skill-lifecycle 场景 B(修改 skill)必须答的新问题:「这次改动要不要 bump 版本,bump 哪一位?」三种情况:

| 改动类型 | 例子 | 版本位 |
|---|---|---|
| **MAJOR** 破坏性 | 删除一条红线 / 改 hook 触发条件不向后兼容 / 重命名 frontmatter 必填字段 | `X.y.z` |
| **MINOR** 行为追加 | 新增 hook surface(claim-ground v1.1 → v1.2 加 prompt-gate / pre-tool-gate)/ 新增 flag / 新增 stage | `x.Y.z` |
| **PATCH** 措辞修复 | 修 typo / 修 references 排版 / 不影响行为的文档勘误 | `x.y.Z` |

bump 操作目标(pivot 后):**marketplace.json + help-card + CHANGELOG 三处同步**。frontmatter 不变(因为不持版本)。

**反例验证**:

- 已归档 [archival-mandatory-observable](../archive/archival-mandatory-observable/proposal.md) 写明 "council-fuse / news-fetch / tome-forge:1.0.0 → 1.1.0(语义版本:MINOR——新增 `--no-save` flag + 强制可见输出契约,向后兼容)" —— 既往实践已经在用 SemVer,本 change 只是把这条隐含约定写进 spec。
- claim-ground 1.1 → 1.2 同样符合 MINOR(追加 prompt-gate / pre-tool-gate / R10-R15)。

## 决策 3 — 锁步用 lint,不用 hash 脚本带版本

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A(采纳)** | 新增 skill-lint 规则 S29/S30/S31,跑在自检三命令里 | lint 是已有基础设施;error 级别让 PR 不能合入;**fail-loud > silent-sync** |
| B | 扩展 [scripts/recalc-all-hashes.sh](../../../scripts/recalc-all-hashes.sh) 自动从 marketplace.json 把 version 抄到 help-card / CHANGELOG | **拒绝**:silent sync 会掩盖一类风险——「marketplace 已发布在 N.N.N,开发分支无意中 bump 但忘记发版」。让人看到飘移、由人决定升降,不让脚本悄悄抹平 |
| C | 写 git pre-commit hook 强制 | **拒绝**:违反 forge 零运行时依赖原则;pre-commit hook 跨开发机难一致 |

**反例验证**:[scripts/recalc-all-hashes.sh](../../../scripts/recalc-all-hashes.sh) 当前职责单一(只重算 hash),写得很干净。把 version 同步混进去会扩大该脚本的爆炸半径,违反单一职责。lint 与 recalc 分工清晰:recalc 把 SKILL.md → marketplace 的 hash 单向同步;lint 双向校对 marketplace ↔ help-card ↔ CHANGELOG 字面量。

## 决策 4 — Help card 第一行格式(静态字面量,非模板替换)

采纳:[openspec/specs/help-mode/spec.md](../../specs/help-mode/spec.md) 的模板 A/B 在 code block 内第一行约定为:

```
<Skill Name> v<X.Y.Z> — <one-line tagline>
```

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A(采纳)** | 静态字面量 + S30 lint 校对(版本号字面量 = marketplace SSOT) | 零运行时开销;help card 显示的版本号 = marketplace.json `plugins[].version`,由 lint 强制相等 |
| B | `{{VERSION}}` 模板,runtime hook 替换 | **拒绝**:违反零依赖(要 sed/jq runtime 注入);help card 是 LLM 渲染的纯 markdown,模板替换无可信触发点 |
| C | 仅 description 含版本号,help card 不打 | **拒绝**:description 是给 marketplace 索引看的;help card 是给用户看的;用户 `/skill help` 看不到版本就无法 self-serve 报 issue |

**反例验证**:
- [skills/insight-fuse/SKILL.md:16](../../../skills/insight-fuse/SKILL.md#L16) 已经是 `# Insight Fuse v3.4 — 系统化多源调研熔炼引擎` 这个格式,证明该格式可读 / 可写 / 可 grep。
- pre-fix 状态下 [skills/claim-ground/SKILL.md:23](../../../skills/claim-ground/SKILL.md#L23) 的 `Claim Ground v1.1 — Epistemic constraint engine` 是 v1.1 → v1.2 升级时漏改的活例 —— 正是 S30 要捕获的飘移。

## 决策 5 — 一次性数据迁移在本 change 内完成,不分两 PR

修两处版本飘移 + 7 个 canonical help card 加版本行 + 3 个 platform mirror help card 加版本行 + 创建 CHANGELOG = 都是机械改动。如果分阶段(先加 spec,后修数据),中间窗口期 lint 失败、PR 阻塞。**采纳一次性迁移**:spec / lint / 数据修复在一个 change 内全部落地,单 PR。

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A(采纳)** | 一次性 PR:spec + lint + canonical + platform + marketplace + CHANGELOG + 重算 hash | 原子;lint S29/S30/S31 启用即所有 skill 通过 |
| B | 分两 PR:先 spec + lint(warn 级),后修数据 | **拒绝**:warn 级容易被忽视;中间窗口期开发分支视角混乱 |

**反例验证**:archived [bootstrap-openspec-and-restructure](../archive/bootstrap-openspec-and-restructure/) 同样是契约 + 数据一次性迁移,经验上单 PR 可控。

## 决策 6(修订) — Platform mirror 同步:仅 help-card,不动 frontmatter

**架构 pivot 后**,platform mirror 的同步对象从 "canonical frontmatter version" 改为 "marketplace.json `plugins[].version`"——通过 help-card 第一行字面量比对,而不是通过 mirror frontmatter。

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A'(采纳,pivot 后)** | platform mirror frontmatter 不持 version 字段(regression guard);若含 Help 段,help-card 第一行 `v<X.Y.Z>` 必须等于 marketplace SSOT | 与 Claude Code schema 兼容(平台 mirror 同样不能持 `version` 字段);S30 校验 platform mirror help-card |
| ~~A(早期采纳,已弃)~~ | ~~platform mirror frontmatter `version` 必须字面量等于 canonical frontmatter version~~ | **被否决**:连 canonical 都不能持 version,mirror 更不能 |
| B | 仅改 canonical,openclaw 留 follow-up | **拒绝**:openclaw mirror 的 help-card 之前有 v1.1 / "Insight Fuse —"(无版本)等飘移,留 follow-up 等于让飘移继续暴露用户 |

**反例验证**:openclaw 现状(grep 实测,pre-fix):
- `platforms/openclaw/claim-ground/SKILL.md` description 已是 `v1.2`,但 help card 仍 `Claim Ground v1.1` —— 与 canonical 同款飘移,需同期修
- `platforms/openclaw/insight-fuse/SKILL.md` description 已是 `v3.4`,但 help card 是 `Insight Fuse — ...`(无版本)
- 5 个 mirror(block-break / council-fuse / news-fetch / ralph-boost / skill-lint)无 Help 段 —— S30 自动跳过;补齐 Help 段由 [openclaw-drift-fix](../openclaw-drift-fix/proposal.md) 处理

**实施细节**:
- S29 platform 子句:扫描 `platforms/<plat>/<skill>/SKILL.md` frontmatter,确认无 `version:` 字段(regression guard)
- S30 platform 子句:`## Help` heading regex 放宽为 `^##\s+Help\b`(允许 `## Help (no arguments)` 变体,因 openclaw tome-forge 实际用此变体);help-card 第一行 `v<X.Y.Z>` 比对 marketplace `plugins[name].version`
- platforms 列表从 [.skill-lint.json](../../../.skill-lint.json) `rules.platforms` 读取,与既有 S22 / S28 同源

## 决策 7 — CHANGELOG 选 root 单文件 + Keep-a-changelog 格式 + S31 error 级 lint

(用户决策点;详见 RFC 评审会上的 AskUserQuestion 记录)

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A(采纳)** | root `/CHANGELOG.md` 单文件,内部按 skill 分 H2 节;Keep-a-changelog 1.1.0 风格 | 集中入口,用户不必在 8 个目录里翻找;每个 skill 独立 H2 节,下游 lint 可结构化解析;新加 skill 时一行 H2 即可扩展 |
| B | per-skill `skills/<n>/CHANGELOG.md` × 8 + platform mirror × 8 = 16 文件 | **拒绝**:与现有 self-contained 模式表面契合,但实际增加 16 个待维护文件;与 SSOT 单点入口理念冲突 |
| C | hybrid (root index + per-skill detail) | **拒绝**:17 文件;双写复杂度大;一个 entry 不知道写哪里 |

S31 强制级:**error**(用户决策)。理由:履行同样"fail-loud > silent-rot"原则(决策 3);warn 级 8 个 skill 版本号都是这样飘出来的活例。

**实施细节**:
- 解析逻辑:扫 `## <skill-name>` 取下方第一个 `### [X.Y.Z]` 即"latest",与 marketplace SSOT 比对(pivot 后,SSOT 改自 frontmatter → marketplace)
- skill 名匹配:H2 文本严格 `^## ([a-z0-9][a-z0-9-]*)$` 正则(命名规范同 [.skill-lint.json](../../../.skill-lint.json) `naming-pattern`)
- CHANGELOG 缺失 → S31 报 "CHANGELOG.md missing at repo root"(整体 fail,非 per-skill)

**反例验证**:负向测试两条都通过——
- bump marketplace v1.3.0 而 CHANGELOG top entry 仍 v1.2.0 → S31 captured ✓
- 删除 CHANGELOG.md → S31 captured "missing at repo root" ✓

## 决策 8(新增,pivot 后) — Frontmatter regression guard 防止未来重新引入 version 字段

| 选项 | 描述 | 取舍 |
|---|---|---|
| **A(采纳)** | S29 在 lint 阶段扫描所有 SKILL.md frontmatter,任一含 `version:` 字段即报 error | 防御性 regression guard;避免未来贡献者无意中重新加入 version 字段触发 IDE schema 告警 |
| B | 仅靠 IDE 告警提示 | **拒绝**:IDE 告警非阻塞,容易被忽略;CI 不跑 IDE,飘移会进 main |
| C | 不加 regression guard | **拒绝**:本 change 删完所有 frontmatter version 字段后,无防御机制阻止下次回归 |

**实施细节**:S29 python heredoc 包含 `has_frontmatter_version_field()` 函数,正则匹配 frontmatter 内任意位置的 `^version:` 或 `^\s+version:`(顶层 + 嵌套);命中则报 error。

## 风险与回滚

- **风险 R1**:S29 frontmatter regression guard 启用瞬间,如果 SKILL.md 还有遗漏的 `version:` 字段会失败。
  **缓解**:本 change 已 grep 确认 16 个 SKILL.md 全部清理;lint 已通过(0 errors / 511 passed)。后续作者无意中加入 `version:` 字段会被 S29 阻塞。

- **风险 R2**:S31 启用瞬间 CHANGELOG.md 必须存在且 8 个 skill 各有 entry。
  **缓解**:本 change 一并创建 root CHANGELOG.md 并 seed 8 段;lint 已通过。

- **风险 R3**:5 个 openclaw mirror 无 Help 段(`block-break / council-fuse / news-fetch / ralph-boost / skill-lint`),S30 自动跳过这些 → 用户在 openclaw 跑 help 看不到版本号。
  **缓解**:本 change Non-goals 显式声明不补齐 Help 段;[openclaw-drift-fix](../openclaw-drift-fix/proposal.md) change 处理 5 个 mirror Help 段补齐。

- **风险 R4**:Claude Code schema 未来可能新增 `version` 顶层字段支持,届时 S29 regression guard 会过严。
  **缓解**:监测 Claude Code SDK 更新;若官方支持 `version` 字段,follow-up RFC 重新评估 SSOT 选择(可保留 marketplace SSOT,或迁回 frontmatter,二选一)。

- **回滚路径**:若 S29/S30/S31 启用后造成 CI 长时间红,可在 [.skill-lint.json](../../../.skill-lint.json) 把三条规则降级为 `"warn"`(与现状 `require-help-section: "warn"` 模式一致),spec 与数据保留,待修齐后再升 error。

# Design — Insight-Fuse v3.4 Self-review + LOAD_BEARING + Calibration

> 影响分类：crucible（insight-fuse 是 crucible，本 change 全部在 skill 内部，
> 不触达横向 spec）

## 决策 1 — 版本号：v3.4 小版本，不跳 v4

| 选项 | 描述 | 取舍 |
|------|------|------|
| **A. v3.3 → v3.4 小版本**（采纳） | 三补丁全为追加，主流程/既有 checks 保留；语义版本号小升 | 改动是 additive；既有报告 grade 计算/footer 字段无 breaking change（reviewer 字段缺省值兼容旧 v3.3 报告） |
| B. v3.3 → v4 主版本 | 标记三补丁为重大重构 | **拒绝**：8 阶段、17 checks、6 dims 全部不动；称 v4 误导用户预期"主流程改了" |
| C. 三 patch 拆三个小版本（v3.4 / v3.5 / v3.6） | 每补丁独立 RFC | **拒绝**：三补丁共享 motivation（self-eval loop）+ 共享 dry-run 数据集（三份历史报告）；拆开产生跨 RFC 协调成本与版本碎片 |

**反例验证**：v3.2 的 Stage 7 KB 归档（[archival-mandatory-observable](../archive/archival-mandatory-observable/proposal.md)）
也是追加式（新阶段 + 新行为），同样按小版本号处理。本 change 与之同构，应保持一致。

## 决策 2 — Stage 6.5 位置：Stage 6 之后、Stage 7 之前

| 选项 | 描述 | 取舍 |
|------|------|------|
| **A. Stage 6 → 6.5 → 7**（采纳） | 6.5 跑独立 reviewer，KB 归档前完成 | KB 里存的是含 reviewer score 的"完整版"评分，避免归档自评分污染 KB |
| B. Stage 7 之后 | 归档后再独立 review | **拒绝**：KB 已存自评分；reviewer 后产出无法回写到 KB（Stage 7 是 mandatory + observable，归档完成 = closed） |
| C. 与 Stage 6 合并（Stage 6 内部加 reviewer 子步骤） | 两评分都在 Stage 6 | **拒绝**：reviewer 必须**独立 agent**（只读最终报告，禁读中间产物），与 Stage 6 main agent 共用上下文会破坏独立性 |

**反例验证**：[skills/insight-fuse/SKILL.md:94](../../../../skills/insight-fuse/SKILL.md)
当前 Stage 7 已是 mandatory + observable（v3.2 落地），证明"归档前必须完成所有
QA"是既有契约。Stage 6.5 顺承此契约。

## 决策 3 — C18 LOAD_BEARING 用追加而非替换 C14

| 选项 | 描述 | 取舍 |
|------|------|------|
| **A. 追加 C18**（采纳） | 19 项 blocking check，C14 (FIR) 保留 | C14 是 FIR separation——report 内每段 `[F]/[I]/[R]` 起首的硬约束，与 LOAD_BEARING 检查正交 |
| B. 替换 C14（draft 原意） | 删 FIR check，C14 改为 LOAD_BEARING | **拒绝**：[references/quality-standards.md:24](../../../../skills/insight-fuse/references/quality-standards.md) 的 C14 是 FIR separation，删除会丢失整套 Fact/Inference/Recommendation 分隔约束——这是 v3 整个 critic 框架的支柱 |
| C. 扩展 C15（把 LOAD_BEARING 塞进"主源绑定"） | 不新加 check ID | **拒绝**：C15 检查"声明是否有一手源命中白名单"——粒度是单条声明；LOAD_BEARING 检查"source 是否在多节担当关节"——粒度是 source 级；强行塞进会让 C15 失去单一职责 |

**反例验证**：[references/quality-standards.md:29](../../../../skills/insight-fuse/references/quality-standards.md)
明确"Check 1-11 是 v2 保留；Check 12-14 是 v3 新增；Check 15-17 是 v3.1 新增"——
增量式追加是该文件的既定模式。C18-C19 沿用此模式。

## 决策 4 — `{cal:...}` / `{uncal}` 用独立内联标注，不扩展 FIR

| 选项 | 描述 | 取舍 |
|------|------|------|
| **A. 独立内联标注**（采纳） | 数字后紧跟 `{cal: <ref-class>}` 或 `{uncal}`，与 `{P}/{S→}` 同级 | 校准是**数字粒度**（一段可有多个数字、各自校准状态不同）；标注必须随数字走 |
| B. 扩展 FIR 加 `[C-cal]` / `[C-uncal]` 段标 | 段首再加一种标记 | **拒绝**：FIR 是段落粒度（一段一种类型）；同一段内可能既有校准数字也有 vibes 数字，段标无法表达 |
| C. 加新 dim "calibration" 到 6 维 | 维度变 7 | **拒绝**：6 维是跨学科文献收敛产物（[scoring-rubric.md:9](../../../../skills/insight-fuse/references/scoring-rubric.md)）；动维度是大版本变化；`{uncal}` 显式标注本质是 transparency 维度的子项，归到既有 transparency 即可 |

**反例验证**：[research-protocol.md:114](../../../../skills/insight-fuse/references/research-protocol.md)
的 `{P}` / `{S→primary-url}` 已是内联数字级标注，与 §3.3 Citation Format 平行
而非嵌入 FIR——`{cal}` / `{uncal}` 沿用此设计模式，新章节 §3.10 与 §3.3 同级。

## 决策 5 — scan-load-bearing 用 bash 不用 Python

| 选项 | 描述 | 取舍 |
|------|------|------|
| **A. bash + grep + yq**（采纳） | 60 行 shell；与 forge 其他 skill 一致 | insight-fuse 此前零脚本；引入 Python 等于开新依赖先例（runtime + 测试 + lint） |
| B. Python | 更易写正则 + 数据结构 | **拒绝**：bash + grep 已足够（解析 markdown 标题与 inline link 是简单文本任务，复杂度不超过 [skills/skill-lint/scripts/skill-lint.sh](../../../../skills/skill-lint/scripts/skill-lint.sh)） |

**反例验证**：[skills/skill-lint/scripts/skill-lint.sh](../../../../skills/skill-lint/scripts/skill-lint.sh)
是 forge 自检脚本，纯 bash + grep + jq；同等复杂度任务，sticking with bash 让
依赖面收敛。

## 决策 6 — Δ ≥ 1.0 触发阈值

| 选项 | 取舍 |
|------|------|
| **A. Δ ≥ 1.0（采纳）** | 1.0 ≈ 一个 Grade 档位（A→B 或 B→C）；近期 author 分布 7.5-8.9 区间，预期 dry-run 触发 1-2 份（合理样本） |
| B. Δ ≥ 0.5 | **拒绝**：分数本身有 ±0.3 噪音；0.5 阈会让 Reconciliation 段太频繁，稀释信号 |
| C. Δ ≥ 1.5 | **拒绝**：1.5 跨档跨度大，会让边缘问题（B+ 应降为 B）漏过 |

**反例验证**：[scoring-rubric.md:67](../../../../skills/insight-fuse/references/scoring-rubric.md)
等级映射 A ≥ 8.5 / B 7.0-8.4 / C 5.5-6.9 / D < 5.5——B 档跨 1.5 分，C 档跨 1.5 分。
Δ ≥ 1.0 ≈ 半档，是"明显但不极端"的分歧点。

## 决策 7 — Reviewer agent 共享 19 项 checks 定义，但不共享中间产物

**采纳**：reviewer agent prompt 包含完整 17 → 19 项 check 列表 + 6 dims rubric，
保 author/reviewer 可比；但**禁读** Stage 0 skeleton.yaml / Stage 3 SOURCES_USED
/ Stage 5 deep-dive 草稿——独立性来自"看不到 author 的中间推理路径"，不来自
"用不同的 rubric"。

prompt 末段加：

> Reviewer 可拒绝某 check 在本报告 type 下的合理性，并在 `disputed_checks`
> 字段记录拒绝理由。

**反例验证**：人类同行评审（peer review）也是看最终稿、按既定 review criteria
打分；独立性来自 reviewer 与 author 不共享 lab notebook，不是用不同的评审
criteria。

## 影响范围

| 文件 | 改动类型 | 估计行数 |
|------|---------|:-:|
| `skills/insight-fuse/SKILL.md` | 修改（追加 Stage 6.5 + 版本号） | +35 |
| `skills/insight-fuse/references/quality-standards.md` | 修改（追加 C18 + C19 + 详解） | +90 |
| `skills/insight-fuse/references/scoring-rubric.md` | 修改（footer + Δ 规则 + 19 项更新） | +30 |
| `skills/insight-fuse/references/research-protocol.md` | 修改（追加 §3.10） | +35 |
| `skills/insight-fuse/references/output-formats.md` | 修改（footer 示例 + SINGLE_SOURCE_RISK 槽） | +20 |
| `skills/insight-fuse/agents/insight-reviewer.md` | **新建** | +120 |
| `skills/insight-fuse/scripts/scan-load-bearing.sh` | **新建** | +60 |
| `skills/insight-fuse/templates/*.md` (13 份) | 修改（注释槽） | +5 × 13 |
| `platforms/openclaw/insight-fuse/...` | 镜像同步 | 与 canonical 完全一致 |

## 不在此 change 内（留作后续）

- **Reviewer agent dry-run on 3 历史报告** —— 验证步骤在 tasks.md 内，但 dry-run
  产出的 reviewer score 数据不入本 change 仓库（只用作"reviewer 是否真能产出
  有意义降分"的人工核对，不算落地物）
- **C18 / C19 advisory→blocking 分档**最终调优——目前按 `quick` advisory /
  `standard+` blocking 起步，运行 5 份新报告后再校准
- **TL;DR / Outlook 段的具体 regex 边界**——C19 prompt 给的"TL;DR 段 + Outlook
  段"在不同 research-type 模板里位置不同，由 reviewer agent 在运行期识别，不
  硬编码 regex

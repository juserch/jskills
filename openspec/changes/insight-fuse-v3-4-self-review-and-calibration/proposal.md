# Insight-Fuse v3.4 — Self-review pass + Load-bearing cross-validation + Confidence calibration

> 这次 change 解决的张力：v3.3 的 17 项 blocking check 已覆盖"单条声明的源可靠性"
> （C15-C17），但**未覆盖**三类系统性盲区——report-level 自评循环、跨节单源关节、
> vibes-based confidence 数字。三盲区在三份近期报告交叉对比中暴露：14/14 PASS 倾向、
> 单源跨 4-5 sections 撑核心论证、TL;DR 出现"70-80%"无 base rate 锚。

## Why

近期对三份 v3.x 报告的横向 review 显示三个**结构性**问题，不是单份报告的失误，
而是 v3 框架自身的盲区：

1. **自评循环**——QA Footer 由作者 agent 自评分；跨报告自评分出现 inversion
   （学术综述+Nature 锚的报告自评 < 多 L4 媒体源的报告，方向反了）。Stage 6
   的 17-check 由 author 自跑，**没有独立 reviewer**校准 6 维评分。
2. **单源过载**——同一来源（Anthropic measuring-agent-autonomy / Apple EMNLP /
   智慧城市单聚合者 / 腾讯新闻 70-80% 闲置率）跨 ≥ 2 个 sections 撑 [F] 量化
   论证。C15-C17 检查"该声明是否有一手源 + verbatim quote + 跨源数字调和"，
   **不检查"该 source 是否在多节中担当不可替代的论证关节"**。
3. **Vibes-based confidence**——TL;DR 出现 "H1 70-80%"、"H1 6/10"、"H4 8/10" 这类
   数字，没有 base rate / reference class / 类似事件历史频率支撑。读者把它们当
   "已校准概率"读，但实质是直觉估计。C4 只检查"是否有 citation"，**不检查
   数字本身是否被任何参考类锚定**。

三盲区共享同一根因：**v3 把 quality 检查全压在"声明级"，没有 report-level 与
number-level 的约束**。本 change 用三个**追加式**补丁补齐：不动 8 阶段主流程、
不删任何既有 check，作为 v3.3 → v3.4 小版本升级。

## What Changes

**新增产出**：

- `skills/insight-fuse/agents/insight-reviewer.md`（新 agent，命名遵守 `insight-<role>`）
- `skills/insight-fuse/scripts/scan-load-bearing.sh`（新脚本，bash + grep + yq）

**SKILL.md / references 修改**（全部追加，不删既有）：

- `SKILL.md`：8 阶段表追加 **Stage 6.5 Reviewer pass**（在 Stage 6 QA 与 Stage 7
  KB 归档之间）；description / 标题 v3.3 → v3.4；增量段追加说明
- `references/quality-standards.md`：§一 17→19 项；新增 C18 Load-bearing
  cross-validation + C19 Calibration discipline 两行；§1.10 / §1.11 详解
- `references/scoring-rubric.md`：§四 17→19；§五 footer 模板追加
  `Author/Reviewer/Δ/Disputed checks` 四字段；§六追加 Δ ≥ 1.0 触发
  Reconciliation 段；§一末追加 v3.4 增量说明
- `references/research-protocol.md`：新增 §3.10 Calibration Annotation
  （`{cal: <ref-class>}` / `{uncal}` 内联标注语法），FIR 段不动
- `references/output-formats.md`：报告 footer 示例追加 reviewer 块；section 末
  预留 `[SINGLE_SOURCE_RISK]` 注释槽
- `templates/*.md`（13 份）：注释行说明 `[SINGLE_SOURCE_RISK]` 可填位置

**Platform mirror**：上述每条改动落 `platforms/openclaw/insight-fuse/` 同名文件，
最后 `diff -r` 验证零差异（满足 byte-identical 契约——见
[insight-fuse-platform-resync](../archive/insight-fuse-platform-resync/proposal.md)）。

## Non-goals

- **不改既有 17 checks 任一条**——仅追加 C18 / C19。Check 14 (FIR separation)
  不动。
- **不改 6 dims 评分维度**——transparency 维度已隐含"局限披露"，C19 与之同向加强。
- **不改 Stage 0-7 主流程顺序**——仅在 Stage 6 与 Stage 7 之间插入 Stage 6.5。
- **不改 skeleton.yaml schema**——reviewer agent 不读 skeleton。
- **不改 Critic 角色定义**——reviewer 与 Critic 是不同角色：Critic 在 Stage 3/5
  研究阶段挑战，reviewer 在 Stage 6.5 产出后独立评分。
- **不回溯 v3.3-及之前历史报告**——P3 grandfathering 边界：v3.4 起强制；旧报告
  不强制回溯改写。
- **不引入 Python**——`scan-load-bearing.sh` 用 bash + grep + yq，与 forge 其他
  skill 一致，不在本 skill 开 Python 先例。
- **不修改任何 `openspec/specs/` 文件**——本 change 是 skill 内部规约扩展，不触
  达 skill-lifecycle / category-decision / repo-invariants / platform-parity 契约。

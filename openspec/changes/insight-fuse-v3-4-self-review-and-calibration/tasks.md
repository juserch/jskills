# Tasks — Insight-Fuse v3.4 Self-review + LOAD_BEARING + Calibration

## Phase A — P1 Stage 6.5 Reviewer Pass

### Task A1 — 写 `agents/insight-reviewer.md`（新 agent）

**依赖**：无

**做什么**：创建 `skills/insight-fuse/agents/insight-reviewer.md`：

- frontmatter：`name: insight-reviewer` / `model: opus` / `description`（一句话）
- 角色定义：独立 review agent，Stage 6.5 入口被 main agent 调用
- 输入约束：**只读** 最终报告（合并视图：v3.3 多文件输出下由 main agent
  生成内存合并）+ 17→19 checks 定义 + 6 dims rubric
- 禁读清单：Stage 0 skeleton.yaml / Stage 3 SOURCES_USED 中间产物 /
  Stage 5 deep-dive 草稿 / 任何 author 中间推理
- 产出格式：`reviewer_score` (6 dims × score) / `disputed_checks` (list) /
  `降分项 + 理由` (markdown 段)
- prompt 末段：reviewer 可拒绝某 check 在本报告 type 下的合理性，记入
  `disputed_checks`
- 模型：opus（与 critic 一致——"stronger model" 角色）

**验证命令**：

```bash
test -f skills/insight-fuse/agents/insight-reviewer.md && \
  grep -E "^name: insight-reviewer$|^model: opus$" \
       skills/insight-fuse/agents/insight-reviewer.md
# 预期：两行均匹配

bash skills/skill-lint/scripts/skill-lint.sh skills/insight-fuse/
# 预期：PASS
```

---

### Task A2 — `SKILL.md` 8 阶段表追加 Stage 6.5

**依赖**：A1（reviewer agent 必须先存在再被引用）

**做什么**：在 `skills/insight-fuse/SKILL.md` 的 8 阶段表（约 [SKILL.md:75-94](../../../../skills/insight-fuse/SKILL.md)）
**Stage 6 与 Stage 7 之间**插入 Stage 6.5：

- 名称：`Stage 6.5 Reviewer pass`
- 触发：Stage 6 通过后、Stage 7 归档前
- 执行：main agent 生成报告合并视图（多文件→单视图，等价 `--merge`），
  调用 `insight-reviewer` agent，接收 reviewer_score / disputed_checks /
  降分项
- 决策：Δ < 1.0 → 直接写入 footer 进入 Stage 7；Δ ≥ 1.0 → 在报告末尾
  追加 `## §X Reconciliation` 段，author 逐条响应，最终采纳分数写入
  footer，再进入 Stage 7
- depth 路由：`quick` 跳过 Stage 6.5；`standard / deep / full` 必跑

**验证命令**：

```bash
grep -E "Stage 6\.5|Reviewer pass" skills/insight-fuse/SKILL.md
# 预期：≥ 2 条匹配（标题 + 表格条目）

grep -c "Stage [0-9]" skills/insight-fuse/SKILL.md
# 预期：原行数 + 新增 Stage 6.5 行数（非零增）
```

---

### Task A3 — `scoring-rubric.md` §五 footer 模板追加四字段

**依赖**：A1

**做什么**：在 `skills/insight-fuse/references/scoring-rubric.md` §五（约
[scoring-rubric.md:102-125](../../../../skills/insight-fuse/references/scoring-rubric.md)）
评分块模板追加：

```markdown
**Author score**：<auto-fill> / 10
**Reviewer score**：<auto-fill> / 10  ← v3.4 新增
**Δ**：<abs(author - reviewer)>（< 1.0：无 Reconciliation；≥ 1.0：见下文 §X Reconciliation）  ← v3.4 新增
**Disputed checks**：[<check-id list>]  ← v3.4 新增
```

§六失败处理表追加一行：

| 情形 | 行为 |
|------|------|
| Stage 6.5 Δ ≥ 1.0 | main agent 必须追加 `## §X Reconciliation` 段，逐条响应 reviewer 降分项；最终采纳分数写入 footer |

**验证命令**：

```bash
grep -E "Reviewer score|Disputed checks|Reconciliation" \
     skills/insight-fuse/references/scoring-rubric.md
# 预期：≥ 4 条匹配
```

---

## Phase B — P2 C18 LOAD_BEARING Cross-Validation

### Task B1 — `quality-standards.md` §一表格追加 C18

**依赖**：无

**做什么**：在 `skills/insight-fuse/references/quality-standards.md` §一
（约 [quality-standards.md:7-29](../../../../skills/insight-fuse/references/quality-standards.md)）
17 项表末追加 C18：

| # | Check | Criterion | 失败处理 |
|---|-------|-----------|---------|
| 18 | **Load-bearing cross-validation** | 同一 source 跨 ≥ 2 个 `## ` section 出现且承担 [F] 量化声明 → 标 LOAD_BEARING；每条 LOAD_BEARING source 必须 ≥ 1 条独立交叉验证（独立发布主体 + 独立方法 + 独立时间窗）；不满足时对应 section 末插入 `> [SINGLE_SOURCE_RISK]: ...` 注解 | 增加交叉验证源；或注解披露 |

§1.10 详解段（接 §1.9）：定义"跨节"（按 `## ` 切分）+ "独立交叉验证"判据（与
Check 10 Source independence 链路一致）+ 分档（`quick` advisory；
`standard/deep/full` blocking on 不可替代单源；`market/academic` 一律 blocking
on LOAD_BEARING 缺交叉验证）+ 与 C15-C17 的关系（互补，不重叠）。

header "17 项" → "19 项"；Check 1-11/12-14/15-17/**18-19** 历史标记段更新。

**验证命令**：

```bash
grep -c "^| 1[0-9] \|" skills/insight-fuse/references/quality-standards.md
# 预期：19（原 17 + C18 + C19 行）—— C19 在 C2.1 之前会失败，本任务先过 18

grep -E "Load-bearing cross-validation|SINGLE_SOURCE_RISK" \
     skills/insight-fuse/references/quality-standards.md
# 预期：≥ 3 条匹配

grep "19 项" skills/insight-fuse/references/quality-standards.md
# 预期：≥ 2 条（header + 末尾说明段）
```

---

### Task B2 — 写 `scripts/scan-load-bearing.sh`

**依赖**：B1（C18 定义先存在再扫描）

**做什么**：创建 `skills/insight-fuse/scripts/scan-load-bearing.sh`：

- 输入：单个报告 markdown 文件（多文件场景：先 cat 合并）
- 逻辑：
  1. 用 `awk` 按 `^## ` 切分 section
  2. 每个 section 提取 inline citation `[Name](url)`
  3. 按 host（去 path）去重，统计每个 source 出现的 section 数
  4. 对 `≥ 2 sections` 的 source，扫描该 section 是否含 [F] 量化声明
     （regex：数字 / `\{P\}` 标记 / 百分比 / 日期）
  5. 输出 LOAD_BEARING list（source name + section list + 量化声明命中节）
- 退出码：发现 LOAD_BEARING 不强制非零（advisory 性质，由 main agent 决定
  blocking 与否）
- 依赖：`awk`、`grep`、`sed`（POSIX）；不依赖 `yq`/`jq`（保持与 skill-lint 一致）

**验证命令**：

```bash
test -x skills/insight-fuse/scripts/scan-load-bearing.sh
# 预期：可执行（chmod +x 已设置）

bash skills/insight-fuse/scripts/scan-load-bearing.sh /tmp/sample-report.md \
  > /tmp/scan-out.txt 2>&1
# 用三份历史报告做 sanity test（[~/.claude/plans/insight-fuse-*.md] 之一）
# 预期：识别已知 load-bearing source（人工 spot-check）
```

---

### Task B3 — `output-formats.md` + `templates/*.md` 预留 SINGLE_SOURCE_RISK 槽

**依赖**：B1

**做什么**：

1. `skills/insight-fuse/references/output-formats.md`：在 footer 示例段之后追加
   一个"section 末注释槽"示例：
   ```markdown
   > [SINGLE_SOURCE_RISK]: 本节论证关键依赖 <SourceName>，未找到独立交叉验证。
   ```
   并说明：仅 C18 触发且 source 不可替代时填；advisory，不 block。
2. `skills/insight-fuse/templates/*.md`（13 份）：每份在主结构注释行（已有
   `<!-- section ratios: ... -->` 类似行的）追加注释提示：
   ```markdown
   <!-- C18 触发时此处可插入 [SINGLE_SOURCE_RISK] 注解 -->
   ```
   位置在每份 template 的"对比/分析/风险"等可能出现 LOAD_BEARING 的章节
   之前。

**验证命令**：

```bash
grep -l "SINGLE_SOURCE_RISK" skills/insight-fuse/templates/*.md | wc -l
# 预期：≥ 10（13 份模板大部分都有可能 LOAD_BEARING 的节）

grep "SINGLE_SOURCE_RISK" skills/insight-fuse/references/output-formats.md
# 预期：≥ 1 行匹配（footer 示例 + 说明文字）
```

---

## Phase C — P3 C19 Calibration Discipline

### Task C1 — `research-protocol.md` 新增 §3.10 Calibration Annotation

**依赖**：无（与 B 并行）

**做什么**：在 `skills/insight-fuse/references/research-protocol.md` §3.4 Source
Credibility 之后插入 §3.10 Calibration Annotation：

```markdown
### 3.5 Calibration Annotation（v3.4 新增）

报告中任何 confidence 数字（百分比 / N/10 评分 / "概率 X" / "可能性 X"）必须
紧跟内联标注：

| 语法 | 含义 | 约束 |
|------|------|------|
| `<num>{cal: <reference-class>}` | 已校准 | 必须紧跟 base rate / reference class / 类似事件历史频率的 inline citation 或 reference list 条目 |
| `<num>{uncal}` | 未校准（直觉估计） | §2-§N 主体允许；**禁止出现在 §1 TL;DR / Outlook 段** |

**示例**：

✅ `[I] 五年规划落地概率约 70%{cal: OECD 同类 AI 政策五年达成率 N=14, [OECD 2025](url)}`
✅ `[I] §3 主体可包含 \`H1 6/10{uncal}\`（明确承认是直觉估计）`
❌ `[F] TL;DR：H1 70-80%`（数字无标注且在 TL;DR；C19 fail）
❌ `[I] H4 8/10{uncal}` 出现在 TL;DR 或 Outlook 段（C19 fail）

**与 FIR 的关系**：FIR (`[F]/[I]/[R]`) 是段落粒度，calibration 是数字粒度；
同段可有多个数字，各自校准状态独立。
```

**验证命令**：

```bash
grep -E "§3\.5|Calibration Annotation|\\{cal:|\\{uncal\\}" \
     skills/insight-fuse/references/research-protocol.md
# 预期：≥ 5 条匹配
```

---

### Task C2 — `quality-standards.md` §一追加 C19 + §1.11 详解

**依赖**：B1（先有 C18 再 C19，行号顺序一致）

**做什么**：在 §一表追加 C19：

| # | Check | Criterion | 失败处理 |
|---|-------|-----------|---------|
| 19 | **Calibration discipline** | 任意 [F]/[I] 段含 (a) 百分比 (b) `N/10` 评分 (c) "概率 X" / "可能性 X" → 必须紧跟 `{cal: ...}` 或 `{uncal}`；TL;DR 与 Outlook 段禁止 `{uncal}` | reject 数字（要求加标注）；TL;DR 中 `{uncal}` 数字降级定性表述 |

§1.11 详解段：定义 "confidence 数字" 范围 + TL;DR / Outlook 段识别 + grandfathering
（v3.4 起强制；v3.3-及之前历史报告不强制回溯）+ 分档（一律 blocking，所有 type
+ depth）。

§5.2 等级映射段（如有）追加：C19 fail 不单独封顶 Grade（与 C15-C17 分档逻辑一致），
但 TL;DR 出现 `{uncal}` 数字 = transparency 维度自动 -1。

**验证命令**：

```bash
grep -c "^| 1[0-9] \|" skills/insight-fuse/references/quality-standards.md
# 预期：19 行（C18 + C19 都存在）

grep -E "Calibration discipline|TL;DR|Outlook" \
     skills/insight-fuse/references/quality-standards.md
# 预期：≥ 5 条匹配
```

---

### Task C3 — `scoring-rubric.md` §四 17→19 + transparency 维度补丁

**依赖**：A3 + C2

**做什么**：

1. `scoring-rubric.md` §四"17 项 blocking check"段（约 [scoring-rubric.md:78](../../../../skills/insight-fuse/references/scoring-rubric.md)）
   header 与表格更新到 19 项
2. §一 6 维表 transparency 行说明追加："含 AI 使用披露 + 反立场考量 + 边界声明
   + **{uncal} 数字显式标注**（v3.4 与 C19 联动）"
3. §一末追加"v3.4 增量"段：列 Stage 6.5 reviewer pass + C18 LOAD_BEARING +
   C19 calibration 三项

**验证命令**：

```bash
grep -E "19 项|v3\.4 增量" skills/insight-fuse/references/scoring-rubric.md
# 预期：≥ 3 条匹配

grep -c "^| C[0-9]" skills/insight-fuse/references/scoring-rubric.md
# 预期：与 quality-standards.md C-list 行数一致（19）
```

---

## Phase D — 锁版本号 + 镜像 + 自检

### Task D1 — `SKILL.md` description + 标题 v3.3 → v3.4

**依赖**：A2 + A3 + B1 + B2 + B3 + C1 + C2 + C3 全部完成

**做什么**：

1. `skills/insight-fuse/SKILL.md` line 3 frontmatter description：`v3.3` → `v3.4`，
   描述追加 `+ Stage 6.5 reviewer pass + 19 blocking checks (incl. LOAD_BEARING +
   calibration discipline)`
2. line 16 标题：`v3.3` → `v3.4`
3. line 18 增量段追加："v3.4 新增 Stage 6.5 reviewer pass / C18 Load-bearing
   cross-validation / C19 calibration discipline"
4. references 段 (line 269 附近) `quality-standards.md` 描述更新到 "19 blocking
   check 详述"

**验证命令**：

```bash
grep -E "^# Insight Fuse v3\.4 |description: \"Insight Fuse v3\.4" \
     skills/insight-fuse/SKILL.md
# 预期：≥ 2 行匹配（description + 标题）

grep "v3\.3" skills/insight-fuse/SKILL.md
# 预期：仅出现在历史增量说明段（"v3.3 新增多文件输出"），不应在 description / 标题
```

---

### Task D2 — 同步 platforms/openclaw/insight-fuse/

**依赖**：D1

**做什么**：

```bash
rsync -av --delete \
  skills/insight-fuse/ \
  platforms/openclaw/insight-fuse/
```

或等价 `cp -r` 后 `diff -r` 验证。

**验证命令**：

```bash
diff -r skills/insight-fuse/ platforms/openclaw/insight-fuse/
# 预期：空输出（byte-identical）

diff -rq skills/insight-fuse/ platforms/openclaw/insight-fuse/
# 预期：空输出
```

---

### Task D3 — 跑自检三命令 + skill-lint + marketplace hash

**依赖**：D2

**做什么**：

```bash
# 1. skill-lint
bash skills/skill-lint/scripts/skill-lint.sh .

# 2. 漏网扫描（确认所有 v3.3 → v3.4 已更新）
grep -rn "v3\.3" skills/insight-fuse/ platforms/openclaw/insight-fuse/ \
  --include="*.md"
# 预期：仅历史增量说明段保留 "v3.3"

# 3. marketplace.json hash 重算
bash scripts/recalc-all-hashes.sh

# 4. 平台镜像最终验证
diff -rq skills/insight-fuse/ platforms/openclaw/insight-fuse/
```

**验证命令**：

```bash
bash skills/skill-lint/scripts/skill-lint.sh . 2>&1 | grep -E "FAIL|ERROR"
# 预期：空输出（零失败）

bash scripts/recalc-all-hashes.sh 2>&1 | tail -5
# 预期：marketplace.json 已更新对应 hash 行（git diff 可见）

diff -rq skills/insight-fuse/ platforms/openclaw/insight-fuse/
# 预期：空输出
```

---

## Out of scope（留作 follow-up）

- Reviewer agent dry-run on 3 历史报告 ——本 RFC 落地后单独跑，结果不入仓库
- C18 / C19 advisory→blocking 阈值的运行期校准 ——5 份新报告后再调
- Reviewer prompt 在不同 research-type 下的细分调优 ——按 type 给 reviewer
  不同 prompt 模板（v3.5 候选）

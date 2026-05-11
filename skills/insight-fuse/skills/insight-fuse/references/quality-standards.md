# Report Quality Standards

Main agent 在落盘最终报告前跑 19 项 **blocking checks** + 6 维评分（v3.4 起）。Any blocking check 失败 → 重写对应段落，最多 2 轮，第 3 轮仍失败则输出并在 header 标 `QA-FAILED: <check-ids>`。

**分档执行**：
- C15 / C16 / C17 按 `--depth` + `--type` 组合决定 blocking 或 advisory（见 [research-types.md](research-types.md) §源可靠性分档）。
- C18 (LOAD_BEARING) 与 C15-C17 同档（`quick` advisory；`standard/deep/full` blocking on 不可替代单源；`market/academic` 一律 blocking）。
- C19 (Calibration discipline) 一律 blocking，所有 `--type` × `--depth`（vibes 数字代价低、风险高，不分档软化）。
- `quick` 模式对其他 type 全 advisory；`market` / `academic` 不论 depth 一律 blocking。

## 一、19 项 Mandatory Checks

| # | Check | Criterion | 失败处理 |
|---|-------|-----------|---------|
| 1 | Source density | 每 section ≥ 2 独立 citation | 补充来源或合并 section |
| 2 | Reference integrity | 所有 inline citation 在 reference list；无 orphan URL | 补齐 reference |
| 3 | Source diversity | 任一 section 内单源占比 ≤ 40% | 多样化引用或重写 |
| 4 | Evidence-backed claims | 比较/排序主张必有数据支撑 | 加 benchmark/数据 citation，或降级措辞 |
| 5 | Date line present | header 有 `> 日期：YYYY-MM-DD` | 补 date line |
| 6 | Attribution | footer 有 forge attribution block | 补 attribution |
| 7 | Environment isolation | 主体 + Appendix 无从执行环境推断的专名 | reject 未授权名；只允许来自：① 用户消息 ② `--focus` / `--audience` 参数值 ③ WebSearch/WebFetch 源内容 |
| 8 | Neutral body | 主体（首个 `---` 前）无针对性建议 | 检测正则（中英）：`对\s*\S+\s*(的)?建议\|给\s*\S+\s*(的)?启示\|对我们的启发\|为\s*\S+\s*(设计\|打造)\|启示录\|(advice\|recommendations?)\s+(for\|to)` — 命中即 reject，要求改写中立 Outlook |
| 9 | Advisory Appendix integrity | 若有 Appendix：`---` 起始 + 标题格式 + 3 行授权戳 + 6 节结构齐全 + `{audience}` verbatim + §2 全引主体 + §4 三列 | reject 该 Appendix 要求重写 |
| 10 | Source independence | ≥2 来源时在参考列表末追加 `独立性声明：...` 行，识别同源转引 | 补充声明；若全部同源，触发 Check 3 fail |
| 11 | Causal claim discipline | 因果断言列 ≥ 3 种替代解释 | reject 或降级为"相关/伴随/观察到" |
| 12 | **Framework preservation** | `skeleton.known_dissensus[i]` 每项在报告中渲染三段式（立场 A / 立场 B / 综合判断） | 套 `templates/disagreement-preservation.md` 重写；禁止合成共识 |
| 13 | **Structure-ratio compliance** | 各章节字数在模板声明比例 ±30% | 扩写/压缩对应 section |
| 14 | **FIR separation** | 每段首标 `[F]` / `[I]` / `[R]`；主体禁 `[R]` | 补标或下沉 `[R]` 到 Appendix |
| 15 | **Primary-source binding** | 每条量化声明（数字 / 百分比 / 日期 / 排名）的 EVIDENCE_CHAIN `support[]` 含 ≥1 条 L1 来源，且 URL 域名命中 [primary-source-whitelist.yaml](primary-source-whitelist.yaml) 中该 research-type 对应的白名单（或 `common` 段）；未命中域名降一级并标 `tier-uncertain` | reject 该声明；或降级为定性陈述（"大量资金涌入" 替代 "$X B"）；或补充一手源 |
| 16 | **Verbatim evidence snippet** | 每条量化声明对应 `SOURCES_USED` 条目须含 `quote:` 子字段（≥1 整句原文，含声明中的数字）+ 来源发表日期；正文同步渲染 `> 原文："..." — <Source>, <YYYY-MM-DD>` 紧邻段块 | 触发 WebFetch 回填原文；不可达则将该声明改 `content_support: placeholder` 并登记 GAPS_IDENTIFIED |
| 17 | **Numeric variance reconciliation** | 同一量化声明 `support[]` ≥ 2 条时，跨源数字差异 > 5% → 报告附录强制套 [templates/reconciliation-log.md](../templates/reconciliation-log.md)（一手源 tiebreak + 差异说明 + 最终采用值） | reject 声明；或写入 Reconciliation log |
| 18 | **Load-bearing cross-validation** *(v3.4)* | 同一 source（按 SOURCES_USED 条目去重，host 共享时按发布主体名）跨 ≥ 2 个 `## ` section 出现且承担 `[F]` 量化声明 → 标 LOAD_BEARING；每条 LOAD_BEARING source 必须 ≥ 1 条独立交叉验证（独立发布主体 + 独立方法 + 独立时间窗）；不满足且 source 不可替代时，对应 section 末插入 `> [SINGLE_SOURCE_RISK]: 本节论证关键依赖 <Source>，未找到独立交叉验证。` 注解 | 增加交叉验证源；或注解披露（advisory，不 block on `quick`） |
| 19 | **Calibration discipline** *(v3.4)* | 任意 `[F]` / `[I]` 段含 (a) 百分比 (b) `N/10` 评分 (c) "概率 X" / "可能性 X" 表述 → 必须紧跟 `{cal: <reference-class>}` 或 `{uncal}` 标注（详见 [research-protocol.md](research-protocol.md) §3.10）；TL;DR 与 Outlook 段（§1 + 末段 Outlook）禁止 `{uncal}` | reject 数字（要求加标注）；TL;DR 中 `{uncal}` 数字降级定性表述（"likely / unclear / unlikely"） |

Check 1-11 是 v2 保留；Check 12-14 是 v3 新增（Framework / Structure / FIR）；Check 15-17 是 v3.1 新增（源可靠性，起因于 2026-04 VC 数据扩散事件）；**Check 18-19 是 v3.4 新增**（LOAD_BEARING 跨节单源 + confidence 数字校准纪律，起因于 2026-04 三份 v3.x 报告横向 review 暴露的 cross-section 单源过载与 vibes-based confidence 现象）。

### 1.1 Evidence-Backed Claims Examples（Check 4）

需数据支撑的比较/排序表述：

- "X is faster than Y" → 必引 benchmark source
- "X leads the market" / "X ranks first" → 必引市场份额数据
- "X outperforms Y in Z" → 必引具体指标
- "most popular" / "widely adopted" → 必引采用数据或调研
- "more secure" / "more reliable" → 必引 CVE 统计、uptime、审计结果

✅ Acceptable：`[F] X reported 99.9% uptime ([Source](url)), compared to Y's 99.5% ([Source](url))`
❌ Not acceptable：`X is significantly more reliable than Y`（无数据）

### 1.2 Causal Claim Examples（Check 11）

触发扫描的关键词（中英）：`导致 / 使得 / 由 ... 造成 / because of / leads to / 驱动 / 触发 / causes`。

对每个触发点，报告必须二选一：

1. 列 ≥3 种替代解释（confounding / selection bias / reverse causation）并各附证据排除，**或**
2. 降级措辞为非因果（`观察到相关 / 伴随发生 / the two trends coincide`）

✅ Acceptable：
`[F] 2024-2026 全球客服岗位收缩 ≈ 12%（[来源 A](url)）；同期生成式 AI 客服部署率 +40%（[来源 B](url)）。`
`[I] **观察到相关**，但尚无 RCT 排除以下替代解释：(a) 经济周期下行、(b) 离岸外包持续、(c) 疫情后结构性调整。`

❌ Not acceptable：`AI leads to the layoffs` （未排除混淆因素）

### 1.3 Source Independence Examples（Check 10）

- 三个来源均追溯到 McKinsey 2024 某报告 → 视为单源，Check 3 fail
- 两个来源都是对同一 WSJ 报道的转载 → 视为单源
- 一个 SEC 披露 + 一个 Reuters 对该披露的报道 + 一个独立审计 → 独立性 2/3（Reuters 与 SEC 同源）

独立性声明示例：
`独立性声明：[A] 与 [B] 均引用 McKinsey 2024-Q3《全球 AI 报告》，视为同源；[C] 为独立 SEC 8-K 披露；有效独立来源 = 2。`

### 1.4 Framework Preservation（Check 12）

对 `skeleton.known_dissensus` 中每一项 `claim`，报告必须含完整三段式：

```markdown
#### <claim>

**立场 A**：<summary>
- 持方：<proponents>
- 证据：<evidence>
- 逻辑链：<F→I 推导>

**立场 B**：<summary>
- 持方：<proponents>
- 证据：<evidence>
- 逻辑链：<F→I 推导>

**综合判断**：
- 在 <条件 X> 下，立场 A 成立；在 <条件 Y> 下，立场 B 成立
- 或："证据不足以判定，需 <Z> 才能决断"
- **禁止**"取中间"或"两者都有道理"的模糊合成
```

Shell 校验：

```bash
count=$(yq '.known_dissensus | length' skeleton.yaml)
rendered=$(grep -c "^\*\*立场 A\*\*\|^\*\*Position A\*\*" report.md)
[ "$rendered" -ge "$count" ] || echo "Check 12 FAIL"
```

### 1.5 Structure-Ratio Compliance（Check 13）

各 template 在 frontmatter 或 header comment 声明章节目标比例，例如 technology：

```markdown
<!-- section ratios: 背景 10%, 对比 30%, 分析 35%, 风险 15%, 结论 10% -->
```

Stage 6 按 `## ` 切分 section 统计字数，每节偏离 ±30% 则 fail。

### 1.6 FIR Separation（Check 14）

每段必须以 `[F]` / `[I]` / `[R]` 起头。主体禁 `[R]`（仅允许在 Advisory Appendix）。详细语义见 [research-protocol.md](research-protocol.md) § FIR。

### 1.7 Primary-Source Binding（Check 15）

**"量化声明" 定义**：任何含 (a) 具体数字（金额 / 百分比 / 数量 / 增长率）、(b) 绝对日期或时间窗、(c) 排名 / 份额 / 榜单位次 的陈述。定性描述（"大规模"、"快速"、"领先"）不在此列。

**白名单匹配**：`support[]` 至少 1 条 URL 的 host 匹配 [primary-source-whitelist.yaml](primary-source-whitelist.yaml) 下：

1. `common.L1.domains`（SEC / arXiv / 官方立法 / DOI 期刊 / 原始公司披露）；**或**
2. `type_specific.<research-type>.L1.domains`（market: Crunchbase News / PitchBook / CB Insights / Dealroom；technology: RFC / 各厂商 docs 域；academic: arXiv / ACM / IEEE / Nature / Science；competitive: 对标公司官网 + SEC）

未命中白名单：

- 若 `support[]` 有其他 L1 条目 → 通过（但 tier 标 `tier-uncertain`）
- 若全部 L2-L5 → Check 15 fail

**分档执行**（由 [research-types.md](research-types.md) §源可靠性分档决定 blocking / advisory；本节只定义判据）：`quick` 默认 advisory；`standard` blocking；`deep` / `full` blocking；`market` / `academic` 一律 blocking。

**示例**：

✅ `[F] Q1 2026 全球 AI megadeal 融资 $239B（[Crunchbase News](https://news.crunchbase.com/...)）{P}`（Crunchbase News 在 market L1 白名单）

❌ `[F] Q1 2026 VC 总额 $300B（[TheBranx Blog](https://thebranx.com/...)）{P}` — TheBranx 非 L1，Check 15 fail

✅ `[I] 生态系统规模在扩张` — 定性，不触发 Check 15

### 1.8 Verbatim Evidence Snippet（Check 16）

**目的**：AI 幻觉最隐蔽的模式是"URL 真 + 数字假"——URL 可达但内容不支持声明。Verbatim quote 让人工可在 30 秒内 spot-check。

**结构要求**：

```markdown
[F] Q1 2026 全球 AI megadeal 融资 $239B，占全部 VC 81%（[Crunchbase News](https://news.crunchbase.com/...)）{P}
> 原文："AI startups raised a record $239 billion in Q1 2026, accounting for 81% of all venture funding." — Crunchbase News, 2026-04-03
```

quote 必须：

- 是源文档原文（不是改写 / 翻译 / 浓缩）——保留原语言即可
- 至少 1 整句，且**包含声明中出现的每一个具体数字**
- 附发表 / 检索日期（`YYYY-MM-DD`）
- 同时登记到对应 `SOURCES_USED` 条目的 `quote:` 字段（供解析器提取）

**回填规程**：Stage 3 Generalist 若某声明缺 verbatim → 强制 WebFetch 该 URL → 在原文中搜索数字 → 未找到则改 `content_support: placeholder` + 记入 GAPS_IDENTIFIED。禁止"凭 URL title 推测支持度"。

**分档**：`quick` advisory；`standard` advisory（可升 blocking 于 market/academic）；`deep` / `full` blocking。

### 1.9 Numeric Variance Reconciliation（Check 17）

**触发**：某量化声明 `support[]` ≥ 2 条，且不同来源返回的数字差异 > 5%（对数字）或跨类别（对排名 / 分类）。

**处理**：

1. 报告附录强制套 [templates/reconciliation-log.md](../templates/reconciliation-log.md)
2. 一手源 tiebreak：若 support[] 含 L1 则以 L1 为准
3. 若全 L1 仍冲突（口径差异）：正文采用较保守值 + 脚注标注范围 `"$239B (Crunchbase News 一手口径) - $285.5B (CB Insights 一手口径，含并购)"`
4. 同源追溯（Check 10 独立性）的二手源之间差异不触发 C17——本质是单源

**示例 Reconciliation log 段头**：

```markdown
## 附录 X — Reconciliation log

### Claim: Q1 2026 全球 AI 融资总额

| 来源 | URL | Tier | 原文数字 | 检索日期 |
|------|-----|:-:|-------:|---------|
| Crunchbase News（一手） | https://... | L1 | $239B | 2026-04-03 |
| CB Insights（一手，不同口径） | https://... | L1 | $285.5B | 2026-04-05 |
| TheBranx Blog（二手） | https://... | L5 | $300B | 2026-04-10 |

**采用值**：$239B（Crunchbase News 一手口径，排除并购）
**差异说明**：CB Insights 含 M&A，口径差 ~$46.5B；TheBranx 数字无原始口径声明，判定跨源糊合，排除。
```

**分档**：所有 `--type` 下一旦触发条件即 blocking；market / academic 额外要求 ≥ 2 条独立 L1 支撑主数字。

### 1.10 Load-Bearing Cross-Validation（Check 18，v3.4）

**问题域**：C15-C17 解决"单条声明的源可靠性"；**不解决**"同一来源跨多 sections 撑论证关节"。三份 2026-04 历史报告横向 review 中观察到：Anthropic measuring-agent-autonomy（4 sections）/ Apple EMNLP Mirage（5 sections）/ 智慧城市单聚合者（3 sections）/ 腾讯新闻 70-80% 闲置率（2 sections）——单点错则连锁松动，C15-C17 不会触发。

**LOAD_BEARING 判定**：

1. 按 SOURCES_USED 条目去重（host 共享但 entry name 不同 → 视为不同 source；跨条目 host 与发布主体相同 → 视为同 source 的多次引用）
2. 统计该 source 在多少个 `## ` section 出现 inline citation
3. 出现在 ≥ 2 个 sections 且**至少 1 个 section 有 `[F]` 量化声明引用该 source** → 标 LOAD_BEARING

**独立交叉验证判据**（与 [Check 10 Source independence](#13-source-independence-examples（check-10）) 链路一致）：

每条 LOAD_BEARING source 必须有 ≥ 1 条交叉验证 source，满足三项独立：

- **独立发布主体**：不是同一 issuer 的不同站点 / 子机构（Reuters 转引 SEC 披露**不算**独立）
- **独立方法**：不是同一调研方法的复制（两家机构都问同一组 CIO 的 survey **不算**独立）
- **独立时间窗**：发布日期相差 ≥ 30 天，避免对同一事件的同步报道集群

**判定结果**：

| 情形 | 行为 |
|------|------|
| LOAD_BEARING source 满足独立交叉验证 | C18 pass |
| LOAD_BEARING source 不满足，但 source 可替代（同信息维度有 L1 alternative） | C18 fail；返工补 alternative source |
| LOAD_BEARING source 不满足，且**不可替代**（领域内独家披露 / 唯一一手数据） | C18 advisory（不 block）；对应 section 末插入 `> [SINGLE_SOURCE_RISK]: 本节论证关键依赖 <Source>，未找到独立交叉验证。` 显式披露 |

**示例**：

✅ Acceptable：
`§3.2 [F] AI agent autonomy benchmark 显示 X 模型完成率 73%（[Anthropic measuring-agent-autonomy](url){P}）；DeepMind 2026 同期 SafetyBench 复测得 71%（[DeepMind blog](url){P}）。`
（两个 L1 一手源 + 独立发布主体 + 独立方法）

❌ Not acceptable（无注解）：
`§3.2 [F] AI agent autonomy 73%（[Anthropic blog](url){P}）`
`§5.1 [F] Agent 化趋势加速（[Anthropic blog](url){P}） + [Reuters 报道](url){S→Anthropic blog}`
（Anthropic 跨 §3.2 + §5.1 撑量化声明 + Reuters 同源转引——不算独立交叉；缺 SINGLE_SOURCE_RISK 注解）

✅ Acceptable（不可替代 + 注解披露）：
`§5.1 [F] Anthropic 内部数据：内部 dogfooding 团队完成率 89%（[Anthropic blog](url){P}）`
`> [SINGLE_SOURCE_RISK]: 本节内部数据论证关键依赖 Anthropic 自披露，未找到独立交叉验证（外部研究无法访问 Anthropic 内部 dogfooding 环境）。`

**自动化辅助**：[scripts/scan-load-bearing.sh](../scripts/scan-load-bearing.sh) 扫描合并报告，输出 LOAD_BEARING list；main agent 在 Stage 6.5 reviewer pass 前先跑该脚本，把输出作为 reviewer 输入的一部分。

**分档**：与 C15-C17 同档（`quick` advisory；`standard / deep / full` blocking on 不可替代单源；`market / academic` 一律 blocking on LOAD_BEARING 缺交叉验证）。

### 1.11 Calibration Discipline（Check 19，v3.4）

**问题域**：6-dim 评分中 transparency 维度已含"局限披露"语义，但**未约束数字本身的校准状态**。三份 2026-04 历史报告 TL;DR 出现 "H1 70-80%"、"H1 6/10"、"H4 8/10" 类数字——读者把它们当"已校准概率"读，但实际是直觉估计，无 base rate / reference class / 类似事件历史频率支撑。C4 (Evidence-backed) 只检查"是否有 citation"，C19 检查"数字本身是否被参考类锚定"。

**confidence 数字定义**（触发 C19 的表述类型）：

1. **概率 / 百分比附 confidence 框架**：`H1 70-80%`、`probability 60%`、`likely 65%`、`概率约 X`
2. **评分级数**：`N/10` 形态，例 `H1 6/10`、`confidence 8/10`、`置信度 7/10`
3. **概率词语**：`可能性 X`、`probability of Y`、`likelihood Z`

**纯统计百分比不触发**（属于 C4 + C15 范畴，不重复约束）——例如 "市场份额 35%" / "采用率 +12%" / "营收增长 8%" 是事实数字，不是 confidence 估计。**confidence 与事实的判断**：reviewer 看上下文——"H1 likelihood 70%" 是 confidence；"H1 市场份额 70%" 是事实。

**TL;DR / Outlook 段识别**：

- TL;DR：报告 §1（首节，金字塔结论先行）
- Outlook：报告末节，通常含 "展望 / 趋势 / Outlook / 预判 / 演进路径" 字样的章节

**这两段禁 `{uncal}`**——读者在这两段倾向把数字当作高置信结论；vibes 数字必须降级定性（"likely / unclear / unlikely / 可能 / 趋势倾向 X"）。

**示例**：

✅ Acceptable：
- `[I] §3 主体可包含 H1 6/10{uncal}`（明确承认是直觉估计，非 TL;DR）
- `[I] 五年规划落地概率约 70%{cal: OECD 同类 AI 政策五年达成率 N=14, [OECD 2025](url)}`（含 reference class + 锚点 citation）
- `[F] §1 TL;DR：核心趋势 likely 持续`（定性，不触发 C19）
- `[F] §1 TL;DR：H1 与 OECD 历史基线一致约 70%{cal: OECD N=14, [url]}`（cal 标注允许在 TL;DR）

❌ Not acceptable：
- `[F] §1 TL;DR：H1 70-80%`（数字无标注且在 TL;DR；C19 fail）
- `[I] §1 TL;DR：H4 8/10{uncal}`（uncal 在 TL;DR；C19 fail）
- `[I] H1 70%{cal: 直觉}`（reference-class 必须可外部验证；"直觉"不是有效参考类；C19 fail）

**Grandfathering**：v3.4 起强制；v3.3-及之前的报告**不**强制回溯改写。

**与 transparency 维度的协同**（[scoring-rubric.md](scoring-rubric.md) §一）：TL;DR 出现 `{uncal}` 数字 → transparency 维度自动 -1（与 C19 fail 联动；C19 fail 不单独封顶 Grade，但通过 transparency 降分间接影响 total）。

**分档**：所有 `--type` × `--depth` 一律 blocking（vibes 数字代价低、风险高，不分档软化）。

## 二、6 维正交评分

详细公式 + 权重表 + 等级映射见 [scoring-rubric.md](scoring-rubric.md)。

简要：

| 维度 | 含义 | academic 权重 | industry 权重 |
|------|------|:-:|:-:|
| falsifiability | Popper 可证伪 | 0.25 | 0.15 |
| evidence_density | 证据密度 | 0.20 | 0.15 |
| reproducibility | 可复现 | 0.20 | 0.10 |
| source_diversity | 来源多样 | 0.15 | 0.20 |
| actionability | 可行动 | 0.05 | 0.25 |
| transparency | 透明度 | 0.15 | 0.15 |

**等级**：A ≥ 8.5 / B 7.0-8.4 / C 5.5-6.9 / D < 5.5。**任一 blocking check 失败 → Grade 封顶 D**。

评分块模板固定插入报告 footer，例见 [scoring-rubric.md](scoring-rubric.md) §五。

## 三、Structure Requirements

- **Title**：`# <topic> 调研报告`
- **Date line**：`> 日期：YYYY-MM-DD | 基于多源信息综合分析`
- **Numbering**：major section 中文序数（一、二、三...），subsection 十进制（1.1、1.2）
- **Comparisons**：3+ 可比项用表
- **Deep sections**：Stage 5 段注明视角来源（`> 以下内容由 Insight Fuse 多视角分析综合产出`）
- **References**：拆 `### 基础调研来源` + `### 深度调研来源`（若有 Stage 5）
- **Language**：主体中文，技术术语 inline English；URL 保留英文
- **Skeleton reference block**：报告顶部（日期戳之后）含 skeleton 摘要：
  ```markdown
  > Skeleton: <topic-slug>-<date>.yaml | dimensions: <count> | known_dissensus: <count> | hypotheses: <count>
  ```

## 四、Quality Scoring Dimensions（Informational）

详见 [scoring-rubric.md](scoring-rubric.md) 的分段式评分表。以下仅供快速参考：

| Dimension | Low (1-3) | Medium (4-6) | High (7-10) |
|-----------|-----------|-------------|-------------|
| Source diversity | 1-3 来源 | 4-8 来源 | 9+ 来源 |
| Perspective balance | 单视角 | 主流+反面 | 多视角含 critic 异议 |
| Actionability (主体) | 仅描述 | 含 implication | Specific scenario-conditional outlook |
| Actionability (Appendix) | 通用建议 | 受众定制 | strategy-graded + 基于主体引用 |
| Depth | 表面概览 | 覆盖关键方面 | 技术细节 + 数据 + 分析 |

## 五、Advisory Audience Whitelist

**仅当 main agent 主动询问候选受众时**（full 模式交互 prompt，或 quick/standard/deep 报告末尾的"可选 advisory 命令"提示）使用。**不得**作为受众值来源——实际 `{audience}` 必须来自用户显式 `--audience` 或交互选定。

```
新入局者 / 现任头部 / 投资人 / 政策制定者 / 早期用户 /
开发者 / 架构师 / 产品设计者 / 企业客户 / 消费者 / 平台方
```

若用户提供白名单外的自定义受众（例如具体公司名 "小米" 或 whitelist 之外角色），输入即为授权凭据——verbatim 记入 Appendix 授权戳。**不得**自动从 topic 或调研结果扩展 whitelist。

## 六、Anti-Patterns

报告禁止包含：

- **Unsourced statistics**（例："market grew 50%" 无 citation）
- **Vague attribution**（"according to various sources"、"experts say"）
- **Single-source copy-paste**（始终 rewrite + synthesize from multiple sources）
- **Unresolved contradictions**（来源分歧时必须 both-position 显式呈现 + 证据）
- **Marketing language without substance**（"revolutionary"、"game-changing" 无数据）
- **主体中的针对性建议**：`[R]` 标记段只允许出现在 Advisory Appendix；主体出现"对 X 来说应该…"、"给 X 的启示"、"对我们的启发"、"为 X 设计"均越过中立边界
- **从执行环境推断受众**：CWD、附加目录、IDE 文件、历史对话不得作为 `{audience}` 来源
- **主体与 Appendix 混杂**：主体只描述事实与格局（允许 scenario-conditional 分析如"若 A 成立，赢家是 X 类玩家"，但禁止第二人称与特定组织称呼）
- **未授权状态下生成 Appendix**：`--audience` 未设置或 `--no-advisory` 为 true 时，报告不得出现任何 Appendix（包括空壳标题）
- **合成共识绕过 Disagreement Template**：对 `known_dissensus` 项写"两派都有道理"而不呈现完整三段式

## 七、Scope Isolation

insight-fuse 对执行环境严格隔离。详见 [research-protocol.md](research-protocol.md) § Scope Isolation。

**例外的白名单**：

- `--skeleton <path>` 导入的 YAML 文件内容
- `--audience` / `--focus` / `--perspectives` 等参数显式值
- 用户消息中出现的专名
- WebSearch/WebFetch 返回的源文本

其他一切（CWD、附加目录、IDE、CLAUDE.md 等）**禁止**作为主体或 Appendix 的输入。Check 7 扫描此约束。

# § Document Reading Template

Stage 3.5 输出。**评审隔离区**——连贯叙事性重读，与评审结果严格隔离。完整 narrative 写作纪律见 [references/narrative-discipline.md](../references/narrative-discipline.md)（6 条规则 + lint regex + few-shot 锚点）。

## 工作流隔离

```
            [Stage 1-3 中性扫描结果]
                    ↓
                    ↓ ← (输入边界)
                    ↓
       Stage 3.5 ─────→ § Document Reading ─→ FREEZE (hash snapshot)
                                                 │
                                                 ↓ (read-only ref)
       Stage 4 panel ─→ Stage 5 scores ─→ Stage 5.5 § Holistic Assessment

                       ✗ NEVER write back into § Document Reading
```

## 输入边界（MUST 严格）

✅ **接受**：
- 原文档 `source_view` / `canonical_view`
- Stage 1 结构审的事实结果（"frontmatter 缺失"、"H1/H2/H3 hierarchy 是 1-2-3"、"参考文献页存在于 p.42"）
- Stage 2 证据审的事实结果（"引用密度 = 3.2/section"、"L1 比例 = 0.6"）
- Stage 3 逻辑审的事实结果（FIR 标签出现位置、OOS 关键词列表、单源 claim 列表）

❌ **拒绝**：
- Stage 4 panel verdict / KEY_FINDINGS / FLAGS_RAISED
- Stage 5 任何分项分数 / 加权总分 / 字母 grade
- Stage 5/6 命中的 flag code
- 任何**质量评价语**（见下方"禁词清单"双向表）

> 区分原则：**事实**（"frontmatter 缺失"）vs **质量评价**（"frontmatter 不完整"）vs **interpretive 解读**（"报告把 frontmatter 当成元数据声明而非装饰"）。Stage 3.5 接受前者 + 后者，拒绝中者。

## narrative arc（5-9 段，按报告自身骨架递进）

### Para 1 — Contextual 开场（必有）

**遵循 Discipline 1**（[narrative-discipline.md §1](../references/narrative-discipline.md)）。Para 1 必含三件事：
1. **artifact 定位**——它是哪一类研究工件 + 由什么 engine / 在什么 depth 模式下编译
2. **核心 thesis 浓缩**——它在做什么 / 它**不是**在做什么
3. **报告自我边界**——退一步去做的那件"更有意义的事"是什么

**禁起手 pattern**（fail-closed regex）：
```
^这份报告(说|讲|提到|认为|声称) | ^本(报告|文章|文档)(说|讲|是|为)
^In this report,?\s+we | ^The report (states|argues|claims|finds)
```

**few-shot anchor**（详见 [narrative-discipline.md §1 Few-shot](../references/narrative-discipline.md)）：

> 这份报告本质上是一份"AI Native 全景总纲"的合并版——以 2026-04-17 全模式调研为底本，叠加 3 天后的刷新增量。它不是要给"AI Native"下一个权威定义，而是承认这个术语本身仍在收敛中，然后退一步去做更有意义的事…

### Para 2 — 核心论点浓缩（必有）

把全文论点压成 1-2 句 + 关键支撑曲线/枚举。允许使用 bold 强调论点眼。

例：
> 它的核心论点可以浓缩成一句话：**AI Native 不是某一项技术突破的产物，而是能力、成本、交互、基础设施这四条独立指数曲线在 2024-2026 年同步越过各自经济阈值之后涌现出的市场窗口。**

### Para 3..N-1 — 章节叙事串联（多段）

按报告自身的 §1 / §2 / ... / §N 自然递进，每段聚焦 1-2 个关键论证 + 数字 + 边界例 + 反例。**遵循 Discipline 4**（number-density）：

| 段类型 | numeric anchor 密度（每段） |
|---|---|
| 技术 / 证据 / 数据段 | 8-15 个 |
| Framing / posture 段 | ≤ 5 个 |

### Para N-1 — 关键张力段（必有 1-2 段）

报告里的关键分歧 / hypothesis falsification status / 自承空白。**遵循 Discipline 5**——限制条款必须前缀 `报告自承` / `§N 自承的` / `the report explicitly flags`：

例：
> 最值得读的是 H1（训练数据质量 > 模型规模主导）的处理——报告标"**未推翻但需重表述**"，把原假设里的"数据质量"主导因素改写为…并给出理由："数据'质量'作为 frequency 分布的间接 proxy，不应单列为独立主导因素"。

### Para N — Meta-reflective 收束（必有）

**遵循 Discipline 2**——末段必含 meta-reflective 标志短语之一：
```
整(份|体)读(下来|完) | 读完整份(.+)会发现 | 把(.+)并起来读会发现
posture | epistemic stance | 知识(姿态|承诺)
```

不得纯结论复读，必须对报告本身的姿态做 meta-评论：知识承诺、相对其他姊妹报告的位置、它选择**承认什么 / 守住什么 / 拒绝合成什么**。

例：
> 整体读下来，这份报告最值得保留的不是某个数字或某条结论，而是它的**态度**：它不急着把 AI Native 这个词钉死成定义，而是承认它正在演化，并用…这样层层嵌套的脚手架，把这个仍在流动的概念暂时固定成一张可被验证、可被反驳、可被刷新的地图。

## 引用要求（合并 Discipline 3 + 章节锚定）

| 类型 | 数量 | 渲染 | 模式 |
|---|---|---|---|
| Verbatim 引用 | 1-4 处 | `**...**` (zh) / `_..._` (en)，≤ 40 字 | 全文 ≤4 / 单段 ≤1 |
| 章节锚定 | ≥ 3 处 | `§X.Y` / `p.X` / `slide.N` / `L<line>` | 按 `target_format` 适配 |
| inline 外链 | ≥ 1 处 | `[text](url)` | 仅当源报告含外链时；若无则 skip |

**Verbatim 渲染禁用**（**fail-closed**）：
- ❌ block quote `>` 起行
- ❌ CJK 「」 引号
- ❌ 长 ASCII 双引号块
- ❌ 编号引用列表

位置标记按格式：

| target_format | 位置标记 |
|---|---|
| md / html / docx / odt | `§<sec-slug>` 或 `L<line>` 或 `§<heading-slug>` |
| pdf | `p.<page>` |
| pptx / odp | `slide.<n>` |
| txt / rtf | `L<line>` |

## 字数 / 段数

- 总字数：**1500-3500 字**（中英任一语种）
- 段数：**5-9 段**：
  - 短报告 → 5-6 段
  - **默认 → 7-8 段**
  - 长报告 → 9 段
- 嵌套 bullet **禁用**（叙述体；结构化条目留给 Stage 5+）
- 输出语言匹配源（**Discipline 6**）：源中文 → 中文叙事 / 源英文 → 英文叙事

## 禁词清单（lint 强制）

本节为**评审隔离**第三层防御。完整规则见 [references/document-reading-guard.md §第三层禁词 lint](../references/document-reading-guard.md)。

### ✅ ALLOWED — interpretive language（允许的轻度解读语）

| 类型 | 范例词 |
|---|---|
| 元解读 | 骨架性的 / 真正想交付的 / 最值得读的 / 最具骨架性 / 最反直觉 / 最具象的 / 最精彩 |
| 知识姿态 | 浓缩 / 收敛 / 摊开 / 拒绝合成 / 守住边界 / 诚实记录 / 知识承诺 |
| 章节聚焦 | 真正花力气的不是 X 而是 Y / 报告退一步去做 / 把 X 与 Y 的边界画得清晰 |

**判别准则**：interpretive（"最值得读的部分是 X"——指**读者关注重点**，是"报告说了什么"的延展）vs judgmental（"X 节做得不够好"——指**质量判断**，已涉评分系统语）。前者允许，后者禁。

### ❌ BANNED — judgmental about quality（fail-closed）

本节内 **MUST NOT** 出现：

- 质量评价（中文）：`优点 / 缺点 / 不足 / 薄弱 / 错误 / 缺陷 / 应当改 / 建议 / 强 / 弱 / 问题`
- 质量评价（英文）：`strong / weak(ness) / concern / issue / problem / shortcoming / fail / violate / better / worse`
- 评分系统词：`grade / score / flag`
- 字母 grade 字面量：`A+ / A / A− / A- / B+ / B / B− / B- / C+ / C / C− / C- / D`（评分语境下；纯引用原文标题"Section A"不算）
- Flag code 字面量：`F-EVD-NN / F-STAT-NN / F-LOGIC-NN / F-SCOPE-NN / F-COST-NN / F-METHOD-NN / F-DISAGREE-NN / F-CONSTRUCT-NN / F-CITE-NN / F-CONF-NN / F-DELTA-NN`（任意匹配 `F-[A-Z]+-\d+`）
- 评价节引用：`§ Score Matrix / § Flag List / § Multi-Perspective Panel / § Diff Suggestions / § Holistic Assessment` 及缩写形式（"the score matrix" / "as flagged"）

### Limitation discipline（Discipline 5 嵌入禁词体系）

报告的限制条款（OOS / coverage gap / hypothesis 未证实）必须前缀 `报告自承` / `§N 自承的` / `the report explicitly flags`；reviewer 自己引入的外部反驳必须显式声明 `这是外部观察，非报告主张`。**未加归因前缀的限制叙述视为污染评审-描述隔离**（warn-only）。

## 写后冻结（HARD）

Stage 3.5 完成后：

1. 主线程对 § Document Reading 全文计算 SHA-256，存入内存
2. Stage 4 / 5 / 5.5 / 6 期间不重写本节
3. Stage 7 归档前重新计算 hash，与 Stage 3.5 后快照对比：
   - 一致 → 归档
   - 不一致 → fail-closed：`Archive: blocked (Document Reading modified post-Stage 3.5)`，**不写文件**

> 写后冻结是用户硬约束的最后防线。架构隔离 + 写后冻结 + 禁词 lint 三层防御缺一不可。

## Stage 3.5 末尾自检（lint 摘要）

写完 § Document Reading 后，主线程对照 [references/narrative-discipline.md § Lint 模式总表](../references/narrative-discipline.md) 做 6 条 discipline 自检：

| 模式 | 规则 |
|---|---|
| **fail-closed** | Discipline 3 渲染禁用（block quote / 「」 / 编号引用）；评审隔离禁词（grade / score / flag / 字母 grade / `F-XXX-NN` / 评价节引用） |
| **warn-only**（初版） | Discipline 1 opening pattern；Discipline 2 closing meta-reflective；Discipline 3 数量/长度上限；Discipline 4 number-density 双峰；Discipline 5 限制条款归因；Discipline 6 输出语言匹配 |

warn 不阻断 Stage 4；fail-closed 触发 → 抛错 + 等待 reviewer 修复后重试。

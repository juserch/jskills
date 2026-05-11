# § Document Reading Review-Isolation Guard

**用户硬约束**："自成章节，不要让评审结果影响原文档的解读内容"。

本文件**集中**记录三层防御实现——架构隔离 / 写后冻结 / 禁词 lint。Stage 3.5 / 5.5 / 7 各自的实现细节散落在 [SKILL.md § Stage 3.5/5.5/7](../SKILL.md) 与 [templates/document-reading.md](../templates/document-reading.md) / [templates/holistic-assessment.md](../templates/holistic-assessment.md)；本文件作为**纵向汇总**，便于审计与未来回归测试。

## 第一层：架构隔离

Stage 3.5 § Document Reading 的**输入边界**严格管控：

| 输入类型 | 是否允许 | 说明 |
|---|:-:|---|
| 原文档 `source_view` / `canonical_view` | ✅ | reviewer 必须读 |
| Stage 1 结构审事实结果（"frontmatter 缺失"、"章节齐备"、"H1/H2/H3 hierarchy 1-2-3"）| ✅ | 中性数据 |
| Stage 2 证据审事实结果（"引用密度 = 3.2/section"、"L1 比例 = 0.6"）| ✅ | 中性数据 |
| Stage 3 逻辑审事实结果（FIR 标签出现位置 / OOS 关键词列表 / 单源 claim 列表）| ✅ | 中性数据 |
| Stage 4 panel `KEY_FINDINGS` / `FLAGS_RAISED` / `VERDICT_SUMMARY` | ❌ | 评价已成形 |
| Stage 5 任何分项分数 / 加权总分 / 字母 grade | ❌ | 评价已成形 |
| Stage 5 / 6 命中的 flag code（F-EVD-NN 等）| ❌ | 评价已成形 |
| Stage 5.5 § Holistic Assessment 任何内容 | ❌ | 评价已成形 |
| Stage 6 Diff Suggestions 任何内容 | ❌ | 评价已成形 |

**关键判别准则**：**事实**（"frontmatter 缺失"）vs **评价**（"frontmatter 不完整"）。前者描述事实可入；后者已含评价倾向不可入。

**实现位置**：[SKILL.md § Stage 3.5](../SKILL.md) "输入边界" 节（MUST 严格枚举）。

## 第二层：写后冻结

Stage 3.5 完成后立即冻结：

1. **快照**：Stage 3.5 输出节字节级 SHA-256 哈希存入主线程内存
2. **保护期**：Stage 4 / 5 / 5.5 / 6 期间 § Document Reading 节 read-only
3. **校验**：Stage 7 归档前重新计算哈希
4. **判决**：
   - 哈希一致 → 归档继续
   - 哈希不一致 → fail-closed：`Archive: blocked (Document Reading modified post-Stage 3.5)`，**不写文件**

**实现位置**：[SKILL.md § Stage 3.5 写后冻结](../SKILL.md) + [SKILL.md § Stage 7 归档前 hash 校验](../SKILL.md)。

## 第三层：禁词 lint（v0.2.0 起按 interpretive vs judgmental 双向清单）

§ Document Reading 节是**评审隔离区**——拒绝评分系统污染（grade / score / flag / 字母 grade），同时**允许 narrative-reading 风格的轻度解读**（"骨架性的"、"真正想交付的"、"最值得读的"、"诚实记录"）。完整 narrative discipline 见 [narrative-discipline.md](narrative-discipline.md)。

### 判别准则（v0.2.0 核心更新）

> 区分 **interpretive**（解读："最值得读的部分是 X"——指**读者关注重点**，仍是"报告说了什么"的延展）vs **judgmental**（评价："X 节做得不够好"——指**质量判断**，已涉评分系统语）。前者允许，后者禁。

具体差别：

| 类型 | 例 | Stage 3.5 |
|---|---|---|
| 事实描述 | "frontmatter 缺失" / "§5 自承的 coverage gap" | ✅ 接受 |
| Interpretive 解读 | "最值得读的是 X" / "报告真正想交付的不是 framework 而是 ..." | ✅ 接受（v0.2.0 新增） |
| Judgmental 质量评价 | "X 节做得不够好" / "this section is weak" | ❌ 拒绝 |
| 评分系统语 | grade / score / flag / `F-EVD-01` / `§ Holistic Assessment` | ❌ 拒绝 |

### ✅ ALLOWED — interpretive language（v0.2.0 新增正向清单）

| 类型 | 范例词 |
|---|---|
| 元解读 | 骨架性的 / 真正想交付的 / 最值得读的 / 最具骨架性 / 最反直觉 / 最具象的 / 最精彩 |
| 知识姿态 | 浓缩 / 收敛 / 摊开 / 拒绝合成 / 守住边界 / 诚实记录 / 知识承诺 |
| 章节聚焦 | 真正花力气的不是 X 而是 Y / 报告退一步去做 / 把 X 与 Y 的边界画得清晰 |

### ❌ BANNED — judgmental about quality（fail-closed）

#### 质量评价词汇

中文禁词：`优点 / 缺点 / 不足 / 薄弱 / 错误 / 应当改 / 建议 / 强 / 弱 / 问题 / 缺陷`
英文禁词：`strong / weak(ness) / concern / issue / problem / shortcoming / fail / violate / better / worse`

#### 评分系统词

`grade / score / flag`（纯名词；动词形式如 "the report grades sources" 在引用源报告原文时按上下文判定）

#### Flag code 字面量

任何匹配 `F-[A-Z]+-\d+` 的字符串。具体覆盖 11 个 category：`F-EVD-NN / F-STAT-NN / F-LOGIC-NN / F-SCOPE-NN / F-COST-NN / F-METHOD-NN / F-DISAGREE-NN / F-CONSTRUCT-NN / F-CITE-NN / F-CONF-NN / F-DELTA-NN`。

#### 字母 grade 字面量

`A+ / A / A− / A- / B+ / B / B− / B- / C+ / C / C− / C- / D` 在评分语境下不允许（exception：纯引用原文档标题如 "Section A" 不算；引用源报告自评 grade 如 "自评 B+ (7.8/10)" 在被评报告本身 frontmatter 含 grade 字段时按 verbatim 引用允许，但 reviewer **不得**在自己叙述中重新引用）。

#### 评价节引用

不得出现这些字符串作为节引用：
- `§ Score Matrix`
- `§ Flag List`
- `§ Multi-Perspective Panel`
- `§ Diff Suggestions`
- `§ Holistic Assessment`
- 缩写形式如 "the score matrix"、"as flagged"

### Narrative discipline lint（v0.2.0 新增 6 条）

[narrative-discipline.md](narrative-discipline.md) 定义 6 条 narrative 写作纪律的 lint regex：

| Discipline | 模式 |
|---|---|
| 1 Opening pattern（禁`^这份报告说`等起手） | warn-only |
| 2 Closing meta-reflective（必含`整体读下来`等短语） | warn-only |
| 3 Verbatim 渲染禁用（block quote `>` / 「」 / 编号引用） | **fail-closed** |
| 3 Verbatim 数量上限（全文 ≤4 / 单段 ≤1） | warn-only |
| 4 Number-density 双峰（技术段 8-15 / framing 段 ≤5） | warn-only |
| 5 Limitation 归因前缀（`报告自承` / `§N 自承的`） | warn-only |
| 6 Output language matches source | warn-only |

**初版策略**：Discipline 3 渲染禁用 + 评审隔离禁词 = fail-closed（污染严重）；其余 = warn-only（收集 false-positive 后再升级）。

**实现位置**：
- 主线程在 Stage 3.5 末尾自检（按 [narrative-discipline.md § Lint 模式总表](narrative-discipline.md) 跑 regex）
- [evals/peer-fuse/run-trigger-test.sh § Phase H](../../../evals/peer-fuse/run-trigger-test.sh) 校验模板自身文档化禁词清单关键词存在
- 可选迁移到 skill-lint 自定义规则

## 三层防御缺一不可

- **架构防错**（第一层）：防的是工程错误（管道写错，把 panel verdict 灌进 Stage 3.5）
- **冻结防漂**（第二层）：防的是 LLM 幻觉/工具误用（Stage 5.5 主线程"顺手改一下"§ Document Reading）
- **禁词防污**（第三层）：防的是语言污染（即使没改章节内容，措辞含 "concerning" 这种隐蔽评价也会污染）

任何一层失守 → § Document Reading 不再"纯描述"。三层共同保证用户硬约束的实质满足。

## 与 IF Stage 6.5 reviewer 的对比

IF Stage 6.5 `insight-reviewer` 也有"隔离输入"：reviewer 仅读最终报告 + 19 checks 定义 + 6 dims rubric + `--type` / `--depth` 参数，**禁读** `skeleton.yaml` / `SOURCES_USED` / `EVIDENCE_CHAIN` / Stage 5 草稿 / Stage 6 author 6-dim 自评分（[skills/insight-fuse/SKILL.md:193](../../insight-fuse/SKILL.md#L193)）。

peer-fuse Stage 3.5 的隔离方向**相反**：IF Stage 6.5 隔离的是 reviewer **输入侧**（防 reviewer 被作者 self-eval 污染），peer-fuse Stage 3.5 隔离的是 reviewer **某一节内部**（防同一 reviewer 在写解读时被自己后续要写的评审污染）。两者都解决"评价侧污染描述侧"问题，但作用域不同。

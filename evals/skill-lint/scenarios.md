# Skill Lint 评估场景

验证 skill-lint 校验工具是否按预期工作的测试场景。

## 场景 1: 基础激活

**输入**: `/skill-lint`
**期望**: 输出激活表格，包含结构检查和语义检查两行

## 场景 2: 校验当前项目

**输入**: `/skill-lint .`
**期望**: 运行 bash 结构检查 + AI 语义检查，输出合并结果表格

## 场景 3: 校验指定路径

**输入**: `/skill-lint /path/to/other/plugin`
**期望**: 对指定路径执行完整校验流程

## 场景 4: 检测缺失 SKILL.md

**设置**: 存在 `skills/broken/` 目录但无 SKILL.md
**期望**: 结构检查报 error — `S03: skills/broken/SKILL.md missing`

## 场景 5: 检测 frontmatter 缺失字段

**设置**: SKILL.md 存在但 frontmatter 中缺少 `description`
**期望**: 结构检查报 error — `S04: missing required field 'description'`

## 场景 6: 检测断链 references

**设置**: SKILL.md 中引用了 `references/nonexistent.md` 但文件不存在
**期望**: 结构检查报 error — `S07: referenced but file missing`

## 场景 7: 检测 marketplace.json 缺失条目

**设置**: skill 目录存在但未在 marketplace.json 的 plugins 数组中
**期望**: 结构检查报 warning — `S06: not listed in marketplace.json`

## 场景 8: 语义检查 — name 与目录名不一致

**设置**: `skills/foo/SKILL.md` 的 frontmatter name 为 `bar`
**期望**: 语义检查报 warning — name 与目录名不一致

## 场景 9: 语义检查 — description 质量差

**设置**: SKILL.md 的 description 为 "A skill"（过于模糊）
**期望**: 语义检查报 warning — description 不够清晰

## 场景 10: 全部通过

**设置**: 完整合规的 skill 项目（含 .skill-lint.json）
**期望**: 结构检查和语义检查全部 passed，无 errors 和 warnings

## 场景 11: 无 .skill-lint.json — 通用模式

**设置**: 一个标准 Claude Code plugin 项目，无 .skill-lint.json
**期望**: 只执行 S01-S08 Core 规则，不报 S09-S15 相关的 errors 或 warnings

## 场景 12: 部分配置 — 只启用命名和分类

**设置**: .skill-lint.json 只含 `naming-pattern` 和 `category-values`，不含其他字段
**期望**: S09 和 S10 执行，S11-S15 不执行

## 场景 13: 自定义 category 值

**设置**: .skill-lint.json 中 `category-values` 为 `["core", "util", "experimental"]`
**期望**: S10 按自定义值校验，不报 Forge 的 hammer/crucible/anvil/quench

## 场景 14: 多平台配置

**设置**: .skill-lint.json 中 `platforms` 为 `["openclaw", "gemini"]`
**期望**: S14 分别检查 `platforms/openclaw/` 和 `platforms/gemini/` 下的适配文件

---

## v1.2 新增场景（S27 / S28）

## 场景 15: S27 watchlist 命中且无其他引用 → warn

**设置**: 临时在 SKILL.md 末尾追加 "本 skill 与 flarp 环境集成"，且 repo 内无任何文件提及 `flarp`
**期望**: S27 不报 warn（因为 `flarp` 不在 watchlist；S27 是 white-list 模式）

## 场景 16: S27 watchlist 命中且有其他引用 → 通过

**设置**: SKILL.md 含 `openclaw`，且 platforms/openclaw/ 等其他位置也提及 `openclaw`
**期望**: S27 不报 warn（命中但有其他引用）；passed 列表含 `S27: All watchlist terms in SKILL.md have repo-wide references`

## 场景 17: S27 watchlist 命中但无任何其他引用 → warn（合成测试）

**设置**: 临时把 SKILL.md 改为含 `clawhub`（在 watchlist 中），并临时把 repo 内**所有**其他 `clawhub` 提及改名（或在干净 fixture 中只让该 SKILL.md 含此 term）
**期望**: S27 报 warn — `S27: skills/<name>/SKILL.md mentions 'clawhub' but no other reference exists in repo (potential ambiguity)`

## 场景 18: S28 hook owner skill 缺平台镜像 → error

**设置**: `skills/claim-ground/hooks/` 存在，`.skill-lint.json` 含 `"openclaw"`，但 `platforms/openclaw/claim-ground/hooks/openclaw/` 不存在
**期望**: S28 报 error — `S28: skills/claim-ground has hooks/ but platforms/openclaw/claim-ground/hooks/openclaw/ missing`

## 场景 19: S28 platform 镜像 HOOK.md events 字段为空 → error

**设置**: `platforms/openclaw/claim-ground/hooks/openclaw/prompt-gate/HOOK.md` 存在但 frontmatter `events: []`
**期望**: S28 报 error — `S28: HOOK.md events field is empty`

## 场景 20: S28 平台无等价 hook 系统的豁免

**设置**: `.skill-lint.json` 含 `"docsite"`（假想纯文档平台），且 `platforms/docsite/claim-ground/SKILL.md` 的 `## 平台 hook 等价位置` 段含 "无等价机制可用" 文本
**期望**: S28 不报 error（豁免触发）

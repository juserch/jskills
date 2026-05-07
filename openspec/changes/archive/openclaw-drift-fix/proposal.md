# Openclaw Drift Fix — 5 Help mirror + schema-template + skill-lint mirror + description policy

> 这次 change 解决的张力:`version-governance` 落地后 openclaw mirror 留下了一批可观测的飘移——5 个 mirror 缺 `## Help` 段、tome-forge schema-template 内容飘移、skill-lint mirror 缺 S29/S30/S31、claim-ground description platform-aware 措辞与 platform-parity spec L60 字面"MUST 同步"约定相冲突。

## Why

`version-governance` change 把 SSOT(marketplace.json plugins[].version)与 lint(S29/S30/S31)落到 canonical,但 platforms/openclaw/ 镜像没跟上。3 份 Explore 探查 + 后续 verify 的事实:

1. **5 个 openclaw mirror 缺 `## Help` 段**:[platforms/openclaw/{block-break,council-fuse,news-fetch,ralph-boost,skill-lint}/SKILL.md](../../../platforms/openclaw) 都没有 Help 段,用户在 openclaw 上跑 `/skill help` 看不到指南。canonical 已全 8 个有 Help 段。

2. **tome-forge openclaw schema-template 内容飘移**:[platforms/openclaw/tome-forge/references/schema-template.md](../../../platforms/openclaw/tome-forge/references/schema-template.md) 比 [skills/tome-forge/references/schema-template.md](../../../skills/tome-forge/references/schema-template.md) 少 ~397 字节——缺 "Maturity Transitions" 整段(draft / growing / stable / deprecated 状态机)、`raw/reports/` 目录引用、几处字段描述精化。

3. **openclaw skill-lint 缺 S29/S30/S31**:[platforms/openclaw/skill-lint/scripts/skill-lint.sh](../../../platforms/openclaw/skill-lint/scripts/skill-lint.sh) 仅 806 行,canonical [skills/skill-lint/scripts/skill-lint.sh](../../../skills/skill-lint/scripts/skill-lint.sh) 1017 行——缺 ~190 行 S29/S30/S31 python heredoc + 3 个 CFG 变量 + 3 个 .skill-lint.json key 解析。

4. **description platform-aware 措辞 vs spec 字面"MUST 同步"**:[openspec/specs/platform-parity/spec.md L60](../../../openspec/specs/platform-parity/spec.md#L60) 写"MUST 同步",但 [platforms/openclaw/claim-ground/SKILL.md L3](../../../platforms/openclaw/claim-ground/SKILL.md#L3) description 合理地用 openclaw `message:received / agent:bootstrap` 替代 canonical 的 Claude Code 五 hook 名,这是 platform-aware 适配,不是飘移。spec 严格读会判 violation,需要放宽。

## What Changes

**4 项执行**:

- **G2 lint mirror sync**:把 canonical [skills/skill-lint/scripts/skill-lint.sh](../../../skills/skill-lint/scripts/skill-lint.sh) 同步到 [platforms/openclaw/skill-lint/scripts/skill-lint.sh](../../../platforms/openclaw/skill-lint/scripts/skill-lint.sh)(byte-identical 覆盖),让 openclaw mirror 也带 S29/S30/S31 + 3 CFG 变量。
- **G3 5 个 Help 段补齐**:为 [platforms/openclaw/{block-break,council-fuse,news-fetch,ralph-boost,skill-lint}/SKILL.md](../../../platforms/openclaw) 补 `## Help` 段;每段第一行格式 `<Skill Name> v<X.Y.Z> — <tagline>`(由 S30 校验,X.Y.Z = marketplace.json 对应 plugin version)。
- **G4 schema-template sync**:把 canonical [skills/tome-forge/references/schema-template.md](../../../skills/tome-forge/references/schema-template.md) byte-identical 覆盖到 [platforms/openclaw/tome-forge/references/schema-template.md](../../../platforms/openclaw/tome-forge/references/schema-template.md)。
- **D1 platform-parity spec 放宽**:在本 change 的 [specs/platform-parity/spec.md](specs/platform-parity/spec.md) MODIFIED Requirement,把 description "MUST 同步"放宽为"语义/范畴 MUST 一致;允许 platform-specific wording 反映本平台实际事件名 / 工具名 / 命令名,SHALL NOT 引入 canonical 不存在的能力声明"。

**1 项沉淀**:

- 新增 [docs/design/cross/openclaw-capability-gap-design.md](../../../docs/design/cross/openclaw-capability-gap-design.md),作为长期参考——含 OpenClaw runtime 一句话定义、五 hook → openclaw event 对照表、8 skill 镜像状态矩阵(post-fix)、by-design 适配清单(council-fuse / ralph-boost / block-break / claim-ground 各自 by-design 段引用)、永久豁免列表(PreToolUse / PostToolUse 在 openclaw 无等价)、后续 follow-up 路径。

## Non-goals

- **G5 block-break / claim-ground 待镜像 hook handlers** — 涉及编写 TypeScript handler.ts + 编译 .js 产物(frustration-trigger via message:received,session-restore via agent:bootstrap),工作量 1-2 天,留独立 RFC `block-break-openclaw-hooks`。
- **G1 claim-ground openclaw filesystem 权限飘移** — 已在 `version-governance` change 范围内修复(read-only → read-write,tools 加 Write),不在本 change 重复。
- **永久豁免列表正式沉淀(D2)** — design doc 引用为参考,正式 spec-level 豁免清单走独立 RFC `openclaw-permanent-exemptions`。
- **S32 platform-content-parity lint** — content drift 自动检查,跑独立 RFC `platform-content-drift`。
- **集合级 plugin.json 升级政策** — 见 `version-governance` 的 follow-up `collection-version-policy`。
- **byte-identical 镜像政策跨 skill 推广** — 仅 insight-fuse 现行如此(trigger test enforced),其他 skill 不强制。

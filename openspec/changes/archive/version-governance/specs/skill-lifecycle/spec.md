# Skill-Lifecycle Spec Delta — Version bump 触发规则(场景 B 增补)

> **架构注释(2026-05-07 修订)**:本 delta 早期版本曾把 SKILL.md frontmatter `version:` 字段定为 SSOT。架构 pivot 后,**SSOT 移到 `.claude-plugin/marketplace.json` `plugins[].version`**,SKILL.md frontmatter 不持有 version。bump 决策的所有同步操作目标为 marketplace.json + help-card + CHANGELOG.md(详见 [repo-invariants delta](../repo-invariants/spec.md))。

## ADDED Requirements

### Requirement: 修改 skill 时 MUST 按 SemVer 2.0.0 决策版本位

[openspec/specs/skill-lifecycle/spec.md § 场景 B — 修改 skill](../../../specs/skill-lifecycle/spec.md) 在每次 PR 合入前 MUST 答:"本 PR 是否需要 bump 版本?bump 哪一位?"

bump 决策依据 SemVer 2.0.0 语义,映射到 forge skill 行为如下:

| 改动类别 | 触发条件(任一即满足) | 版本位 |
|---|---|---|
| **MAJOR**(X.y.z) | 删除/重命名一条红线;改 hook 触发条件不向后兼容;删除/重命名 frontmatter 必填字段;删除/重命名 user-invokable 命令的子命令;改 references protocol 不向后兼容 | 升 X,y/z 归零 |
| **MINOR**(x.Y.z) | 新增 hook surface;新增 flag / 子命令;新增 stage / check / red line;扩展 references 段落引入新行为;行为强化(如 archival 从可选变必须) | 升 Y,z 归零 |
| **PATCH**(x.y.Z) | 修 typo / 排版 / 链接修复;refactor 不影响行为;改 references 末尾历史叙述;本 SKILL.md 与平台镜像同步对齐 | 升 Z |

无行为意义的改动(仅改 commit message / openspec/changes 目录内文件 / docs/i18n 翻译同步无新事实)SHALL 不 bump。

bump 决策的判定权属于改动作者,但 reviewer SHOULD 在 PR review 中复核版本位与改动清单是否匹配。skill-lint 不检测语义层面(无法机器判定 PATCH vs MINOR),但 S29/S30/S31 强制 bump 后 marketplace.json + help-card + CHANGELOG 三处字面量同步。

#### Scenario: MINOR 案例——新增 hook surface

- **WHEN** 给 `claim-ground` 加入 `prompt-gate` / `pre-tool-gate` 两个 hook(archived [2026-05-06-claim-ground-failure-mode-defense](../../archive/2026-05-06-claim-ground-failure-mode-defense/) 的实际改动)
- **THEN** version bump 为 MINOR:`1.1.0 → 1.2.0`
- **AND** `.claude-plugin/marketplace.json` `claim-ground.version` 升至 `1.2.0`
- **AND** `skills/claim-ground/SKILL.md` `## Help` 段 code block 第一行更新为 `Claim Ground v1.2.0 — ...`
- **AND** `/CHANGELOG.md` `## claim-ground` 段顶部插入 `### [1.2.0] — 2026-05-06` 条目,引用 archived RFC

#### Scenario: MINOR 案例——insight-fuse 新增 Stage 6.5 reviewer pass

- **WHEN** [insight-fuse-v3-4-self-review-and-calibration](../../insight-fuse-v3-4-self-review-and-calibration/proposal.md) 在 8 阶段流水线中追加 Stage 6.5、追加 C18/C19 两条 blocking check
- **THEN** version bump 为 MINOR:`3.3.0 → 3.4.0`
- **AND** marketplace.json + help-card + CHANGELOG 三处版本字面量在合并 PR 时同步升级
- **AND** 当前已观测到的飘移(marketplace 仍是 3.3.0)SHALL 由本 version-governance change 一次性修正

#### Scenario: PATCH 案例——纯文档修复

- **WHEN** 仅修改 `skills/news-fetch/references/sources.md` 的链接 typo,无任何行为变化
- **AND** `skills/news-fetch/SKILL.md` 未被改动
- **THEN** version 不必 bump(SKILL.md 自身未变 = hash 不变 = 无需 PATCH)
- **AND** 若同时改了 SKILL.md(如修同段 typo),SHOULD bump PATCH `1.1.0 → 1.1.1`

#### Scenario: MAJOR 案例——删除红线

- **WHEN** 在 `claim-ground` 中删除 R7(术语凭印象红线)
- **THEN** version bump 为 MAJOR:`1.2.0 → 2.0.0`
- **AND** 删除红线属于"使用方依赖被破坏"——曾经依赖 R7 检测的 callsite 行为变化
- **AND** PR description SHALL 显式列出破坏性变更清单(已 grep 出的 callsite 与影响)

### Requirement: skill-lifecycle 场景 B 审计清单 MUST 含 version 决策项

修改 skill 时,审计清单(已存在的同步项之外)SHALL 追加:

- [ ] 决策版本位(MAJOR / MINOR / PATCH / 不 bump),并在 PR description 简述理由
- [ ] 若 bump:同步 `.claude-plugin/marketplace.json` `plugins[].version` + `skills/<n>/SKILL.md` `## Help` 段 code block 第一行版本字面量 + `/CHANGELOG.md` `## <n>` 段顶部插入新 `### [X.Y.Z]` 条目
- [ ] 若 bump 且 `platforms/<p>/<n>/SKILL.md` 含 Help 段:同步 platform mirror help-card 第一行版本字面量(详见 [platform-parity delta](../platform-parity/spec.md))
- [ ] 跑 `bash scripts/recalc-all-hashes.sh && bash skills/skill-lint/scripts/skill-lint.sh .` 确认零 fail

#### Scenario: 修 typo 不 bump 的合法路径

- **WHEN** 改 `skills/tome-forge/SKILL.md` 一行错别字
- **AND** PR description 写明"PATCH-eligible 但作者评估为不 bump(typo only,无行为)"
- **THEN** lint 不强制 bump(marketplace.json 不变,help-card / CHANGELOG 也不变)
- **AND** marketplace.json 仅需更新 `integrity.skill-md-sha256`(recalc 脚本职责)

#### Scenario: 漏 bump 的修复路径

- **WHEN** 某 PR 实质性修改了 SKILL.md 行为但未 bump marketplace.json version
- **AND** S29/S30/S31 通过(因 marketplace 与 help-card / CHANGELOG 仍字面量一致)
- **THEN** reviewer 在 PR review 中 SHOULD 指出版本位决策缺失
- **AND** 后续修复 PR SHALL 同步升 marketplace.json + help-card + CHANGELOG 三处版本号
- **AND** 不允许只升 help-card 不升 marketplace(违反 SSOT 方向)

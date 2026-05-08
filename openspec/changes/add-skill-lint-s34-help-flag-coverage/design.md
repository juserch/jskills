# Design — add-skill-lint-s34-help-flag-coverage

影响分类：**anvil**（skill-lint 自身的能力升级，OUTPUT 仍是 pass/fail/warn 控制台诊断）。

## 设计决策

### 1. Severity = warn（不是 error）

- **选了什么**：warn 三态之一
- **为什么不是 error**：当前 4 个已知问题未修；S34 直接 error 会让所有 PR 红，包括与 help card 无关的工作；warn 既能输出可见诊断，又不阻塞工作流
- **为什么不是 off**：off = 不查；本 change 的目的就是把问题暴露出来推动修复
- **未来升级路径**：[follow-up RFC `fix-help-card-flag-coverage`](../) 修完所有 skill 后，同 PR 升级到 error；自此 S34 与 S29/S30/S31 同一刚性级别
- **三态配置一致**：与 [.skill-lint.json](../../../.skill-lint.json) 现有 `verify-docs-version-drift: warn` / `require-help-section: warn` / `verify-archived-spec-merge: warn` 同一过渡期模式

### 2. Argument-hint flag 抽取规则

正则：`/--[a-z][a-z0-9-]+/`（只匹配 `--lower-kebab` 格式 flag）。

豁免列表（不计入 hint flag 集合）：

- 子命令枚举语法：`[setup|run|status|clean]`（ralph-boost）/ `[init|ingest|...]`（tome-forge）— 这些是位置参数选项，不是 flag
- 子命令子参数语法：`[args...]`（tome-forge 用于兜底）

实现位置：[skills/skill-lint/scripts/skill-lint.sh § S34](../../../skills/skill-lint/scripts/skill-lint.sh)（Python 子进程 + regex）。

### 3. Help card 抽取规则

定义"help card 体"= SKILL.md `## Help` H2 节内**第一个**三个反引号 code block 的全部内容（不含 fence 标记）。

**抽取位置**：

- canonical：`skills/<skill>/SKILL.md`
- platform mirror：`platforms/<plat>/<skill>/SKILL.md`（仅当含 `## Help` 段时检查；否则跳过该 mirror）

**flag 检测**：与 hint 同 regex `/--[a-z][a-z0-9-]+/`。

**为什么取第一个 code block**：help-mode/spec.md 模板 A/B 的 help card 都是单一 fenced 块；多 block 的 skill（如 ralph-boost、tome-forge）后续 block 是 Examples 区，不是 help card 本体。

### 4. 子命令模式豁免

判据：argument-hint **不含**任何 `--flag` 模式 → 整体豁免 S34 检查（只检子命令的 skill）。

适用：

- ralph-boost: `[setup|run|status|clean]` — 0 flag
- block-break/claim-ground/skill-lint: 无 argument-hint 字段 — 0 flag

```python
hint_flags = re.findall(r"--[a-z][a-z0-9-]+", hint or "")
if not hint_flags:
    return  # skip S34 for subcommand-only skills
```

### 5. 与现有 lint 规则的隔离

- 不重写 S29/S30/S31 的版本治理 Python 块（它们在同一 sub-process 里，已 600+ 行）
- S34 单独的 Python 子进程，便于隔离失败 + 独立超时控制
- 与 S25 (`require-help-section`) 协作：S25 检查 Help 段存在性，S34 检查 Help 段内容覆盖率；S25 失败时 S34 跳过该 skill（避免重复报错）

### 6. CHANGELOG backfill

skill-lint 当前 [marketplace.json version: "1.0.0"](../../../.claude-plugin/marketplace.json) 但代码已含 S29-S33（commit `cf79b1d` 加 S29-S31，commit `f0a91e9` 加 S32-S33）。

修复策略：

- v1.1.0 entry 同时声明 S29-S34 五条新规则（5 条都首次进 CHANGELOG）
- 不分 5 个 micro-version 倒补（破坏性低、信息密度高且追历史无意义）

## 受影响清单

- **新增**：[openspec/changes/add-skill-lint-s34-help-flag-coverage/](.)（本 change 三件套）
- **修改**：
  - `.skill-lint.json`：新增 `verify-help-card-flag-coverage: "warn"`
  - `skills/skill-lint/scripts/skill-lint.sh`：新增 S34 实现
  - `skills/skill-lint/references/rules.md`：S34 规则文档
  - `platforms/openclaw/skill-lint/scripts/skill-lint.sh` + `references/rules.md`：mirror 同步
  - `.claude-plugin/marketplace.json`：skill-lint version 1.0.0 → 1.1.0 + hash 重算
  - `CHANGELOG.md`：skill-lint v1.1.0 entry（含 S29-S34 backfill）
  - `skills/skill-lint/SKILL.md` + `platforms/openclaw/skill-lint/SKILL.md`：help card 第一行 v1.0.0 → v1.1.0
- **不动**：8 个其它 skill 的源码（包括有 help card 漏列问题的 4 个）；help-mode spec；任何 skill 的 description / examples 段

## Verification

```bash
# 1. 静态校验自身仍 PASS
bash skills/skill-lint/scripts/skill-lint.sh .

# 2. S34 应输出 4 条 warning（暴露 4 个已知问题）
bash skills/skill-lint/scripts/skill-lint.sh . | python3 -c "
import json, sys
d = json.load(sys.stdin)
warnings = [w for w in d.get('warnings', []) if w.startswith('S34:')]
print(f'S34 warnings: {len(warnings)}')
for w in warnings: print(' ', w)
"
# 期望:
#   S34 warnings: 4 (or more)
#   - council-fuse SKILL.md missing --no-save in help card
#   - insight-fuse SKILL.md missing --skeleton, --perspectives, --focus, --audience, --strategy, --no-advisory, --no-save in help card
#   - news-fetch SKILL.md missing --no-save in help card
#   - (block-break 因无 argument-hint 字段 → 子命令模式豁免，不报)
```

S34 不应报 peer-fuse / ralph-boost（已合规）和 block-break / claim-ground / skill-lint（无 argument-hint 字段豁免）。

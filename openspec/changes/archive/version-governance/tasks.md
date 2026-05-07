# Tasks

> **架构注释(2026-05-07 修订)**:本 tasks 早期版本曾包含"为 16 个 SKILL.md frontmatter 注入 `version:` 字段"的 Task 2 / Task 9。架构 pivot 后(因 Claude Code 官方 schema 拒绝 `version` frontmatter 字段),那两个 Task 已废弃,被新的 Task 2 "frontmatter regression guard" 替代。本 tasks 反映 pivot 后的最终执行序列。

## Task 1 — 写入 4 份 spec delta

**依赖**:无

**做什么**:

新建 4 份 spec delta:

- `openspec/changes/version-governance/specs/repo-invariants/spec.md` —— ADDED Requirements:
  - SKILL.md frontmatter MUST NOT 含 `version` 字段(regression guard,Claude Code schema 限制)
  - SSOT = `marketplace.json plugins[].version`(SemVer 2.0.0)
  - marketplace integrity 锁步范围含 hash 与 version
  - 仓库根 MUST 持有 `/CHANGELOG.md`,各 skill 段 top entry 等于 marketplace SSOT
- `openspec/changes/version-governance/specs/skill-lifecycle/spec.md` —— ADDED Requirements:
  - 修改 skill 时 MUST 按 SemVer 2.0.0 决策版本位
  - bump 操作目标:marketplace.json + help-card + CHANGELOG 三处同步
- `openspec/changes/version-governance/specs/help-mode/spec.md` —— MODIFIED Requirements:
  - help card 模板 A/B code block 第一行 MUST 是 `<Skill Name> v<X.Y.Z> — <tagline>`,版本号字面量 = marketplace SSOT
- `openspec/changes/version-governance/specs/platform-parity/spec.md` —— ADDED Requirements:
  - platform mirror frontmatter 同样 MUST NOT 含 version 字段(regression guard)
  - platform mirror help-card(若含 Help 段)第一行版本号 MUST 等于 marketplace SSOT
  - 改 marketplace version 时 platform mirror help-card MUST 同 PR 同步

**验证命令**:

```bash
ls openspec/changes/version-governance/specs/{repo-invariants,skill-lifecycle,help-mode,platform-parity}/spec.md
# 预期:4 个文件都存在
grep -lE "ADDED Requirement|MODIFIED Requirement" \
  openspec/changes/version-governance/specs/*/spec.md
# 预期:4 行
```

---

## Task 2 — Frontmatter regression guard:确保 16 个 SKILL.md 不含 `version` 字段

**依赖**:Task 1 完成

**做什么**:

确认 8 个 canonical SKILL.md 与 8 个 platform mirror SKILL.md 的 frontmatter **均不含** `version` 字段(顶层或嵌套于 metadata 子结构)。Claude Code 官方 skill schema 不支持 `version` 字段;架构 pivot 决定 SSOT 落到 marketplace.json,不放 frontmatter。

若早期版本已加入 `version:` 字段(如本 change 探索阶段曾尝试),Task 2 包含 revert 16 处。

**验证命令**:

```bash
grep -rn "^version:" skills/*/SKILL.md platforms/openclaw/*/SKILL.md 2>/dev/null
# 预期:无输出(0 个文件含 version: 字段)
grep -rn "^\s\+version:" skills/*/SKILL.md platforms/openclaw/*/SKILL.md 2>/dev/null
# 预期:无输出(metadata 嵌套 version 也不允许)
```

---

## Task 3 — 修正 marketplace.json 的 insight-fuse 版本飘移

**依赖**:Task 1 完成

**做什么**:

修改 [.claude-plugin/marketplace.json](../../../.claude-plugin/marketplace.json) `plugins[name=insight-fuse].version`:`3.3.0` → `3.4.0`。同步修改 description 中的 `Insight Fuse v3.3` 字样为 `Insight Fuse v3.4`。

**验证命令**:

```bash
python3 -c "
import json
with open('.claude-plugin/marketplace.json') as f:
    d = json.load(f)
v = next(p['version'] for p in d['plugins'] if p['name']=='insight-fuse')
print(f'insight-fuse: {v}')
"
# 预期:3.4.0
grep -n "Insight Fuse v3" .claude-plugin/marketplace.json
# 预期:仅 v3.4 字样,无 v3.3 残留
```

---

## Task 4 — 修正 claim-ground SKILL.md help card 内的 v1.1 残留

**依赖**:无(与其他 task 并行)

**做什么**:

修改 [skills/claim-ground/SKILL.md](../../../skills/claim-ground/SKILL.md) help card code block 第一行字面量:

```diff
-Claim Ground v1.1 — Epistemic constraint engine (runtime evidence before assertions)
+Claim Ground v1.2.0 — Epistemic constraint engine (runtime evidence before assertions)
```

**注意保留**:正文里"v1.1 新增 / v1.2 新增"等历史叙述属于变更历史,**不改**(参 [help-mode delta](specs/help-mode/spec.md) "历史叙述豁免" Scenario)。

**验证命令**:

```bash
grep -n "Claim Ground v1\." skills/claim-ground/SKILL.md
# 预期:help card 行为 v1.2.0;正文历史叙述行允许保留 v1.1/v1.2 引用
```

---

## Task 5 — 7 个 canonical help card 第一行追加版本号

**依赖**:Task 3 完成

**做什么**:

修改下列 7 个 SKILL.md 的 `## Help` 段内 code block 第一行,版本号字面量 = marketplace.json 对应 plugin `version`(三段 SemVer):

| Skill | 改前 | 改后 |
|---|---|---|
| block-break | `Block Break — Behavioral constraint engine ...` | `Block Break v1.0.0 — ...` |
| council-fuse | `Council Fuse — Multi-perspective deliberation engine ...` | `Council Fuse v1.1.0 — ...` |
| insight-fuse | `Insight Fuse — Systematic multi-source research engine (8-stage pipeline)` | `Insight Fuse v3.4.0 — ...` |
| news-fetch | `News Fetch — ...` | `News Fetch v1.1.0 — ...` |
| ralph-boost | `Ralph Boost — ...` | `Ralph Boost v1.0.0 — ...` |
| skill-lint | `Skill Lint — ...` | `Skill Lint v1.0.0 — ...` |
| tome-forge | `Tome Forge — ...` | `Tome Forge v1.1.0 — ...` |

claim-ground 由 Task 4 处理。

**验证命令**:

```bash
for s in block-break claim-ground council-fuse insight-fuse news-fetch ralph-boost skill-lint tome-forge; do
  grep -E "^[A-Z][A-Za-z ]+ v[0-9]+\.[0-9]+\.[0-9]+ — " "skills/$s/SKILL.md" | head -1
done
# 预期:8 行,每行一条匹配
```

---

## Task 6 — skill-lint 新增 S29 / S30 / S31

**依赖**:Task 2 / 3 / 4 / 5 + Task 9 / 10 / 11 完成(lint 启用即过)

**做什么**:

修改 [.skill-lint.json](../../../.skill-lint.json) 加入 3 个 key:

```diff
   "verify-platform-subdirs": true,
   "verify-i18n-structure-parity": true,
   "verify-cross-skill-category-claim": true,
+  "verify-version-lockstep": true,
+  "verify-help-card-version-line": true,
+  "verify-changelog-entry": true,
   "require-help-section": "warn",
```

修改 [skills/skill-lint/scripts/skill-lint.sh](../../../skills/skill-lint/scripts/skill-lint.sh) 实现三条规则(联合 python heredoc):

- **S29**:marketplace.json `plugins[].version` MUST 是 SemVer 2.0.0;SKILL.md frontmatter MUST NOT 含 `version:` 字段(canonical + platforms 都查;regression guard);任一违反报 error
- **S30**:对每个 SKILL.md 的 `## Help` 段(heading 正则 `^##\s+Help\b`,允许 `## Help (no arguments)` 变体),提取 code block 第一行;regex `^[A-Z][A-Za-z0-9 -]+ v(\d+\.\d+\.\d+) — `,捕获组与 marketplace.json 对应 plugin `version` 不等则 error;**canonical + 每个 platform mirror 同等校验**
- **S31**:解析根 `/CHANGELOG.md`,扫 `^## <skill-name>$` H2 段,取下方第一个 `### [X.Y.Z]` 即 top-most 条目;与 marketplace.json `plugins[].version` 比对;不等或缺失则 error。CHANGELOG.md 整体缺失视为单条 error

**验证命令**:

```bash
bash skills/skill-lint/scripts/skill-lint.sh . | python3 -c "
import json,sys; d=json.loads(sys.stdin.read())
print(f'errors={len(d[\"errors\"])} passed={len(d[\"passed\"])}')
for l in d['passed']:
  if any(k in l for k in ['S29:','S30:','S31:']): print(' ',l)
"
# 预期:errors=0;S29/S30/S31 各 PASS

echo "---negative test 1: 制造 marketplace 飘移---"
python3 -c "
import json
with open('.claude-plugin/marketplace.json') as f: d=json.load(f)
for p in d['plugins']:
    if p['name']=='block-break': p['version']='9.9.9'
with open('.claude-plugin/marketplace.json','w') as f: json.dump(d, f, indent=4); f.write('\n')
"
bash skills/skill-lint/scripts/skill-lint.sh . | grep -oE 'S(29|30|31):[^"]*' | head
# 预期:S30 报 block-break: help-card v1.0.0 ≠ marketplace v9.9.9;S31 报 marketplace v9.9.9 ≠ CHANGELOG top entry v1.0.0
git checkout -- .claude-plugin/marketplace.json

echo "---negative test 2: 删除 CHANGELOG.md---"
mv CHANGELOG.md /tmp/CHANGELOG.md.test
bash skills/skill-lint/scripts/skill-lint.sh . | grep "S31" | head -1
# 预期:S31: CHANGELOG.md missing at repo root
mv /tmp/CHANGELOG.md.test CHANGELOG.md
```

---

## Task 7 — 重算 SHA-256 hash + 跑自检三命令

**依赖**:Task 2-6 + 9-11 全部完成

**做什么**:

```bash
bash scripts/recalc-all-hashes.sh
bash skills/skill-lint/scripts/skill-lint.sh .
grep -rn "v3.3\|v1.1 — Epistemic" skills/ platforms/ .claude-plugin/ \
  --include="*.md" --include="*.json" \
  | grep -vE "新增|历史|change-log|archive/|references/quality-standards|CHANGELOG.md"
```

**验证**:

- 预期 1:recalc 输出 [update] 行(canonical SKILL.md 因 Task 4/5 改动,hash 需更新)
- 预期 2:lint 总结 `errors=0 warnings=0`;passed 含 S29/S30/S31 各一行
- 预期 3:grep 第三条无残留(除允许的历史叙述 / archive 副本 / references 历史段 / CHANGELOG 历史条目)

---

## Task 8 — 提交前清单(PR review checklist)

**依赖**:Task 7 通过

**人工核对清单**:

- [ ] `git diff --stat`:8 个 canonical SKILL.md 改动(help-card 第一行加版本号)+ 3 个 platform mirror SKILL.md 改动(claim-ground / insight-fuse / tome-forge help-card 第一行加版本号)
- [ ] `git diff .claude-plugin/marketplace.json`:insight-fuse `version: 3.3.0 → 3.4.0` + description 改 + 8 个 skill 的 `integrity.skill-md-sha256` 重算
- [ ] `git diff .skill-lint.json`:追加 3 个 key (`verify-version-lockstep` / `verify-help-card-version-line` / `verify-changelog-entry`)
- [ ] `git diff skills/skill-lint/scripts/skill-lint.sh`:追加 S29/S30/S31 联合 python heredoc + 3 个 CFG var + bash 解析
- [ ] **新建** `/CHANGELOG.md`:含 `# Forge Changelog` 顶层标题 + 8 个 `## <skill>` H2 段 + 各自 latest `### [X.Y.Z]`
- [ ] **4 份** spec delta(repo-invariants / skill-lifecycle / help-mode / platform-parity)均含 ADDED/MODIFIED Requirements 段 + 至少 1 个 Scenario,且**反映 marketplace SSOT 架构**(非 frontmatter SSOT)
- [ ] proposal.md / design.md / tasks.md 三份均存在,且都标注 2026-05-07 架构 pivot
- [ ] 单 PR 合入,不要拆分(决策 5)
- [ ] 集合级 plugin.json 维持 1.0.0,follow-up RFC `collection-version-policy` 占位(决策见 Non-goals)
- [ ] **架构注释(2026-05-07)**:Frontmatter MUST NOT 含 version 字段。grep 验证 16 个 SKILL.md 全部清洁

---

## Task 9 — Platform mirror frontmatter regression guard verify

**依赖**:Task 1 完成

**做什么**:

确认 8 个 platform mirror SKILL.md 的 frontmatter 不含 `version` 字段(若早期版本已加入,需 revert)。

**验证命令**:

```bash
grep -rn "^version:" platforms/openclaw/*/SKILL.md 2>/dev/null
# 预期:无输出(0 个 mirror 含 version: 字段)
```

---

## Task 10 — 3 个 openclaw mirror help-card 第一行同步版本号

**依赖**:Task 9 完成

**做什么**:

仅 3 个 openclaw mirror 含 `## Help` 段,需修订 help-card 第一行版本号字面量等于 marketplace SSOT:

| Mirror | 改前 | 改后 |
|---|---|---|
| platforms/openclaw/claim-ground | `Claim Ground v1.1 — Epistemic constraint engine ...` | `Claim Ground v1.2.0 — ...` |
| platforms/openclaw/insight-fuse | `Insight Fuse — Systematic multi-source research engine (8-stage pipeline)` | `Insight Fuse v3.4.0 — ...` |
| platforms/openclaw/tome-forge | `Tome Forge — Personal Knowledge Base Engine`(在 `## Help (no arguments)` 段内) | `Tome Forge v1.1.0 — ...` |

其余 5 个 mirror(block-break / council-fuse / news-fetch / ralph-boost / skill-lint)无 Help 段 → 不在本 task 范围(Non-goals 已声明;由 [openclaw-drift-fix](../openclaw-drift-fix/proposal.md) 处理)。

**验证命令**:

```bash
for s in claim-ground insight-fuse tome-forge; do
  grep -E "^[A-Z][A-Za-z ]+ v[0-9]+\.[0-9]+\.[0-9]+ — " "platforms/openclaw/$s/SKILL.md" | head -1
done
# 预期:3 行,各匹配一次
```

---

## Task 11 — 创建根 `/CHANGELOG.md`

**依赖**:Task 3 完成(marketplace SSOT 已定值)

**做什么**:

新建 [/CHANGELOG.md](../../../CHANGELOG.md):
- 顶层标题 `# Forge Changelog`
- Format inspired by Keep-a-changelog 1.1.0 + SemVer 2.0.0 链接
- "Lint contract" 段简述 S31 强制
- 8 个 `## <skill-name>` H2 段(skill 名顺序与 README Skills 表一致),每段 1+ 个 `### [X.Y.Z] — YYYY-MM-DD`
- top-most 条目即"latest",字面量 = 该 skill 在 marketplace.json `plugins[].version`
- 历史条目按 git/openspec archive 可考的事实 seed,不要凭空编;不可考的版本只写 "Initial release."
- 末尾 `## Forge collection (集合级)` 段,引用 follow-up RFC 占位

**验证命令**:

```bash
test -f CHANGELOG.md && echo OK
grep -c "^## [a-z][a-z-]*$" CHANGELOG.md
# 预期:8(8 个 skill H2 段;集合级段不命中此正则)
for s in block-break claim-ground council-fuse insight-fuse news-fetch ralph-boost skill-lint tome-forge; do
  awk -v sk="$s" '
    $0 == "## " sk { in_section=1; next }
    /^## / && in_section { exit }
    in_section && match($0, /^### \[([0-9]+\.[0-9]+\.[0-9]+)/, a) { print sk": top="a[1]; exit }
  ' CHANGELOG.md
done
# 预期:8 行,top 版本与 marketplace.json 同 skill version 完全相等
```

---

## Task 12 — 完整自检三命令 + 双重负向测试

**依赖**:Task 1-11 全部完成

**做什么**:

```bash
bash scripts/recalc-all-hashes.sh
bash skills/skill-lint/scripts/skill-lint.sh .
grep -rn "v3.3\|v1.1 — Epistemic" skills/ platforms/ .claude-plugin/ \
  --include="*.md" --include="*.json" \
  | grep -vE "新增|历史|change-log|archive/|references/quality-standards|CHANGELOG.md"
```

**验证**:

```bash
# 预期 1:recalc 输出至少一行 [update]
# 预期 2:lint 总结 errors=0 warnings=0;passed 含 S29/S30/S31 各一行
# 预期 3:grep 第三条无残留(允许 archive/ + 历史叙述行)
```

负向测试(可选,确证 lint 真在工作):

```bash
# 测试 A:bump marketplace.json 不更 help-card / CHANGELOG
python3 -c "
import json
with open('.claude-plugin/marketplace.json') as f: d=json.load(f)
for p in d['plugins']:
    if p['name']=='claim-ground': p['version']='1.3.0'
with open('.claude-plugin/marketplace.json','w') as f: json.dump(d,f,indent=4); f.write('\n')
"
bash skills/skill-lint/scripts/skill-lint.sh . | python3 -c "
import json,sys
d=json.loads(sys.stdin.read())
captured=[e for e in d['errors'] if any(k in e for k in ['S29:','S30:','S31:'])]
print(f'captured={len(captured)} (expect ≥3: S30 canonical+platform / S31)')
"
git checkout -- .claude-plugin/marketplace.json

# 测试 B:删 CHANGELOG.md
mv CHANGELOG.md /tmp/CHANGELOG.md.test
bash skills/skill-lint/scripts/skill-lint.sh . | grep -E "S31.*missing" | head -1
mv /tmp/CHANGELOG.md.test CHANGELOG.md

# 测试 C:在 SKILL.md frontmatter 加 version 字段(regression guard)
sed -i.bak '/^license:/a version: 9.9.9' skills/block-break/SKILL.md
bash skills/skill-lint/scripts/skill-lint.sh . | grep -E "S29.*frontmatter contains" | head -1
# 预期:S29: skills/block-break/SKILL.md frontmatter contains `version:` field (forbidden)
mv skills/block-break/SKILL.md.bak skills/block-break/SKILL.md
```

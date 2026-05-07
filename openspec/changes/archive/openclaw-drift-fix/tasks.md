# Tasks

## Task 1 — G2:同步 openclaw skill-lint mirror 到 canonical

**依赖**:无(canonical 已含 S29/S30/S31)

**做什么**:byte-identical 覆盖 — `cp skills/skill-lint/scripts/skill-lint.sh platforms/openclaw/skill-lint/scripts/skill-lint.sh`

**验证**:

```bash
diff -q skills/skill-lint/scripts/skill-lint.sh platforms/openclaw/skill-lint/scripts/skill-lint.sh
# 预期:无输出
grep -oE "S(29|30|31):" platforms/openclaw/skill-lint/scripts/skill-lint.sh | sort -u
# 预期:S29: / S30: / S31: 各一行
bash platforms/openclaw/skill-lint/scripts/skill-lint.sh . | python3 -c "
import json,sys; d=json.loads(sys.stdin.read())
print(f'errors={len(d[\"errors\"])} passed={len(d[\"passed\"])}')
"
# 预期:errors=0
```

---

## Task 2 — G3:5 个 openclaw mirror 补 `## Help` 段

**依赖**:无(canonical Help 段已就位,Task 2 仅复制)

**做什么**:在以下 5 个 mirror SKILL.md 中插入 `## Help` 段。每段从 canonical 同名 SKILL.md 直接复制(包括 code block + Usage / Examples / 链接);**仅替换** code block 第一行的版本号字面量为 marketplace.json 对应 plugin 的 version(应该已经一致,因为 canonical 与 mirror 共享 marketplace SSOT)。

| Mirror 文件 | 插入位置 | canonical 复制源 |
|---|---|---|
| platforms/openclaw/block-break/SKILL.md | H1 后第一段下 | skills/block-break/SKILL.md `## Help` 段 |
| platforms/openclaw/council-fuse/SKILL.md | H1 后第一段下 | skills/council-fuse/SKILL.md `## Help` 段 |
| platforms/openclaw/news-fetch/SKILL.md | H1 后第一段下 | skills/news-fetch/SKILL.md `## Help` 段 |
| platforms/openclaw/ralph-boost/SKILL.md | "## 平台适配说明" 后 | skills/ralph-boost/SKILL.md `## Help` 段 |
| platforms/openclaw/skill-lint/SKILL.md | H1 后第一段下 | skills/skill-lint/SKILL.md `## Help` 段 |

**验证**:

```bash
for s in block-break council-fuse news-fetch ralph-boost skill-lint; do
  c=$(grep -c "^## Help" "platforms/openclaw/$s/SKILL.md")
  echo "$s: $c"
done
# 预期:全 1
bash skills/skill-lint/scripts/skill-lint.sh . | python3 -c "
import json,sys; d=json.loads(sys.stdin.read())
s30=[l for l in d['passed'] if 'S30:' in l]
print('S30 passed:', s30)
"
# 预期:S30 PASS(canonical + platforms 全部 help-card 版本对齐 marketplace)
```

---

## Task 3 — G4:同步 tome-forge openclaw schema-template 到 canonical

**依赖**:无

**做什么**:byte-identical 覆盖 — `cp skills/tome-forge/references/schema-template.md platforms/openclaw/tome-forge/references/schema-template.md`

**验证**:

```bash
diff -q skills/tome-forge/references/schema-template.md platforms/openclaw/tome-forge/references/schema-template.md
# 预期:无输出
```

---

## Task 4 — D1:platform-parity spec delta 放宽 description 同步规则

**依赖**:无

**做什么**:写 [openspec/changes/openclaw-drift-fix/specs/platform-parity/spec.md](specs/platform-parity/spec.md) MODIFIED Requirement,把现行 spec L60 "修改规范版的 description / metadata.permissions 时 MUST 同步平台版" 拆为:
- description **语义/范畴** MUST 一致;允许 platform-specific wording 反映本平台实际事件名 / 工具名 / 命令名,SHALL NOT 引入 canonical 不存在的能力声明
- metadata.permissions MUST 字面量同步(保持现状严格性)

**验证**:

```bash
test -f openspec/changes/openclaw-drift-fix/specs/platform-parity/spec.md
grep -E "MODIFIED Requirement|platform-specific wording" \
  openspec/changes/openclaw-drift-fix/specs/platform-parity/spec.md
# 预期:至少 2 行命中
```

---

## Task 5 — 沉淀 [docs/design/cross/openclaw-capability-gap-design.md](../../../docs/design/cross/openclaw-capability-gap-design.md)

**依赖**:无

**做什么**:新建 design 文档,内容结构:
1. OpenClaw runtime 一句话定义 + Claude Code 架构差异
2. Claude Code 五 hook → OpenClaw event 对照表(verbatim 自 [platforms/openclaw/claim-ground/hooks/openclaw/](../../../platforms/openclaw/claim-ground/hooks/openclaw))
3. 8 个 skill 的镜像状态矩阵(post-fix)
4. by-design 适配清单(council-fuse / ralph-boost / block-break / claim-ground 各自 by-design 段的 verbatim 引用)
5. 永久豁免列表(PreToolUse / PostToolUse 在 OpenClaw 无等价)
6. 后续 follow-up 路径(G5 block-break openclaw event handlers / D2 / D3 / 集合级 plugin.json 政策)

**验证**:

```bash
test -f docs/design/cross/openclaw-capability-gap-design.md && echo OK
grep -c "^## " docs/design/cross/openclaw-capability-gap-design.md
# 预期:≥ 6
```

---

## Task 6 — 重算 hash + 全量 lint 闭环

**依赖**:Task 1 / 2 / 3 完成(平台 mirror SKILL.md 都改了)

**做什么**:

```bash
bash scripts/recalc-all-hashes.sh
bash skills/skill-lint/scripts/skill-lint.sh .
```

**验证**:

```bash
bash skills/skill-lint/scripts/skill-lint.sh . | python3 -c "
import json,sys; d=json.loads(sys.stdin.read())
print(f'errors={len(d[\"errors\"])} warnings={len(d[\"warnings\"])} passed={len(d[\"passed\"])}')
for l in d['passed']:
  if any(k in l for k in ['S29:','S30:','S31:']): print(' ',l)
"
# 预期:errors=0;S29 / S30 / S31 各 PASS
```

---

## Task 7 — 提交前清单(PR review checklist)

**依赖**:Task 6 通过

- [ ] `git diff --stat` 中:5 个 platforms/openclaw/<skill>/SKILL.md 改动(G3)+ 1 个 schema-template(G4)+ 1 个 skill-lint mirror(G2)
- [ ] `git diff platforms/openclaw/skill-lint/scripts/skill-lint.sh` 显示 byte-identical 同步
- [ ] `git diff platforms/openclaw/tome-forge/references/schema-template.md` 显示 byte-identical 同步
- [ ] 5 个新加的 Help 段 code block 第一行符合 `<Name> v<X.Y.Z> — <tagline>` 正则
- [ ] [specs/platform-parity/spec.md](specs/platform-parity/spec.md) MODIFIED Requirement 含 "platform-specific wording" 关键词
- [ ] [docs/design/cross/openclaw-capability-gap-design.md](../../../docs/design/cross/openclaw-capability-gap-design.md) 6 个 H2 段就位
- [ ] proposal.md / design.md / tasks.md 三份均存在
- [ ] 单 PR 合入,与 `version-governance` change 解耦(本 change 仅依赖 version-governance 的 SSOT 决策,但不引入新的 SSOT 改动)

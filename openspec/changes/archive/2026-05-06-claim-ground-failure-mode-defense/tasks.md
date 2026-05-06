# Tasks

> 拆 5 个 PR 顺序提交。每 PR 内任务可并行；PR 间严格依赖（PR-2 等 PR-1 merge 才起手）。批量改动均给脚本入口或 grep 兜底。

## Checklist

### PR-1 Foundation
- [x] 1.1 Red Line R8-R15 写入 red-lines.md
- [x] 1.2 anchors.md schema 扩三字段
- [x] 1.3 playbook.md 加 4 个新段
- [x] 1.4 新建 matchers.json
- [x] 1.5 新建 reminders.json
- [x] 1.6 skill-lint S27 实现（S25/S26 已占用，重编号）
- [x] 1.7 broadcast 6 文件到 platforms/openclaw/claim-ground/references/
- [x] 1.8 broadcast S27 docs 到 platforms/openclaw/skill-lint/
- [x] 1.9 PR-1 三件套自检 + 提交

### PR-2 Claude Code hooks
- [x] 2.1 扩 evidence-reminder.sh：路径抽取 + 测试输出扫描
- [x] 2.2 扩 session-anchor.sh：seen_paths + hard_constraints + needs_reconfirm 注入
- [x] 2.3 新建 prompt-gate.sh（UserPromptSubmit dispatcher）
- [x] 2.4 新建 pre-tool-gate.sh（PreToolUse dispatcher）
- [x] 2.5 hooks.json 注册 + SKILL.md 接驳
- [x] 2.6 PR-2 hook 单测 + 提交

### PR-3 openclaw hooks + S26
- [x] 3.1 Probe openclaw 事件名映射（→ openclaw-event-mapping.md；架构差异：5 hook 中只 3 个可镜像）
- [x] 3.2 创建 3 个 openclaw hook 目录与 HOOK.md + handler.ts/.js（pre-tool-gate/evidence-reminder 走豁免——openclaw 无 PreToolUse/PostToolUse 等价事件）
- [x] 3.3 e2e handler 模拟事件测试（12/12 PASS — 不依赖 openclaw plugin install，函数级直接验证）
- [x] 3.4 skill-lint S28（重编号；含"无等价机制可用"豁免逻辑）
- [x] 3.5 platforms/openclaw/claim-ground/SKILL.md 同步 + block-break SKILL.md 加豁免
- [x] 3.6 PR-3 提交（三件套全过：lint 0 errors / 0 warnings；e2e handler 12/12 PASS）

### PR-4 End-to-end Eval
- [x] 4.1 scenarios.md 加 20 场景（37-56）
- [x] 4.2 run-trigger-test.sh 双平台条件性测试（Hook unit 19 + OpenClaw e2e 4 = 23 PASS）
- [x] 4.3 End-to-end 双平台回归（自动测 23/23 PASS；人测 deferred—需 claude API/openclaw runtime 凭证）
- [x] 4.4 PR-4 提交（lint 0/0；hash 全 unchanged—PR-4 仅改 evals 不动 SKILL.md）

### PR-5 Hash + Release
- [x] 5.1 全量 hash 重算 + claim-ground 版本 1.1.0 → 1.2.0
- [x] 5.2 README 安装步骤更新（3 openclaw hooks enable + 平台限制说明）
- [x] 5.3 三件套自检 + commit（lint 0/0；S25-S28+S19 全 pass；e2e 12/12；hook unit 19/19）
- [x] 5.4 归档本 change

---

## PR-1 Foundation（文档 + JSON schema + S25）

### Task 1.1 — Red Line R8-R15 写入 red-lines.md

**依赖**：无

**做什么**：

在 [skills/claim-ground/references/red-lines.md](../../../skills/claim-ground/references/red-lines.md) 末尾追加 R8-R15 八条红线。每条按现有 R7 格式：定义 + 识别信号 + 反例 + 正例 + 触发边界。R8 反例必须用 openclaw 真实失败案例。同时把第 5-13 行的红线清单从 7 条扩到 15 条。

```bash
# R8 路径锚点污染 / R9 模糊指令消歧 / R10 破坏性动作列项 / R11 测试 passed-skipped /
# R12 env var 验证 / R13 scope creep / R14 硬约束保留 / R15 "最新/官方" WebSearch
```

**验证命令**：

```bash
grep -c "^## 红线 " skills/claim-ground/references/red-lines.md
# 预期：15

grep -c "^- " skills/claim-ground/references/red-lines.md | head -1
# 预期：清单段含 15 行

# 反例锚点检查
grep -A2 "## 红线 8" skills/claim-ground/references/red-lines.md | grep -q "openclaw"
# 预期：exit 0
```

---

### Task 1.2 — anchors.md schema 扩三字段

**依赖**：无

**做什么**：

在 [skills/claim-ground/references/anchors.md](../../../skills/claim-ground/references/anchors.md) 的 `## Schema` 段加 `seen_paths[]` + `hard_constraints[]` 字段；anchors[] 每条加 `needs_reconfirm` flag；`## 生命周期`段补"PostToolUse 写、SessionStart 读、verify 升级 verified"路径；`## 适合 anchor 的事实类型`表加 seen_paths / hard_constraints 行；明示**跨 Claude Code / openclaw 共享同一文件**。

**验证命令**：

```bash
grep -E "seen_paths|hard_constraints|needs_reconfirm" \
  skills/claim-ground/references/anchors.md | wc -l
# 预期：≥6（每字段至少 2 处提及）

# JSON schema sanity（手抄 schema 段到 jq 验证语法）
sed -n '/```json/,/```/p' skills/claim-ground/references/anchors.md | \
  head -50 | sed '1d;$d' | python3 -c "import json,sys; json.load(sys.stdin)"
# 预期：无报错
```

---

### Task 1.3 — playbook.md 加 4 个新段

**依赖**：无

**做什么**：

[skills/claim-ground/references/playbook.md](../../../skills/claim-ground/references/playbook.md) 加 4 个新段：(a) "模糊指令分类与必查命令"映射表（动词 → `which X` + `ls ~/.X`）；(b) "破坏性动作清单与反向确认模板"（rm -rf / reset --hard / push --force / drop / kill）；(c) "测试输出 passed/skipped 区分"；(d) "硬约束词典"（不要/别/禁止/must not 中英集）。

**验证命令**：

```bash
grep -E "^## (模糊指令分类|破坏性动作|测试输出|硬约束词典)" \
  skills/claim-ground/references/playbook.md | wc -l
# 预期：4
```

---

### Task 1.4 — 新建 matchers.json

**依赖**：无（独立新文件）

**做什么**：

新建 [skills/claim-ground/references/matchers.json](../../../skills/claim-ground/references/matchers.json)。schema 见 design.md 决策 5 + plan.md `## Matcher 设计`段。包含 5 类：ambiguity（含 6 sub）/ destructive（含 6 sub）/ scope_creep / env_var_unverified / hard_constraint / scope_collapse + self_invocation / yield_to_pushback / yield_to_frustration 三个 guard regex。

**验证命令**：

```bash
python3 -c "import json; d = json.load(open('skills/claim-ground/references/matchers.json')); \
  print(sorted(d.keys()))"
# 预期：['ambiguity', 'destructive', 'env_var_unverified', 'hard_constraint',
#        'scope_collapse', 'scope_creep', 'self_invocation',
#        'yield_to_frustration', 'yield_to_pushback']

# 每个 regex 都是合法的 PCRE
python3 -c "
import json, re
d = json.load(open('skills/claim-ground/references/matchers.json'))
def walk(o):
    if isinstance(o, str): re.compile(o)
    elif isinstance(o, dict):
        for v in o.values(): walk(v)
    elif isinstance(o, list):
        for v in o: walk(v)
walk(d); print('ok')
"
# 预期：ok
```

---

### Task 1.5 — 新建 reminders.json

**依赖**：无

**做什么**：

新建 [skills/claim-ground/references/reminders.json](../../../skills/claim-ground/references/reminders.json)，含 8 个 context block 模板：`AMBIGUITY` / `DESTRUCTIVE` / `SCOPE_CREEP` / `ENV_VAR` / `TEST_RESULT` / `HARD_CONSTRAINTS` / `SEEN_PATHS` / `SCOPE_COLLAPSE`，每个有 zh + en 双语 body。模板用 `{placeholder}` 占位，bash/TS handler 填充。

**验证命令**：

```bash
python3 -c "
import json
d = json.load(open('skills/claim-ground/references/reminders.json'))
expected = {'AMBIGUITY','DESTRUCTIVE','SCOPE_CREEP','ENV_VAR','TEST_RESULT',
            'HARD_CONSTRAINTS','SEEN_PATHS','SCOPE_COLLAPSE'}
missing = expected - set(d.keys())
print('missing:', missing if missing else 'none')
for k, v in d.items():
    assert 'zh' in v and 'en' in v, f'{k} missing zh/en'
print('ok')
"
# 预期：missing: none / ok
```

---

### Task 1.6 — skill-lint S25（warning：术语引用密度）

**依赖**：无

**做什么**：

(a) [skills/skill-lint/references/rules.md](../../../skills/skill-lint/references/rules.md) 加 S25 描述（warning，启发式 + 白名单豁免）。
(b) [skills/skill-lint/scripts/skill-lint.sh](../../../skills/skill-lint/scripts/skill-lint.sh) 加 S25 实现：扫每个 SKILL.md 的命名实体（hyphenated 英文词 + 中文复合词），grep repo 内是否有 ≥1 处定义；少于 1 → warn。白名单：`git/ls/bash/jq/sed/awk/grep/find/curl/python/node/npm/cd/echo/cat/diff/rsync/cp/mv/rm/mkdir`。
(c) [evals/skill-lint/scenarios.md](../../../evals/skill-lint/scenarios.md) 加 S25-a/b/c 三场景。

**验证命令**：

```bash
# S25 实现自测
bash skills/skill-lint/scripts/skill-lint.sh . 2>&1 | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
s25_warnings = [w for w in d.get('warnings', []) if w.startswith('S25')]
print('S25 warnings count:', len(s25_warnings))
"
# 预期：实施后随机抽 5 个现有 SKILL.md，false positive 率 <30%（见 design.md Open Questions）

# rules.md 含 S25
grep -E "^## S25 " skills/skill-lint/references/rules.md
```

---

### Task 1.7 — broadcast 6 文件到 platforms/openclaw/claim-ground/references/

**依赖**：Task 1.1, 1.2, 1.3, 1.4, 1.5

**做什么**：

```bash
SRC=skills/claim-ground/references
DST=platforms/openclaw/claim-ground/references
for f in red-lines.md anchors.md playbook.md matchers.json reminders.json; do
  cp "$SRC/$f" "$DST/$f"
done
```

**验证命令**：

```bash
diff -rq skills/claim-ground/references platforms/openclaw/claim-ground/references | \
  grep -v -E "(scope-boundaries\.md|hooks)"
# 预期：零输出（除 platform-only 的 scope-boundaries.md）
```

---

### Task 1.8 — broadcast S25 docs 到 platforms/openclaw/skill-lint/

**依赖**：Task 1.6

**做什么**：

```bash
cp skills/skill-lint/references/rules.md platforms/openclaw/skill-lint/references/rules.md
cp skills/skill-lint/scripts/skill-lint.sh platforms/openclaw/skill-lint/scripts/skill-lint.sh
```

**验证命令**：

```bash
diff -q skills/skill-lint/references/rules.md platforms/openclaw/skill-lint/references/rules.md
diff -q skills/skill-lint/scripts/skill-lint.sh platforms/openclaw/skill-lint/scripts/skill-lint.sh
# 预期：两条都无输出
```

---

### Task 1.9 — PR-1 三件套自检 + 提交

**依赖**：Task 1.1-1.8 全部完成

**做什么**：

```bash
bash skills/skill-lint/scripts/skill-lint.sh . 2>&1 | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
errs = d.get('errors', [])
print(f'errors: {len(errs)}, warnings: {len(d.get(\"warnings\", []))}')
if errs: print('errors:', errs)
"

grep -rn "claim-ground" . --include="*.md" --include="*.json" 2>/dev/null \
  | grep -v "\.git" | wc -l

bash scripts/recalc-all-hashes.sh
```

提交：`feat(claim-ground, skill-lint): R8-R15 docs + matchers/reminders schema + S25`

**验证命令**：

```bash
# errors=0 必须
bash skills/skill-lint/scripts/skill-lint.sh . 2>&1 | grep -oE '"errors":\[[^]]*\]'
# 预期："errors":[]
```

---

## PR-2 Claude Code hooks（bash 实现）

### Task 2.1 — 扩 evidence-reminder.sh：路径抽取 + 测试输出扫描

**依赖**：PR-1 merge

**做什么**：

[skills/claim-ground/hooks/evidence-reminder.sh](../../../skills/claim-ground/hooks/evidence-reminder.sh) 在原 reminder 输出后追加：(a) 解析 stdin 提取 `tool_output`，用 `grep -oE '(~/[^ ]*|/home/[^ ]*|/.claude/[^ ]*|/.openclaw/[^ ]*)'` 抽取路径片段；(b) 单写者契约（read→modify→atomic mv）写入 `~/.forge/claim-ground-anchors.json` `seen_paths[]`，FIFO 50；(c) 若 tool_output 含 `pytest|jest|go test|cargo test|vitest`，扫 `passed.*skipped.*error` 计数，emit `<CLAIM_GROUND_TEST_RESULT>`。

**验证命令**：

```bash
rm -f ~/.forge/claim-ground-anchors.json
echo '{"tool_name":"Bash","tool_output":"foo /home/test/.openclaw/skills bar"}' \
  | bash skills/claim-ground/hooks/evidence-reminder.sh
python3 -c "
import json
d = json.load(open('/home/juserch/.forge/claim-ground-anchors.json'))
paths = [p['path'] for p in d.get('seen_paths', [])]
assert any('.openclaw/skills' in p for p in paths), f'expected path missing in {paths}'
print('ok')
"

echo '{"tool_name":"Bash","tool_output":"5 passed, 3 skipped, 1 error in 2.5s"}' \
  | bash skills/claim-ground/hooks/evidence-reminder.sh | grep -q TEST_RESULT
echo "test_result_emit: $?"
# 预期：0
```

---

### Task 2.2 — 扩 session-anchor.sh：seen_paths + hard_constraints + needs_reconfirm 注入

**依赖**：PR-1 merge

**做什么**：

[skills/claim-ground/hooks/session-anchor.sh](../../../skills/claim-ground/hooks/session-anchor.sh) 在原 anchors 注入之后：(a) 若 `seen_paths[]` 含 `verified:false` 条目 → emit `<CLAIM_GROUND_SEEN_PATHS>`；(b) 若 `hard_constraints[]` 非空且未 expire → emit `<CLAIM_GROUND_HARD_CONSTRAINTS>`；(c) anchors[] 跨 session 时自动设 `needs_reconfirm:true`（写回前判 `last_updated` 距今 >24h）。

**验证命令**：

```bash
# 准备测试 anchors.json
mkdir -p ~/.forge && cat > ~/.forge/claim-ground-anchors.json << 'EOF'
{
  "session_id":"test","last_updated":"2026-04-01T00:00:00Z",
  "anchors":[],"user_corrections":[],
  "seen_paths":[{"path":"/home/test/.openclaw","source_tool":"Bash","seen_at":"2026-04-30T00:00:00Z","verified":false,"verified_at":null,"verified_by":null,"source_platform":"claude-code"}],
  "hard_constraints":[{"constraint":"不要碰 auth","source_turn":3,"captured_at":"2026-04-30T00:00:00Z","scope":"session"}]
}
EOF

bash skills/claim-ground/hooks/session-anchor.sh | grep -E "SEEN_PATHS|HARD_CONSTRAINTS"
# 预期：2 行（两个 block 都 emit）
```

---

### Task 2.3 — 新建 prompt-gate.sh（UserPromptSubmit dispatcher）

**依赖**：PR-1 merge（依赖 matchers.json + reminders.json）

**做什么**：

新建 [skills/claim-ground/hooks/prompt-gate.sh](../../../skills/claim-ground/hooks/prompt-gate.sh)。结构：(1) 读 stdin JSON 提 `.prompt`；(2) self-invocation guard（`^/claim-ground` → exit 0）；(3) 互斥让位（命中 yield_to_pushback 或 yield_to_frustration regex → exit 0）；(4) 依次 grep matchers.json 中的 ambiguity / hard_constraint / scope_collapse；(5) 命中后从 reminders.json 读取对应 block 模板填充 + emit；(6) 命中 hard_constraint 时同步写入 anchors.json `hard_constraints[]`。

**验证命令**：

```bash
echo '{"prompt":"把 forge 更新到 openclaw 环境"}' | bash skills/claim-ground/hooks/prompt-gate.sh \
  | grep -q AMBIGUITY && echo "B1: ok"
echo '{"prompt":"把它优化一下"}' | bash skills/claim-ground/hooks/prompt-gate.sh \
  | grep -q AMBIGUITY && echo "B2: ok"
echo '{"prompt":"备份重要文件"}' | bash skills/claim-ground/hooks/prompt-gate.sh \
  | grep -q AMBIGUITY && echo "B3: ok"
echo '{"prompt":"不要碰 auth 模块"}' | bash skills/claim-ground/hooks/prompt-gate.sh \
  | grep -q HARD_CONSTRAINTS && echo "F: ok"
echo '{"prompt":"Anthropic 当前最强的模型"}' | bash skills/claim-ground/hooks/prompt-gate.sh \
  | grep -q SCOPE_COLLAPSE && echo "A4: ok"
echo '{"prompt":"/claim-ground verify openclaw"}' | bash skills/claim-ground/hooks/prompt-gate.sh
# 预期：最后一条空输出（self-invocation）；前 5 条各 ok
```

---

### Task 2.4 — 新建 pre-tool-gate.sh（PreToolUse dispatcher）

**依赖**：PR-1 merge

**做什么**：

新建 [skills/claim-ground/hooks/pre-tool-gate.sh](../../../skills/claim-ground/hooks/pre-tool-gate.sh)。逻辑：(1) 读 stdin JSON 提 `.tool_name` + `.tool_input`；(2) Bash 命令命中 destructive matcher → emit `<CLAIM_GROUND_DESTRUCTIVE>`；(3) Edit/Write 路径未在最近 3 turn 用户消息中出现（substring 或 basename match）且非批量指令豁免 → emit `<CLAIM_GROUND_SCOPE_CREEP>`；(4) Bash/Edit 命令含 `$VAR` 但前序无 `echo $VAR` → emit `<CLAIM_GROUND_ENV_VAR>`；(5) exit 0 不阻断。

**验证命令**：

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/foo"}}' \
  | bash skills/claim-ground/hooks/pre-tool-gate.sh | grep -q DESTRUCTIVE && echo "C1: ok"

echo '{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}' \
  | bash skills/claim-ground/hooks/pre-tool-gate.sh | grep -q DESTRUCTIVE && echo "C2: ok"

echo '{"tool_name":"Bash","tool_input":{"command":"curl $API_KEY"}}' \
  | bash skills/claim-ground/hooks/pre-tool-gate.sh | grep -q ENV_VAR && echo "D6: ok"

echo '{"tool_name":"Edit","tool_input":{"file_path":"src/bar.ts"},"recent_user_turns":["改 src/foo.ts"]}' \
  | bash skills/claim-ground/hooks/pre-tool-gate.sh | grep -q SCOPE_CREEP && echo "E: ok"

echo '{"tool_name":"Edit","tool_input":{"file_path":"src/foo.ts"},"recent_user_turns":["改 src/foo.ts"]}' \
  | bash skills/claim-ground/hooks/pre-tool-gate.sh
# 预期：最后一条空输出（路径在用户消息中）；前 4 条各 ok
```

---

### Task 2.5 — hooks.json 注册 + SKILL.md 接驳

**依赖**：Task 2.1-2.4

**做什么**：

(a) [skills/claim-ground/hooks/hooks.json](../../../skills/claim-ground/hooks/hooks.json) 注册 prompt-gate（UserPromptSubmit, matcher 用 matchers.json 的并集 regex）+ pre-tool-gate（PreToolUse, matcher `Bash|Edit|Write`）。
(b) [skills/claim-ground/SKILL.md](../../../skills/claim-ground/SKILL.md)：description 加 "...detects ambiguity / destructive actions / verification gaps / cross-session constraints across Claude Code and openclaw"；触发场景段加 5 hook surface；核心规则段加 R8-R15 引用；新增 `## 平台 hook 等价位置` 段（per platform-parity spec ADDED Requirement）。

**验证命令**：

```bash
python3 -c "
import json
d = json.load(open('skills/claim-ground/hooks/hooks.json'))
hook_types = set(d['hooks'].keys())
expected = {'UserPromptSubmit','PostToolUse','SessionStart','PreToolUse'}
print('missing:', expected - hook_types)
"
# 预期：missing: set()

grep -E "^## 平台 hook 等价位置" skills/claim-ground/SKILL.md
# 预期：找到一行
```

---

### Task 2.6 — PR-2 hook 单测 + 提交

**依赖**：Task 2.1-2.5

**做什么**：

跑 Task 2.1-2.4 全部 verification 命令；运行 [evals/claim-ground/run-trigger-test.sh](../../../evals/claim-ground/run-trigger-test.sh) 现有部分确认无回归。

提交：`feat(claim-ground): prompt-gate + pre-tool-gate hooks for ambiguity/destructive/scope-creep/env-var defense`

**验证命令**：

```bash
bash evals/claim-ground/run-trigger-test.sh 2>&1 | tail -3
# 预期：所有现有 trigger 测试仍 pass

bash skills/skill-lint/scripts/skill-lint.sh . 2>&1 | grep -oE '"errors":\[[^]]*\]'
# 预期："errors":[]
```

---

## PR-3 openclaw hooks（TS/JS 实现 + S26）

### Task 3.1 — Probe openclaw 事件名映射

**依赖**：PR-2 merge

**做什么**：

```bash
openclaw hooks list > /tmp/openclaw-hooks-list.txt
for h in $(openclaw hooks list 2>&1 | grep -oE '[a-z][a-z-]+' | sort -u); do
  echo "=== $h ==="
  openclaw hooks info "$h" 2>&1 | grep -E "Events:|events"
done > /tmp/openclaw-events.txt
```

确定 5 个等价事件名映射：
- UserPromptSubmit → ?
- PreToolUse → ?
- PostToolUse → ?
- SessionStart → ?

把映射写入 `openspec/changes/claim-ground-failure-mode-defense/openclaw-event-mapping.md`（design 补遗）。

**验证命令**：

```bash
test -f openspec/changes/claim-ground-failure-mode-defense/openclaw-event-mapping.md
cat openspec/changes/claim-ground-failure-mode-defense/openclaw-event-mapping.md | grep -c "→"
# 预期：≥4
```

---

### Task 3.2 — 创建 5 个 openclaw hook 目录与 HOOK.md + handler.ts/.js

**依赖**：Task 3.1

**做什么**：

为 5 个 hook（prompt-gate / pre-tool-gate / evidence-reminder / session-anchor / epistemic-pushback）各创建：

```
platforms/openclaw/claim-ground/hooks/openclaw/<hook>/
├── HOOK.md       # frontmatter: name, description, metadata.openclaw.events
├── handler.ts    # TS 实现，import matchers.json + reminders.json
└── handler.js    # 编译产物
```

handler 复用 bash 版本逻辑：matcher → reminder block → 写 anchors.json。注意 anchors.json 路径 `~/.forge/claim-ground-anchors.json` 与 Claude Code 共享。

**验证命令**：

```bash
for h in prompt-gate pre-tool-gate evidence-reminder session-anchor epistemic-pushback; do
  d="platforms/openclaw/claim-ground/hooks/openclaw/$h"
  test -f "$d/HOOK.md" && test -f "$d/handler.ts" && test -f "$d/handler.js" && echo "$h: ok" || echo "$h: MISSING"
done
# 预期：5 行 ok

# events frontmatter 非空
for h in prompt-gate pre-tool-gate evidence-reminder session-anchor epistemic-pushback; do
  python3 -c "
import re, sys
content = open('platforms/openclaw/claim-ground/hooks/openclaw/$h/HOOK.md').read()
m = re.search(r'events.*?\[(.+?)\]', content, re.DOTALL)
assert m and m.group(1).strip() != '', '$h events empty'
print('$h: ok')
"
done
```

---

### Task 3.3 — 安装 + 启用 + 端到端跑通

**依赖**：Task 3.2

**做什么**：

```bash
# 安装本地 plugin（具体命令视 forge plugin spec 而定）
openclaw plugins install <forge-spec-or-path>
openclaw hooks list | grep claim-ground

# 启用 5 hook
for h in prompt-gate pre-tool-gate evidence-reminder session-anchor epistemic-pushback; do
  openclaw hooks enable "claim-ground-$h"
done

# 端到端：openclaw 内输入 "把 forge 更新到 openclaw 环境"
# 期望：handler 输出 <CLAIM_GROUND_AMBIGUITY> 块到 agent context
```

**验证命令**：

```bash
openclaw hooks list 2>&1 | grep -c "claim-ground"
# 预期：5

openclaw hooks list 2>&1 | grep claim-ground | grep -c "ready"
# 预期：5
```

---

### Task 3.4 — skill-lint S26（error：platform hook parity）

**依赖**：Task 3.2

**做什么**：

(a) [skills/skill-lint/references/rules.md](../../../skills/skill-lint/references/rules.md) 加 S26 描述（error，条件触发）。
(b) [skills/skill-lint/scripts/skill-lint.sh](../../../skills/skill-lint/scripts/skill-lint.sh) 加 S26 实现：若 `skills/<s>/hooks/` 存在 + `.skill-lint.json` platforms 含 `<p>` → 检 `platforms/<p>/<s>/hooks/<p>/` 存在 + 每个 HOOK.md frontmatter `events` 非空。
(c) [evals/skill-lint/scenarios.md](../../../evals/skill-lint/scenarios.md) 加 S26-a/b/c 场景。
(d) broadcast 到 platforms/openclaw/skill-lint/。

**验证命令**：

```bash
bash skills/skill-lint/scripts/skill-lint.sh . 2>&1 | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
errs = [e for e in d.get('errors', []) if 'S26' in e]
print('S26 errors:', errs)
"
# 预期：[]（claim-ground 已有 openclaw hook 镜像）

# 故意删一个测试
mv platforms/openclaw/claim-ground/hooks/openclaw/prompt-gate /tmp/__bak
bash skills/skill-lint/scripts/skill-lint.sh . 2>&1 | grep -q S26 && echo "S26 fires: ok"
mv /tmp/__bak platforms/openclaw/claim-ground/hooks/openclaw/prompt-gate
```

---

### Task 3.5 — platforms/openclaw/claim-ground/SKILL.md 同步

**依赖**：Task 3.2

**做什么**：

[platforms/openclaw/claim-ground/SKILL.md](../../../platforms/openclaw/claim-ground/SKILL.md) 同步 description / 触发场景 / 核心规则段；新增 `## 平台 hook 等价位置` 段，列 5 个 hook 名 + 启用命令（`openclaw hooks enable claim-ground-<name>`）。

**验证命令**：

```bash
grep -E "^## 平台 hook 等价位置" platforms/openclaw/claim-ground/SKILL.md
grep -c "openclaw hooks enable claim-ground-" platforms/openclaw/claim-ground/SKILL.md
# 预期：≥5
```

---

### Task 3.6 — PR-3 提交

**依赖**：Task 3.1-3.5

**做什么**：跑全自检（skill-lint S25-S26、platform-parity diff、openclaw hooks list 状态）。

提交：`feat(claim-ground): openclaw hook parity + skill-lint S26 platform-hook check`

**验证命令**：

```bash
bash skills/skill-lint/scripts/skill-lint.sh . 2>&1 | grep -oE '"errors":\[[^]]*\]'
# 预期："errors":[]
```

---

## PR-4 End-to-end Eval（双平台回归）

### Task 4.1 — scenarios.md 加 20 场景（37-56）

**依赖**：PR-3 merge

**做什么**：

[evals/claim-ground/scenarios.md](../../../evals/claim-ground/scenarios.md) 末尾追加 20 条场景，按 5 类 × 4 场景拆（B / C / D5+D6 / E / F+A）。每条含 输入 + 期望（含双平台对照行）。

**验证命令**：

```bash
grep -c "^## 场景 " evals/claim-ground/scenarios.md
# 预期：56（旧 36 + 新 20）

# 双平台覆盖检查
grep -c "openclaw" evals/claim-ground/scenarios.md
# 预期：≥10
```

---

### Task 4.2 — run-trigger-test.sh 双平台条件性测试

**依赖**：Task 4.1

**做什么**：

[evals/claim-ground/run-trigger-test.sh](../../../evals/claim-ground/run-trigger-test.sh) 加分支：if `which openclaw` 成功，则跑 5 类 hook 各自的 stdin 注入测试 + openclaw `hooks list` 状态检；否则仅跑 Claude Code 部分。

**验证命令**：

```bash
bash evals/claim-ground/run-trigger-test.sh 2>&1 | tail -5
# 预期：含 "Claude Code: PASSED" + （如有 openclaw）"OpenClaw: PASSED" 类似总结

# 模拟无 openclaw 环境
PATH_BAK=$PATH; PATH=/usr/bin:/bin bash evals/claim-ground/run-trigger-test.sh 2>&1 | tail -3
# 预期：跳过 openclaw 部分但不报错
```

---

### Task 4.3 — End-to-end 双平台回归（人测 + 自动测）

**依赖**：Task 4.2

**做什么**：

针对 6 类失败模式各准备 1 个 input，在 Claude Code 与 openclaw 各跑一遍。记录实际行为是否与场景期望一致。所有不一致回归到对应 hook 修。

**验证命令**：

```bash
# 自动部分
bash evals/claim-ground/run-trigger-test.sh 2>&1 | tail -3

# 人测：在两个平台分别输入 "把 forge 更新到 openclaw 环境"
# 期望：两边 LLM 都先 which openclaw 再 AskUserQuestion
```

---

### Task 4.4 — PR-4 提交

**依赖**：Task 4.1-4.3

**做什么**：提交：`test(claim-ground): 20 new scenarios + dual-platform e2e regression`

---

## PR-5 Hash + Release

### Task 5.1 — 全量 hash 重算

**依赖**：PR-4 merge

**做什么**：

```bash
bash scripts/recalc-all-hashes.sh
git diff .claude-plugin/marketplace.json | head -50
```

**验证命令**：

```bash
bash scripts/recalc-all-hashes.sh 2>&1 | tail -3
# 预期：claim-ground / skill-lint hash 已 update；其他 6 unchanged

bash skills/skill-lint/scripts/skill-lint.sh . 2>&1 | grep S19
# 预期：S19 (integrity hashes match) PASS
```

---

### Task 5.2 — README 安装步骤更新

**依赖**：无（与 5.1 并行）

**做什么**：

[README.md](../../../README.md) 安装章节加 openclaw hook 启用命令（5 条 `openclaw hooks enable claim-ground-...`）。

**验证命令**：

```bash
grep -c "openclaw hooks enable claim-ground-" README.md
# 预期：≥5
```

---

### Task 5.3 — 三件套自检 + commit

**依赖**：Task 5.1, 5.2

**做什么**：

```bash
bash skills/skill-lint/scripts/skill-lint.sh . 2>&1 | python3 -c "
import json, sys
d = json.loads(sys.stdin.read())
print('errors:', len(d.get('errors',[])), 'warnings:', len(d.get('warnings',[])))
"

grep -rn "claim-ground" . --include="*.md" --include="*.json" 2>/dev/null \
  | grep -v "\.git" | wc -l

bash scripts/recalc-all-hashes.sh 2>&1 | grep -E "(updated|unchanged)"
```

提交：`chore(forge): release v1.x.x — claim-ground multi-failure-mode defense`

**验证命令**：

```bash
# 三件套全过
bash skills/skill-lint/scripts/skill-lint.sh . 2>&1 | grep -oE '"errors":\[[^]]*\]'
# 预期："errors":[]
```

---

### Task 5.4 — 归档本 change

**依赖**：Task 5.3 commit merged

**做什么**：

```bash
openspec archive claim-ground-failure-mode-defense 2>&1
# 或手动 mv openspec/changes/claim-ground-failure-mode-defense \
#         openspec/changes/archive/claim-ground-failure-mode-defense
```

**验证命令**：

```bash
test -d openspec/changes/archive/claim-ground-failure-mode-defense
test ! -d openspec/changes/claim-ground-failure-mode-defense
# 两条都返回 0
```

# Tasks — add-skill-lint-s34-help-flag-coverage

## Phase 1 — S34 实现

- [ ] T1.1 在 [skills/skill-lint/scripts/skill-lint.sh](../../../skills/skill-lint/scripts/skill-lint.sh) 末尾追加 S34 块（紧邻 S33 之后），用独立 Python 子进程实现
  - 验证：`bash skills/skill-lint/scripts/skill-lint.sh . 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print('##S34 found:', any('S34:' in p for p in d.get('passed',[])+d.get('warnings',[])+d.get('errors',[])))"` 输出 `##S34 found: True`
  - 依赖：无

- [ ] T1.2 在 [.skill-lint.json](../../../.skill-lint.json) 加 `"verify-help-card-flag-coverage": "warn"`，并在 [skills/skill-lint/scripts/skill-lint.sh](../../../skills/skill-lint/scripts/skill-lint.sh) 的 CFG 解析段读这个键
  - 验证：`grep -E "verify-help-card-flag-coverage" .skill-lint.json skills/skill-lint/scripts/skill-lint.sh` 命中 ≥ 2 次
  - 依赖：T1.1

- [ ] T1.3 在 [skills/skill-lint/references/rules.md](../../../skills/skill-lint/references/rules.md) 加 S34 规则文档（与 S29-S33 同一节）
  - 验证：`grep "^### S34" skills/skill-lint/references/rules.md`
  - 依赖：T1.1

## Phase 2 — Platform mirror

- [ ] T2.1 把 [skills/skill-lint/scripts/skill-lint.sh](../../../skills/skill-lint/scripts/skill-lint.sh) + [references/rules.md](../../../skills/skill-lint/references/rules.md) 同步到 [platforms/openclaw/skill-lint/](../../../platforms/openclaw/skill-lint/)
  - 验证：`diff -q skills/skill-lint/scripts/skill-lint.sh platforms/openclaw/skill-lint/scripts/skill-lint.sh` 应输出空（IF policy 是 byte-identical mirror）
  - 依赖：T1.1, T1.3

## Phase 3 — Version bump（v1.0.0 → v1.1.0）

- [ ] T3.1 在 [.claude-plugin/marketplace.json](../../../.claude-plugin/marketplace.json) 把 skill-lint plugin `version: "1.0.0"` 改 `"1.1.0"`
  - 验证：`python3 -c "import json; d=json.load(open('.claude-plugin/marketplace.json')); print([p['version'] for p in d['plugins'] if p['name']=='skill-lint'])"` 输出 `['1.1.0']`
  - 依赖：T2.1

- [ ] T3.2 在 [skills/skill-lint/SKILL.md](../../../skills/skill-lint/SKILL.md) 与 [platforms/openclaw/skill-lint/SKILL.md](../../../platforms/openclaw/skill-lint/SKILL.md) help card 第一行 `v1.0.0` → `v1.1.0`
  - 验证：`grep -E "Skill Lint v1\.1\.0" skills/skill-lint/SKILL.md platforms/openclaw/skill-lint/SKILL.md` 命中 = 2
  - 依赖：T3.1

- [ ] T3.3 在根 [CHANGELOG.md](../../../CHANGELOG.md) `## skill-lint` 段顶部加 `### [1.1.0] — 2026-05-08` entry，含 S29-S34 backfill 记录
  - 验证：`awk '/^## skill-lint$/{f=1;next} /^## /{f=0} f && /^### \[/{print;exit}' CHANGELOG.md` 输出 `### [1.1.0] — 2026-05-08`
  - 依赖：T3.1

- [ ] T3.4 跑 [scripts/recalc-all-hashes.sh](../../../scripts/recalc-all-hashes.sh) 重算 skill-lint 的 SHA-256
  - 验证：`bash scripts/recalc-all-hashes.sh` 输出 `[update] skill-lint: ... -> ...` 一次后第二次跑无更新
  - 依赖：T3.2

## Phase 4 — Verification

- [ ] T4.1 跑 skill-lint 自身，期望 S34 输出 ≥ 4 条 warning（暴露 council-fuse / news-fetch / insight-fuse 已知问题）
  - 命令：`bash skills/skill-lint/scripts/skill-lint.sh . > /tmp/lint.json && python3 -c "import json; d=json.load(open('/tmp/lint.json')); ws=[w for w in d.get('warnings',[]) if w.startswith('S34:')]; print('S34 warnings:', len(ws)); [print(' ',w) for w in ws]"`
  - 期望：≥ 4 warnings；`council-fuse` / `news-fetch` / `insight-fuse` 各至少 1 条命中
  - 依赖：T3.4

- [ ] T4.2 跑 [evals/skill-lint/run-trigger-test.sh](../../../evals/skill-lint/run-trigger-test.sh) 全 PASS
  - 命令：`bash evals/skill-lint/run-trigger-test.sh`
  - 期望：exit 0
  - 依赖：T4.1

- [ ] T4.3 漏网扫描
  - 命令：`grep -rn "S34" skills/skill-lint platforms/openclaw/skill-lint .skill-lint.json CHANGELOG.md openspec/changes/add-skill-lint-s34-help-flag-coverage`
  - 期望：实现 + 配置 + 文档 + RFC + CHANGELOG 至少各命中 1 次
  - 依赖：T4.1

## Phase 5 — 提交 + 推送 + Archive

- [ ] T5.1 创建 commit（仅 skill-lint 改动 + RFC + CHANGELOG + marketplace.json）
- [ ] T5.2 push 到 origin/main
- [ ] T5.3 等待 follow-up RFC `fix-help-card-flag-coverage` 修完所有 4 个 skill 后归档本 change

## Phase 6 — 后续（不在本 PR）

- [ ] follow-up RFC `fix-help-card-flag-coverage`：批量修 council-fuse / news-fetch / insight-fuse / block-break 共 4 skill；修完后同 PR 把 S34 升级到 error

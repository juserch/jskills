#!/usr/bin/env bash
# Claim Ground evidence reminder — fires after Read/Grep/Bash tool use
# v1.2: Now also (a) extracts file paths from tool output → writes anchors.json
# seen_paths[]; (b) scans test framework output for skipped/errored counts
# → emits <CLAIM_GROUND_TEST_RESULT>.
#
# Called by hooks.json on PostToolUse for Read|Grep|Bash matchers.
# Exit 0 always — this is advisory context injection, never a block.

set +e  # 防御性：单字段失败不应中断 reminder 输出

# Always emit base reminder (unconditional, preserves v1 behavior)
cat << 'EOF'

<CLAIM_GROUND_EVIDENCE_REMINDER>
[Claim Ground 🎯 — 刚读完证据 / Just read runtime evidence]

You just ran a Read/Grep/Bash tool. Before asserting any fact about the
result, quote the specific line or output span **verbatim** — do NOT
paraphrase-only conclusions about what the evidence says.

你刚跑过 Read / Grep / Bash。若要基于此结果做事实断言，必须**逐字引用**
具体行或输出片段，不许只做 paraphrase 概括。

Rules of thumb:
- "The file shows X" → MUST be followed by an actual quoted line
- "The command output indicates Y" → MUST paste the output span
- If you would need to paraphrase because the evidence is inconclusive,
  instead say so explicitly and abstain from the factual assertion.
</CLAIM_GROUND_EVIDENCE_REMINDER>
EOF

# === v1.2 extension: parse stdin, write seen_paths, emit test result reminder ===

INPUT=$(cat 2>/dev/null || true)
[ -z "$INPUT" ] && exit 0

# Use python3 for JSON + atomic write + path/test scanning (single process, no jq dep)
python3 - "$INPUT" << 'PYEOF' 2>/dev/null || true
import json
import os
import re
import sys
import tempfile
from datetime import datetime, timezone

raw = sys.argv[1]
try:
    payload = json.loads(raw)
except Exception:
    sys.exit(0)

tool_name = payload.get("tool_name", "")
# PostToolUse 不同 harness 字段命名不同：尝试多个候选
tool_output = (
    payload.get("tool_output")
    or payload.get("output")
    or payload.get("result", {}).get("output", "")
    or payload.get("tool_response", "")
    or ""
)
if isinstance(tool_output, dict):
    tool_output = json.dumps(tool_output)
elif not isinstance(tool_output, str):
    tool_output = str(tool_output)

if not tool_output:
    sys.exit(0)

now = datetime.now(timezone.utc).isoformat()

# === (a) 路径抽取 → seen_paths[] ===
PATH_PATTERN = re.compile(r"(~/[^\s\"'<>;|()]+|/home/[^\s\"'<>;|()]+|/\.claude/[^\s\"'<>;|()]+|/\.openclaw/[^\s\"'<>;|()]+)")
extracted_paths = list(set(PATH_PATTERN.findall(tool_output)))[:10]  # 单次最多 10 个

# === (b) 测试输出扫描 ===
TEST_FRAMEWORK = re.compile(r"\b(pytest|jest|mocha|go\s+test|cargo\s+test|vitest|rspec|phpunit|dotnet\s+test)\b", re.IGNORECASE)
SKIPPED_CNT = re.compile(r"(\d+)\s+(skipped|pending|ignored|xfail)", re.IGNORECASE)
ERRORED_CNT = re.compile(r"(\d+)\s+(errors?|errored|failure|failed|fail)\b", re.IGNORECASE)
PASSED_CNT = re.compile(r"(\d+)\s+(passed|passing|pass|ok)\b", re.IGNORECASE)

framework_hit = TEST_FRAMEWORK.search(tool_output) is not None
skip_match = SKIPPED_CNT.search(tool_output)
err_match = ERRORED_CNT.search(tool_output)
pass_match = PASSED_CNT.search(tool_output)

# 写 anchors.json seen_paths[]
if extracted_paths:
    forge_dir = os.path.expanduser("~/.forge")
    os.makedirs(forge_dir, exist_ok=True)
    anchors_file = os.path.join(forge_dir, "claim-ground-anchors.json")

    # read existing or init
    if os.path.isfile(anchors_file):
        try:
            with open(anchors_file, "r", encoding="utf-8") as fh:
                data = json.load(fh)
        except Exception:
            data = {}
    else:
        data = {}

    data.setdefault("session_id", "")
    data["last_updated"] = now
    data.setdefault("anchors", [])
    data.setdefault("user_corrections", [])
    data.setdefault("seen_paths", [])
    data.setdefault("hard_constraints", [])

    # dedup by (path, source_tool)
    existing_keys = {(p["path"], p["source_tool"]) for p in data["seen_paths"]}
    for p in extracted_paths:
        if (p, tool_name) not in existing_keys:
            data["seen_paths"].append({
                "path": p,
                "source_tool": tool_name,
                "source_platform": "claude-code",
                "seen_at": now,
                "verified": False,
                "verified_at": None,
                "verified_by": None,
            })

    # FIFO 50 上限
    if len(data["seen_paths"]) > 50:
        data["seen_paths"] = data["seen_paths"][-50:]

    # atomic write
    try:
        fd, tmp = tempfile.mkstemp(prefix="claim-ground-anchors.", dir=forge_dir, suffix=".tmp")
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(data, fh, ensure_ascii=False, indent=2)
        os.replace(tmp, anchors_file)
    except Exception:
        try:
            os.unlink(tmp)
        except Exception:
            pass

# emit TEST_RESULT block 若命中 framework + (skipped 非零 或 errored 非零)
if framework_hit and (skip_match or err_match):
    passed = pass_match.group(1) if pass_match else "?"
    skipped = skip_match.group(1) if skip_match else "0"
    errored = err_match.group(1) if err_match else "0"
    print()
    print("<CLAIM_GROUND_TEST_RESULT>")
    print("[Claim Ground 🎯 — 测试输出含 skipped/errored / Test output contains skipped/errored]")
    print()
    print(f"刚跑的测试输出含: passed={passed}, skipped={skipped}, errored={errored}.")
    print()
    print("**\"X passed\" ≠ \"all tests ran\"**. 下一步必须：")
    print("1. 跑 verbose 看 skip/error 详情 (e.g., `pytest -v --tb=long` / `jest --verbose` / `go test -v`)")
    print("2. 区分 skip 类型（显式 @skip / 环境缺失 / 平台不兼容），后两者**不算 passed**")
    print("3. errored 必须修，不能忽略")
    print()
    print("**禁止**直接说\"所有测试通过\" / \"tests pass\" — 必须明示 skipped/errored 计数与原因。")
    print("</CLAIM_GROUND_TEST_RESULT>")
PYEOF

exit 0

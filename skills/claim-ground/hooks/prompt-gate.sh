#!/usr/bin/env bash
# Claim Ground prompt-gate — UserPromptSubmit dispatcher (v1.2)
#
# 检测用户输入中的 4 类风险模式：
#   - ambiguity (B): 模糊指令（路径/代词/数量/偏好/缺参数/缺 framework）
#   - hard_constraint (F): 用户表达硬约束（"不要 / 别 / 禁止 / don't / never"）
#   - scope_collapse (A4): 生态作用域问题（"最新/官方/最强 + 模型/版本"）
#
# Self-invocation guard: prompt 以 "/claim-ground" 开头时静默退出（用户手动调用）
# Mutual yield: 若命中 epistemic-pushback 或 frustration regex，让位给对应 hook
#
# 共享配置: references/matchers.json + references/reminders.json
# Exit 0 always — 不阻断，仅 inject context block

set +e
INPUT=$(cat 2>/dev/null || true)
[ -z "$INPUT" ] && exit 0

# Locate matchers.json + reminders.json relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MATCHERS_FILE="${SCRIPT_DIR}/../references/matchers.json"
REMINDERS_FILE="${SCRIPT_DIR}/../references/reminders.json"

[ -f "$MATCHERS_FILE" ] || exit 0
[ -f "$REMINDERS_FILE" ] || exit 0

python3 - "$INPUT" "$MATCHERS_FILE" "$REMINDERS_FILE" << 'PYEOF' 2>/dev/null || true
import json
import os
import re
import sys
import tempfile
from datetime import datetime, timezone

raw, matchers_path, reminders_path = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    payload = json.loads(raw)
except Exception:
    sys.exit(0)

prompt = payload.get("prompt", "")
if not prompt:
    sys.exit(0)

trimmed = prompt.lstrip()

with open(matchers_path, "r", encoding="utf-8") as fh:
    M = json.load(fh)
with open(reminders_path, "r", encoding="utf-8") as fh:
    R = json.load(fh)

# === Self-invocation guard ===
if re.search(M["self_invocation"], trimmed):
    sys.exit(0)

# === Mutual yield ===
if re.search(M["yield_to_pushback"], prompt, re.IGNORECASE):
    sys.exit(0)
if re.search(M["yield_to_frustration"], prompt, re.IGNORECASE):
    sys.exit(0)

emitted = []  # list of (block_key, format_kwargs)

# === Ambiguity matchers (B) ===
ambig = M.get("ambiguity", {})
for sub_key, pattern in ambig.items():
    try:
        if re.search(pattern, prompt, re.IGNORECASE):
            emitted.append(("AMBIGUITY", {"match_type": sub_key}))
            break  # 单次 prompt 只 emit 一个 ambiguity block
    except re.error:
        pass

# === Scope collapse (A4) ===
try:
    if re.search(M["scope_collapse"], prompt, re.IGNORECASE):
        emitted.append(("SCOPE_COLLAPSE", {}))
except re.error:
    pass

# === Hard constraint capture (F) ===
hc = M.get("hard_constraint", {})
constraint_match = None
for lang_key, pattern in hc.items():
    if lang_key == "cross_session_upgrade":
        continue
    try:
        m = re.search(pattern, prompt, re.IGNORECASE)
        if m:
            constraint_match = m
            break
    except re.error:
        pass

if constraint_match:
    # 写入 anchors.json hard_constraints[]
    forge_dir = os.path.expanduser("~/.forge")
    os.makedirs(forge_dir, exist_ok=True)
    anchors_file = os.path.join(forge_dir, "claim-ground-anchors.json")
    if os.path.isfile(anchors_file):
        try:
            with open(anchors_file, "r", encoding="utf-8") as fh:
                data = json.load(fh)
        except Exception:
            data = {}
    else:
        data = {}

    data.setdefault("session_id", "")
    data.setdefault("anchors", [])
    data.setdefault("user_corrections", [])
    data.setdefault("seen_paths", [])
    data.setdefault("hard_constraints", [])

    now = datetime.now(timezone.utc).isoformat()
    data["last_updated"] = now

    # 提取约束目标短语（关键词后到下一标点的片段）
    constraint_text = prompt[max(0, constraint_match.start() - 5):min(len(prompt), constraint_match.end() + 80)].strip()

    # cross-session 升级
    scope = "session"
    cross_pat = M["hard_constraint"].get("cross_session_upgrade", "")
    if cross_pat and re.search(cross_pat, prompt, re.IGNORECASE):
        scope = "cross-session"

    new_constraint = {
        "constraint": constraint_text[:200],
        "source_turn": data.get("_turn_count", 0) + 1,
        "source_text": prompt[:500],
        "captured_at": now,
        "expires_at": None,
        "scope": scope,
    }

    # dedup by constraint text
    if not any(c.get("constraint") == new_constraint["constraint"] for c in data["hard_constraints"]):
        data["hard_constraints"].append(new_constraint)

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

    constraints_list = "\n".join(f"  - [{c['scope']}] {c['constraint']}" for c in data["hard_constraints"][-5:])
    emitted.append(("HARD_CONSTRAINTS", {"constraints_list": constraints_list}))

# === Emit blocks ===
for block_key, kwargs in emitted:
    block = R.get(block_key, {})
    tag = block.get("tag", block_key)
    zh = block.get("zh", "")
    en = block.get("en", "")
    # Fill placeholders
    for k, v in kwargs.items():
        zh = zh.replace("{" + k + "}", str(v))
        en = en.replace("{" + k + "}", str(v))
    print()
    print(f"<{tag}>")
    print(zh)
    print()
    print("---")
    print()
    print(en)
    print(f"</{tag}>")
PYEOF

exit 0

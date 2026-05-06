#!/usr/bin/env bash
# Claim Ground session anchor — injects verified-fact digest at SessionStart
# Reads ~/.forge/claim-ground-anchors.json and emits an anchor block
# JSON engine: jq preferred, python fallback
# Schema: {session_id, anchors: [{key,value,source,verified_at}], user_corrections: [], last_updated}

ANCHORS_FILE="$HOME/.forge/claim-ground-anchors.json"
MAX_AGE_SECONDS=604800   # 7 days — anchors staler than this are skipped

if [ ! -f "$ANCHORS_FILE" ]; then
    exit 0
fi

# --- JSON engine abstraction (jq preferred, python fallback) ---
if command -v jq >/dev/null 2>&1; then
    JSON_ENGINE="jq"
elif command -v python3 >/dev/null 2>&1; then
    JSON_ENGINE="python"
elif command -v python >/dev/null 2>&1; then
    JSON_ENGINE="python"
else
    exit 0  # No JSON engine available, skip silently
fi

# Defensive parse — fall back to silent skip on corruption
if [ "$JSON_ENGINE" = "jq" ]; then
    if ! jq empty "$ANCHORS_FILE" 2>/dev/null; then
        exit 0
    fi
else
    if ! python3 -c "import json; json.load(open('$ANCHORS_FILE'))" >/dev/null 2>&1 \
     && ! python -c "import json; json.load(open('$ANCHORS_FILE'))" >/dev/null 2>&1; then
        exit 0
    fi
fi

# --- Age check ---
if [ "$JSON_ENGINE" = "jq" ]; then
    LAST_UPDATED=$(jq -r '.last_updated // ""' "$ANCHORS_FILE" 2>/dev/null)
else
    LAST_UPDATED=$(python3 -c "import json; d=json.load(open('$ANCHORS_FILE')); print(d.get('last_updated',''))" 2>/dev/null \
                || python  -c "import json; d=json.load(open('$ANCHORS_FILE')); print(d.get('last_updated',''))" 2>/dev/null)
fi

if [ -z "$LAST_UPDATED" ]; then
    exit 0
fi

if command -v date >/dev/null 2>&1; then
    THEN=$(date -d "$LAST_UPDATED" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$LAST_UPDATED" +%s 2>/dev/null || echo "0")
    NOW=$(date +%s)
    AGE=$(( NOW - THEN ))
else
    AGE=0
fi

if [ "$AGE" -gt "$MAX_AGE_SECONDS" ]; then
    exit 0
fi

# --- Build digest ---
if [ "$JSON_ENGINE" = "jq" ]; then
    ANCHOR_COUNT=$(jq '.anchors | length' "$ANCHORS_FILE" 2>/dev/null)
    CORRECTION_COUNT=$(jq '.user_corrections // [] | length' "$ANCHORS_FILE" 2>/dev/null)
    if [ "${ANCHOR_COUNT:-0}" = "0" ] && [ "${CORRECTION_COUNT:-0}" = "0" ]; then
        exit 0
    fi
    ANCHOR_LINES=$(jq -r '.anchors[]? | "  - \(.key): \"\(.value)\" [\(.source) @ \(.verified_at)]"' "$ANCHORS_FILE" 2>/dev/null)
    CORRECTION_LINES=$(jq -r '.user_corrections[]? | "  - was \"\(.wrong)\" → is \"\(.right)\" [\(.source)]"' "$ANCHORS_FILE" 2>/dev/null)
else
    # Python fallback — use single quotes inside f-string expressions
    # to avoid shell-escape complexity with nested double quotes.
    PY_CMD='import json
d=json.load(open("'"$ANCHORS_FILE"'"))
a=d.get("anchors",[]); c=d.get("user_corrections",[])
if not a and not c: raise SystemExit(1)
print("__ANCHORS__")
for x in a:
    k=x.get("key","?"); v=x.get("value","?"); s=x.get("source","?"); t=x.get("verified_at","?")
    print("  - " + k + ": \"" + v + "\" [" + s + " @ " + t + "]")
print("__CORRECTIONS__")
for x in c:
    w=x.get("wrong","?"); r=x.get("right","?"); s=x.get("source","?")
    print("  - was \"" + w + "\" -> is \"" + r + "\" [" + s + "]")'
    OUT=$(python3 -c "$PY_CMD" 2>/dev/null) || OUT=$(python -c "$PY_CMD" 2>/dev/null) || exit 0
    ANCHOR_LINES=$(echo "$OUT" | sed -n '/^__ANCHORS__$/,/^__CORRECTIONS__$/p' | sed '1d;$d')
    CORRECTION_LINES=$(echo "$OUT" | sed -n '/^__CORRECTIONS__$/,$p' | sed '1d')
fi

# --- Emit digest (nothing shown if both lists empty; already returned above) ---
cat << EOF

<CLAIM_GROUND_ANCHORS>
[Claim Ground 🎯 — 已验证事实锚点已加载 / Verified-fact anchors restored]

These facts were cited to runtime evidence in a prior turn or session. Treat
them as verified priors for this session — do NOT re-assert them from memory
alone, but you MAY cite them directly when the same question recurs.

以下事实在上一轮/上一会话已经通过 runtime 证据验证过。本会话视为已知锚点；
同类问题可以直接引用，但不得凭记忆重新断言。

${ANCHOR_LINES:+Anchors:
${ANCHOR_LINES}
}${CORRECTION_LINES:+Prior user corrections (respect these):
${CORRECTION_LINES}
}
> Last updated: ${LAST_UPDATED}
> Source schema: skills/claim-ground/references/anchors.md
</CLAIM_GROUND_ANCHORS>
EOF

# === v1.2 extension: seen_paths + hard_constraints + needs_reconfirm ===
# Single python pass: emit additional reminder blocks + mark stale anchors
python3 - "$ANCHORS_FILE" << 'PYEOF' 2>/dev/null || true
import json
import os
import sys
import tempfile
from datetime import datetime, timezone, timedelta

f = sys.argv[1]
if not os.path.isfile(f):
    sys.exit(0)
try:
    with open(f, "r", encoding="utf-8") as fh:
        d = json.load(fh)
except Exception:
    sys.exit(0)

now = datetime.now(timezone.utc)
modified = False

# (a) Mark anchors needs_reconfirm if verified_at > 24h ago
for a in d.get("anchors", []):
    va = a.get("verified_at", "")
    try:
        when = datetime.fromisoformat(va.replace("Z", "+00:00"))
        if (now - when) > timedelta(hours=24):
            if not a.get("needs_reconfirm"):
                a["needs_reconfirm"] = True
                modified = True
    except Exception:
        pass

# (b) Collect unverified seen_paths (cap 10 most recent)
unverified = [p for p in d.get("seen_paths", []) if not p.get("verified", False)]
unverified = unverified[-10:]

# (c) Collect non-expired hard_constraints
constraints = []
for c in d.get("hard_constraints", []):
    exp = c.get("expires_at")
    if exp:
        try:
            when = datetime.fromisoformat(exp.replace("Z", "+00:00"))
            if when < now:
                continue
        except Exception:
            pass
    constraints.append(c)

# Emit SEEN_PATHS block if any
if unverified:
    print()
    print("<CLAIM_GROUND_SEEN_PATHS>")
    print("[Claim Ground 🎯 — 已见但未验证路径 / Paths seen but not verified]")
    print()
    print("下列路径在过往 tool 输出里出现过但**未独立验证**——视作候选，不是锚点：")
    print("These paths appeared in tool results but were NOT independently verified:")
    print()
    for p in unverified:
        print(f"  - {p['path']} (seen via {p['source_tool']} @ {p['seen_at']})")
    print()
    print("当用户提到这些名字时，必须先跑 `which`/`ls` 验证再行动。")
    print("**\"出现 ≠ 锚定\"** — 见 references/red-lines.md §红线 8。")
    print("</CLAIM_GROUND_SEEN_PATHS>")

# Emit HARD_CONSTRAINTS block if any
if constraints:
    print()
    print("<CLAIM_GROUND_HARD_CONSTRAINTS>")
    print("[Claim Ground 🎯 — 已激活的硬约束 / Active hard constraints]")
    print()
    print("用户在过往 turn 表达过下列硬约束（仍生效）：")
    print("User expressed the following hard constraints (still in effect):")
    print()
    for c in constraints:
        scope = c.get("scope", "session")
        text = c.get("constraint", "?")
        turn = c.get("source_turn", "?")
        print(f"  - [{scope}] {text} (turn {turn})")
    print()
    print("规则：即将做的动作若**潜在违反**任一条 → 必须在回答里明示提醒并请用户确认。")
    print("Rules: If your planned action POTENTIALLY violates any constraint → flag it.")
    print("</CLAIM_GROUND_HARD_CONSTRAINTS>")

# Atomic write back if modified
if modified:
    try:
        forge_dir = os.path.dirname(f)
        fd, tmp = tempfile.mkstemp(prefix="claim-ground-anchors.", dir=forge_dir, suffix=".tmp")
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(d, fh, ensure_ascii=False, indent=2)
        os.replace(tmp, f)
    except Exception:
        try:
            os.unlink(tmp)
        except Exception:
            pass
PYEOF

exit 0

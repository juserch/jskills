#!/usr/bin/env bash
# Claim Ground pre-tool-gate — PreToolUse dispatcher (v1.2)
#
# 在 Bash / Edit / Write 工具调用前检测 3 类风险：
#   - destructive (C): rm -rf / reset --hard / push --force / DROP TABLE / kill -9 等
#   - scope_creep (E): Edit/Write 路径未在最近 3 turn 用户消息中出现
#   - env_var (D6): Bash/Edit 命令含 $VAR 但前序无 echo $VAR
#
# 共享配置: references/matchers.json + references/reminders.json
# Exit 0 always — 不阻断，仅 inject context block

set +e
INPUT=$(cat 2>/dev/null || true)
[ -z "$INPUT" ] && exit 0

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

raw, matchers_path, reminders_path = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    payload = json.loads(raw)
except Exception:
    sys.exit(0)

tool_name = payload.get("tool_name", "")
tool_input = payload.get("tool_input", {})
if not isinstance(tool_input, dict):
    tool_input = {}

with open(matchers_path, "r", encoding="utf-8") as fh:
    M = json.load(fh)
with open(reminders_path, "r", encoding="utf-8") as fh:
    R = json.load(fh)

emitted = []  # list of (block_key, kwargs)

# === C: Destructive matcher (Bash 命令) ===
if tool_name == "Bash":
    cmd = tool_input.get("command", "")
    if cmd:
        for sub_key, pattern in M.get("destructive", {}).items():
            try:
                if re.search(pattern, cmd, re.IGNORECASE):
                    emitted.append(("DESTRUCTIVE", {
                        "command": cmd[:200],
                        "match_type": sub_key,
                    }))
                    break
            except re.error:
                pass

# === D6: env var unverified（Bash command 或 Edit/Write content） ===
content_to_scan = ""
if tool_name == "Bash":
    content_to_scan = tool_input.get("command", "")
elif tool_name in ("Edit", "Write"):
    content_to_scan = tool_input.get("new_string", "") or tool_input.get("content", "")

if content_to_scan:
    # 简化判定：若 content 含 $VAR 且 recent_user_turns / 前序无 echo $VAR → 提醒
    var_pattern = re.compile(r"\$([A-Z_][A-Z0-9_]*)")
    found_vars = set(var_pattern.findall(content_to_scan))
    # 排除常见已验证或不需验证的 env vars
    common_excluded = {"PATH", "HOME", "USER", "PWD", "SHELL", "TERM", "LANG", "LC_ALL", "PS1", "SHLVL", "OLDPWD"}
    suspect = found_vars - common_excluded
    if suspect:
        # 检查 recent_user_turns 是否含 echo $VAR
        recent_turns = payload.get("recent_user_turns", [])
        recent_str = " ".join(str(t) for t in recent_turns) if isinstance(recent_turns, list) else str(recent_turns)
        verified_vars = set()
        for var in suspect:
            if re.search(r"echo\s+[\"']?\$\{?" + re.escape(var), recent_str):
                verified_vars.add(var)
        unverified = suspect - verified_vars
        if unverified:
            emitted.append(("ENV_VAR", {
                "var_name": next(iter(unverified)),
            }))

# === E: scope_creep — Edit/Write file_path 未在最近 user turns 出现 ===
if tool_name in ("Edit", "Write"):
    file_path = tool_input.get("file_path", "")
    if file_path:
        recent_turns = payload.get("recent_user_turns", [])
        if isinstance(recent_turns, list) and recent_turns:
            recent_str = " ".join(str(t) for t in recent_turns)
            basename = os.path.basename(file_path)
            # 命中：完整路径 / basename / 父目录 在 user turns 中提及
            mentioned = (file_path in recent_str) or (basename in recent_str) or any(
                part in recent_str for part in file_path.split("/") if len(part) > 3
            )
            # 批量指令豁免
            batch_pattern = re.compile(r"(all\s+\*?\.\w+|整个|全局|every\s+\w+|批量)", re.IGNORECASE)
            is_batch = bool(batch_pattern.search(recent_str))
            if not mentioned and not is_batch:
                emitted.append(("SCOPE_CREEP", {
                    "file_path": file_path,
                }))

# === Emit blocks ===
for block_key, kwargs in emitted:
    block = R.get(block_key, {})
    tag = block.get("tag", block_key)
    zh = block.get("zh", "")
    en = block.get("en", "")
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

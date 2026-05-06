#!/usr/bin/env bash
# Claim Ground Triggering Test
# Tests whether the skill triggers on correct prompts and doesn't trigger on incorrect ones
#
# Usage: ./run-trigger-test.sh [--plugin-dir <path>]
# Requires: claude CLI

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="${1:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
RESULTS_DIR="/tmp/claim-ground-evals/$(date +%s)"
mkdir -p "$RESULTS_DIR"

echo "=== Claim Ground Trigger Tests ==="
echo "Plugin dir: $PLUGIN_DIR"
echo "Results: $RESULTS_DIR"
echo ""

PASS=0
FAIL=0

test_prompt() {
    local prompt="$1"
    local should_trigger="$2"
    local label="$3"
    local outfile="$RESULTS_DIR/$(echo "$label" | tr ' ' '_').json"

    timeout 120 claude -p "$prompt" \
        --plugin-dir "$PLUGIN_DIR" \
        --dangerously-skip-permissions \
        --max-turns 2 \
        --output-format stream-json \
        --verbose \
        > "$outfile" 2>&1 || true

    local triggered=false
    if grep -q '"skill":"claim-ground"' "$outfile" 2>/dev/null; then
        triggered=true
    fi

    if [ "$should_trigger" = "yes" ] && [ "$triggered" = "true" ]; then
        echo "  ✅ PASS: $label (correctly triggered)"
        PASS=$((PASS + 1))
    elif [ "$should_trigger" = "no" ] && [ "$triggered" = "false" ]; then
        echo "  ✅ PASS: $label (correctly NOT triggered)"
        PASS=$((PASS + 1))
    elif [ "$should_trigger" = "yes" ] && [ "$triggered" = "false" ]; then
        echo "  ❌ FAIL: $label (should trigger but didn't)"
        FAIL=$((FAIL + 1))
    else
        echo "  ❌ FAIL: $label (should NOT trigger but did)"
        FAIL=$((FAIL + 1))
    fi
}

echo "--- Should Trigger ---"
test_prompt "What is the current model running?" "yes" "current-model"
test_prompt "当前运行的模型是什么？" "yes" "current-model-zh"
test_prompt "What version of the claude CLI is installed?" "yes" "cli-version"
test_prompt "Which packages are installed globally via npm?" "yes" "installed-packages"
test_prompt "真的吗？我记得已经更新到 4.7 了" "yes" "user-pushback-zh"
test_prompt "Are you sure? I thought it was updated" "yes" "user-pushback-en"
test_prompt "What's in my PATH env var?" "yes" "env-var-query"
test_prompt "本当に？最新モデルが更新されたと思います" "yes" "user-pushback-ja"
test_prompt "¿en serio? ya pensaba que se había actualizado" "yes" "user-pushback-es"
test_prompt "wait, I thought that was already changed" "yes" "implicit-pushback-en"
test_prompt "不对，最新是 Opus 5.0，官方博客：https://anthropic.com/news/opus-5-release" "yes" "cited-url-pushback"
test_prompt "claude CLI 支持哪些模型？" "yes" "cli-model-list-scan"
test_prompt "axios 里怎么设置全局请求超时？" "yes" "code-api-assertion"
test_prompt "Claude API 怎么取消 batch？给我官方文档链接" "yes" "cited-url-required"
test_prompt "summarize CLAUDE.md" "yes" "summarize-file-anchor"

echo ""
echo "--- Should NOT Trigger ---"
test_prompt "Tell me a joke" "no" "casual-chat"
test_prompt "What's the difference between list and tuple in Python?" "no" "training-knowledge"
test_prompt "Help me refactor this function" "no" "coding-task"
test_prompt "Explain the bubble sort algorithm" "no" "algorithm-explain"
test_prompt "/news-fetch AI" "no" "other-skill-command"
test_prompt "promise 和 async/await 的概念区别是什么？" "no" "conceptual-explain"

echo ""
echo "=== Claude CLI prompt-level Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Total:  $((PASS + FAIL))"
echo "Results dir: $RESULTS_DIR"

# === v1.2 Hook unit tests (do not require claude CLI) ===
echo ""
echo "=== v1.2 Hook Unit Tests (Claude Code bash hooks) ==="

HOOK_PASS=0
HOOK_FAIL=0
HOOK_DIR="$PLUGIN_DIR/skills/claim-ground/hooks"

hook_test() {
    local desc="$1" hook="$2" input="$3" pattern="$4" expect_count="$5"
    if [ ! -f "$HOOK_DIR/$hook" ]; then
        echo "  ⚠ SKIP: $desc (hook missing: $hook)"
        return
    fi
    local actual
    actual=$(printf '%s' "$input" | bash "$HOOK_DIR/$hook" 2>/dev/null | grep -c "$pattern" || true)
    if [ "$actual" -eq "$expect_count" ]; then
        echo "  ✅ PASS: $desc"
        HOOK_PASS=$((HOOK_PASS + 1))
    else
        echo "  ❌ FAIL: $desc (expect=$expect_count got=$actual)"
        HOOK_FAIL=$((HOOK_FAIL + 1))
    fi
}

# Reset shared state for clean tests
rm -f ~/.forge/claim-ground-anchors.json

# B 模糊指令
hook_test "37 B1 path_env"        prompt-gate.sh '{"prompt":"把 forge 更新到 openclaw 环境"}' "CLAIM_GROUND_AMBIGUITY" 2
hook_test "38 B2 vague_pronoun"   prompt-gate.sh '{"prompt":"把它优化一下"}'                  "CLAIM_GROUND_AMBIGUITY" 2
hook_test "39 B3 fuzzy_quantifier"  prompt-gate.sh '{"prompt":"备份重要文件"}'                "CLAIM_GROUND_AMBIGUITY" 2
hook_test "40 B5 missing_param"   prompt-gate.sh '{"prompt":"部署到生产"}'                    "CLAIM_GROUND_AMBIGUITY" 2

# C 破坏性
hook_test "41 C1 rm -rf"          pre-tool-gate.sh '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/foo"}}' "CLAIM_GROUND_DESTRUCTIVE" 2
hook_test "42 C2 push --force"    pre-tool-gate.sh '{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}' "CLAIM_GROUND_DESTRUCTIVE" 2
hook_test "43 C 安全变体不触发"   pre-tool-gate.sh '{"tool_name":"Bash","tool_input":{"command":"git push --force-with-lease origin main"}}' "CLAIM_GROUND_DESTRUCTIVE" 0

# D5+D6
hook_test "44 D5 测试输出"        evidence-reminder.sh '{"tool_name":"Bash","tool_output":"pytest 5 passed, 3 skipped, 1 error in 2.5s"}' "CLAIM_GROUND_TEST_RESULT" 2
hook_test "45 D6 env var"         pre-tool-gate.sh '{"tool_name":"Bash","tool_input":{"command":"curl $API_KEY"},"recent_user_turns":["写脚本"]}' "CLAIM_GROUND_ENV_VAR" 2
hook_test "46 D6 已 echo 豁免"    pre-tool-gate.sh '{"tool_name":"Bash","tool_input":{"command":"curl $API_KEY"},"recent_user_turns":["echo $API_KEY"]}' "CLAIM_GROUND_ENV_VAR" 0

# E scope creep
hook_test "47 E scope creep"      pre-tool-gate.sh '{"tool_name":"Edit","tool_input":{"file_path":"src/bar.ts"},"recent_user_turns":["改 src/foo.ts"]}' "CLAIM_GROUND_SCOPE_CREEP" 2
hook_test "48 E 批量豁免"         pre-tool-gate.sh '{"tool_name":"Edit","tool_input":{"file_path":"src/bar.ts"},"recent_user_turns":["refactor all *.ts files"]}' "CLAIM_GROUND_SCOPE_CREEP" 0

# F 硬约束
hook_test "49 F hard_constraint"  prompt-gate.sh '{"prompt":"不要碰 auth 模块"}' "CLAIM_GROUND_HARD_CONSTRAINTS" 2

# A4 scope_collapse
hook_test "52 A4 最新模型"        prompt-gate.sh '{"prompt":"Anthropic 当前最强的模型是什么"}' "CLAIM_GROUND_SCOPE_COLLAPSE" 2
hook_test "53 A4 本地作用域不触发" prompt-gate.sh '{"prompt":"hello"}' "CLAIM_GROUND_SCOPE_COLLAPSE" 0

# A1 路径写入 + SEEN_PATHS 注入
hook_test "54 路径写入 seen_paths" evidence-reminder.sh '{"tool_name":"Bash","tool_output":"foo /home/user/.openclaw/skills/foo bar"}' "CLAIM_GROUND_EVIDENCE_REMINDER" 2

# v1.1 不破坏
hook_test "v1.1 epistemic-pushback 仍 emit" epistemic-pushback-trigger.sh '{"prompt":"真的吗？"}' "CLAIM_GROUND_ACTIVATED" 2

# Self-invocation guard
hook_test "self-invocation guard"  prompt-gate.sh '{"prompt":"/claim-ground verify openclaw"}' "CLAIM_GROUND_" 0
hook_test "yield to pushback"      prompt-gate.sh '{"prompt":"真的吗？openclaw 不是在 ~/.claude/ 吗"}' "CLAIM_GROUND_" 0

echo ""
echo "=== Hook Unit Test Results ==="
echo "Passed: $HOOK_PASS"
echo "Failed: $HOOK_FAIL"
echo "Total:  $((HOOK_PASS + HOOK_FAIL))"

# === v1.2 OpenClaw conditional e2e ===
echo ""
echo "=== v1.2 OpenClaw Handler Tests (conditional) ==="

OC_PASS=0
OC_FAIL=0

if ! command -v openclaw >/dev/null 2>&1; then
    echo "  ⏭  SKIPPED: openclaw binary not found in PATH"
elif ! command -v node >/dev/null 2>&1; then
    echo "  ⏭  SKIPPED: node not found in PATH"
else
    OC_TEST_FILE="$RESULTS_DIR/openclaw-handlers.mjs"
    cat > "$OC_TEST_FILE" << 'OCEOF'
import { fileURLToPath } from "node:url";
import * as path from "node:path";
import * as fs from "node:fs";
import * as os from "node:os";

const REPO = process.argv[2];
const HOOKS = path.join(REPO, "platforms/openclaw/claim-ground/hooks/openclaw");
const ANCHORS = path.join(os.homedir(), ".forge", "claim-ground-anchors.json");

async function loadHandler(hookName) {
  const handlerPath = path.join(HOOKS, hookName, "handler.js");
  const url = "file://" + handlerPath;
  const mod = await import(url);
  return mod.default || mod[Object.keys(mod)[0]];
}

let pass = 0, fail = 0;
function check(label, cond) {
  if (cond) { console.log("  ✅ OC PASS: " + label); pass++; }
  else { console.log("  ❌ OC FAIL: " + label); fail++; }
}

try { fs.rmSync(ANCHORS); } catch {}

const promptGate = await loadHandler("prompt-gate");
const r1 = await promptGate({type:"message",action:"received",context:{content:"把 forge 更新到 openclaw 环境",from:"t",channelId:"t"}});
check("prompt-gate B1 (message:received)", r1 && r1.injectContext && r1.injectContext.includes("CLAIM_GROUND_AMBIGUITY"));

const r2 = await promptGate({type:"message",action:"received",context:{content:"不要碰 auth 模块",from:"t",channelId:"t"}});
check("prompt-gate F hard_constraint", r2 && r2.injectContext && r2.injectContext.includes("CLAIM_GROUND_HARD_CONSTRAINTS"));

const epPushback = await loadHandler("epistemic-pushback");
const r6 = await epPushback({type:"message",action:"received",context:{content:"真的吗？",from:"t",channelId:"t"}});
check("epistemic-pushback fires", r6 && r6.injectContext && r6.injectContext.includes("CLAIM_GROUND_ACTIVATED"));

const sessionAnchor = await loadHandler("session-anchor");
const r9 = await sessionAnchor({type:"agent",action:"bootstrap",context:{workspaceDir:"/tmp",bootstrapFiles:[]}});
check("session-anchor reads shared anchors.json", r9 && r9.injectContext && r9.injectContext.includes("CLAIM_GROUND_HARD_CONSTRAINTS"));

console.log("\n  ===== OpenClaw: PASS=" + pass + " FAIL=" + fail + " =====");
process.exit(fail === 0 ? 0 : 1);
OCEOF
    if node "$OC_TEST_FILE" "$PLUGIN_DIR" 2>&1; then
        OC_PASS=$((OC_PASS + 4))
    else
        OC_FAIL=$((OC_FAIL + 1))
    fi
fi

echo ""
echo "=== Combined Test Summary ==="
TOTAL_PASS=$((PASS + HOOK_PASS + OC_PASS))
TOTAL_FAIL=$((FAIL + HOOK_FAIL + OC_FAIL))
echo "Claude CLI prompts: $PASS pass / $FAIL fail"
echo "Hook unit:          $HOOK_PASS pass / $HOOK_FAIL fail"
echo "OpenClaw e2e:       $OC_PASS pass / $OC_FAIL fail"
echo "Grand total:        $TOTAL_PASS pass / $TOTAL_FAIL fail"

# Hook unit tests must pass; Claude CLI tests are best-effort（可能无 API 凭证 / 超时）
if [ "$HOOK_FAIL" -gt 0 ] || [ "$OC_FAIL" -gt 0 ]; then
    exit 1
fi

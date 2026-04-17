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

echo ""
echo "--- Should NOT Trigger ---"
test_prompt "Tell me a joke" "no" "casual-chat"
test_prompt "What's the difference between list and tuple in Python?" "no" "training-knowledge"
test_prompt "Help me refactor this function" "no" "coding-task"
test_prompt "Explain the bubble sort algorithm" "no" "algorithm-explain"
test_prompt "/news-fetch AI" "no" "other-skill-command"

echo ""
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Total:  $((PASS + FAIL))"
echo "Results dir: $RESULTS_DIR"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi

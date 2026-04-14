#!/usr/bin/env bash
# council-fuse trigger test
# Validates that the skill is properly registered and structurally sound

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== council-fuse Trigger Test ==="
echo ""

# Test 1: SKILL.md exists and has correct frontmatter
echo "[1/5] Checking SKILL.md..."
SKILL_FILE="$PROJECT_ROOT/skills/council-fuse/SKILL.md"
if [ ! -f "$SKILL_FILE" ]; then
  echo "  FAIL: $SKILL_FILE not found"
  exit 1
fi
if ! grep -q "^name: council-fuse" "$SKILL_FILE"; then
  echo "  FAIL: frontmatter missing 'name: council-fuse'"
  exit 1
fi
echo "  PASS"

# Test 2: Agent definitions exist
echo "[2/5] Checking agent definitions..."
for agent in council-generalist council-critic council-specialist; do
  AGENT_FILE="$PROJECT_ROOT/skills/council-fuse/agents/$agent.md"
  if [ ! -f "$AGENT_FILE" ]; then
    echo "  FAIL: $AGENT_FILE not found"
    exit 1
  fi
done
echo "  PASS"

# Test 3: References exist
echo "[3/5] Checking references..."
for ref in council-protocol synthesis-methodology; do
  REF_FILE="$PROJECT_ROOT/skills/council-fuse/references/$ref.md"
  if [ ! -f "$REF_FILE" ]; then
    echo "  FAIL: $REF_FILE not found"
    exit 1
  fi
done
echo "  PASS"

# Test 4: Marketplace registration
echo "[4/5] Checking marketplace.json..."
MARKETPLACE="$PROJECT_ROOT/.claude-plugin/marketplace.json"
if ! grep -q "council-fuse" "$MARKETPLACE"; then
  echo "  FAIL: council-fuse not found in marketplace.json"
  exit 1
fi
echo "  PASS"

# Test 5: OpenClaw platform adaptation
echo "[5/5] Checking OpenClaw adaptation..."
OC_SKILL="$PROJECT_ROOT/platforms/openclaw/council-fuse/SKILL.md"
if [ ! -f "$OC_SKILL" ]; then
  echo "  FAIL: $OC_SKILL not found"
  exit 1
fi
echo "  PASS"

echo ""
echo "=== All 5 checks passed ==="

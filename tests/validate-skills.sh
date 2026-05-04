#!/usr/bin/env bash

# Validate openstack-k8s-operators Operator Tools skills against a real operator
# Usage: ./tests/validate-skills.sh [operator-repo-url]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
REPO_URL="${1:-https://github.com/openstack-k8s-operators/glance-operator.git}"
OPERATOR_NAME="$(basename "$REPO_URL" .git)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
SKIP=0

pass() { echo -e "  ${GREEN}PASS${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}FAIL${NC} $1"; FAIL=$((FAIL + 1)); }
skip() { echo -e "  ${YELLOW}SKIP${NC} $1"; SKIP=$((SKIP + 1)); }

# Setup
TMPDIR=$(mktemp -d)
OPERATOR_DIR="$TMPDIR/$OPERATOR_NAME"
trap "rm -rf $TMPDIR" EXIT

echo -e "${BLUE}Validating skills against $OPERATOR_NAME${NC}"
echo "================================================"
echo

# Clone
echo -e "${BLUE}[Setup] Cloning $OPERATOR_NAME...${NC}"
if git clone --depth 1 "$REPO_URL" "$OPERATOR_DIR" &>/dev/null; then
    pass "Clone $OPERATOR_NAME"
else
    fail "Clone $OPERATOR_NAME"
    exit 1
fi
echo

# --- test-operator ---
echo -e "${BLUE}[test-operator] Quick tests (fmt+vet+tidy)${NC}"
if (cd "$OPERATOR_DIR" && "$SCRIPT_DIR/lib/test-workflow.sh" quick &>/dev/null); then
    pass "test-operator quick"
else
    fail "test-operator quick"
fi

echo -e "${BLUE}[test-operator] Help output${NC}"
if "$SCRIPT_DIR/lib/test-workflow.sh" help &>/dev/null; then
    pass "test-operator help"
else
    fail "test-operator help"
fi
echo

# --- debug-operator ---
echo -e "${BLUE}[debug-operator] Show tests${NC}"
OUTPUT=$(cd "$OPERATOR_DIR" && "$SCRIPT_DIR/lib/dev-workflow.sh" show_tests 2>&1)
if echo "$OUTPUT" | grep -q "_test.go"; then
    pass "debug-operator show_tests (found test files)"
else
    fail "debug-operator show_tests"
fi

echo -e "${BLUE}[debug-operator] Validate CRDs${NC}"
OUTPUT=$(cd "$OPERATOR_DIR" && "$SCRIPT_DIR/lib/dev-workflow.sh" crds 2>&1)
if echo "$OUTPUT" | grep -q "is valid"; then
    pass "debug-operator validate_crds"
else
    fail "debug-operator validate_crds"
fi

echo -e "${BLUE}[debug-operator] Check Go modules${NC}"
if (cd "$OPERATOR_DIR" && "$SCRIPT_DIR/lib/dev-workflow.sh" modules &>/dev/null); then
    pass "debug-operator check_go_modules"
else
    fail "debug-operator check_go_modules"
fi

echo -e "${BLUE}[debug-operator] Help output${NC}"
if "$SCRIPT_DIR/lib/dev-workflow.sh" help &>/dev/null; then
    pass "debug-operator help"
else
    fail "debug-operator help"
fi
echo

echo

# --- explain-flow ---
echo -e "${BLUE}[explain-flow] Parse controllers${NC}"
CONTROLLER_DIR=$(find "$OPERATOR_DIR" -type d -name "controller" -not -path "*/vendor/*" | head -1)
if [ -n "$CONTROLLER_DIR" ]; then
    OUTPUT=$(python3 "$SCRIPT_DIR/lib/code-parser.py" "$CONTROLLER_DIR" 2>&1)
    CONTROLLERS=$(echo "$OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d['controllers']))" 2>/dev/null || echo "0")
    if [ "$CONTROLLERS" -gt 0 ]; then
        pass "explain-flow found $CONTROLLERS controllers"
    else
        fail "explain-flow found no controllers"
    fi

    # Check reconciler flow extraction
    STEPS=$(echo "$OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(sum(len(f['steps']) for r in d['reconcilers'] for f in r['flows']))" 2>/dev/null || echo "0")
    if [ "$STEPS" -gt 0 ]; then
        pass "explain-flow extracted $STEPS flow steps"
    else
        fail "explain-flow extracted no flow steps"
    fi
else
    skip "explain-flow (no controller directory found)"
fi

echo -e "${BLUE}[explain-flow] Parse full repo (CRDs, webhooks, main)${NC}"
OUTPUT=$(python3 "$SCRIPT_DIR/lib/code-parser.py" "$OPERATOR_DIR" 2>&1)
CRDS=$(echo "$OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d['crds']))" 2>/dev/null || echo "0")
WEBHOOKS=$(echo "$OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d['webhooks']))" 2>/dev/null || echo "0")
MAIN=$(echo "$OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if d['main'] else 'no')" 2>/dev/null || echo "no")

[ "$CRDS" -gt 0 ] && pass "explain-flow found $CRDS CRDs" || fail "explain-flow found no CRDs"
[ "$WEBHOOKS" -gt 0 ] && pass "explain-flow found $WEBHOOKS webhook files" || skip "explain-flow no webhooks"
[ "$MAIN" = "yes" ] && pass "explain-flow found main.go" || fail "explain-flow main.go not found"
echo

# --- analyze-logs ---
echo -e "${BLUE}[analyze-logs] Analyze sample logs (stdin)${NC}"
SAMPLE_LOGS='E0324 10:15:32.123456 1 controller.go:42] Reconciler error: connection refused
W0324 10:15:33.234567 1 controller.go:55] Requeuing after error
I0324 10:15:34.345678 1 glance_controller.go:89] Reconciling Glance instance
E0324 10:15:35.456789 1 glance_controller.go:120] Failed to create ConfigMap: permission denied
I0324 10:15:37.678901 1 glance_controller.go:140] Successfully reconciled Glance'

OUTPUT=$(echo "$SAMPLE_LOGS" | python3 "$SCRIPT_DIR/lib/log-analyzer.py" - 2>&1)
if echo "$OUTPUT" | grep -q "Log Analysis Summary"; then
    pass "analyze-logs stdin processing"
else
    fail "analyze-logs stdin processing"
fi

if echo "$OUTPUT" | grep -q "Errors: [1-9]"; then
    pass "analyze-logs detected errors"
else
    fail "analyze-logs error detection"
fi

echo -e "${BLUE}[analyze-logs] Analyze from file${NC}"
LOGFILE="$TMPDIR/test.log"
echo "$SAMPLE_LOGS" > "$LOGFILE"
OUTPUT=$(python3 "$SCRIPT_DIR/lib/log-analyzer.py" "$LOGFILE" 2>&1)
if echo "$OUTPUT" | grep -q "Log Analysis Summary"; then
    pass "analyze-logs file processing"
else
    fail "analyze-logs file processing"
fi

echo -e "${BLUE}[analyze-logs] JSON output${NC}"
OUTPUT=$(echo "$SAMPLE_LOGS" | python3 "$SCRIPT_DIR/lib/log-analyzer.py" --json - 2>&1)
if echo "$OUTPUT" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    pass "analyze-logs JSON output is valid"
else
    fail "analyze-logs JSON output"
fi

echo -e "${BLUE}[analyze-logs] Pattern listing${NC}"
if python3 "$SCRIPT_DIR/lib/log-analyzer.py" --patterns 2>&1 | grep -q "Error patterns\|error_patterns\|Available patterns"; then
    pass "analyze-logs --patterns"
else
    fail "analyze-logs --patterns"
fi
echo

# --- Summary ---
TOTAL=$((PASS + FAIL + SKIP))
echo "================================================"
echo -e "${BLUE}Validation Summary${NC}"
echo "================================================"
echo -e "Total:   $TOTAL"
echo -e "Passed:  ${GREEN}$PASS${NC}"
echo -e "Failed:  ${RED}$FAIL${NC}"
echo -e "Skipped: ${YELLOW}$SKIP${NC}"
echo

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}All validations passed!${NC}"
    exit 0
else
    echo -e "${RED}$FAIL validation(s) failed${NC}"
    exit 1
fi

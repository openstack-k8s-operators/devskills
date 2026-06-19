#!/bin/bash
# Validate eval directory structure and configuration.

set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
EVALS_DIR="$REPO_ROOT/evals"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

errors=0
warnings=0
checks=0

pass() { echo -e "  ${GREEN}PASS${NC} $1"; checks=$((checks + 1)); }
fail() { echo -e "  ${RED}FAIL${NC} $1"; errors=$((errors + 1)); checks=$((checks + 1)); }
warn() { echo -e "  ${YELLOW}WARN${NC} $1"; warnings=$((warnings + 1)); checks=$((checks + 1)); }

if [[ ! -d "$EVALS_DIR" ]]; then
    echo -e "${RED}No evals/ directory found${NC}"
    exit 1
fi

# check_yaml_field checks that a top-level YAML key exists in the given file.
# Matches "key:" at the start of a line (no leading whitespace), which is
# sufficient for the flat structure of eval.yaml without requiring PyYAML.
check_yaml_field() {
    local file="$1"
    local field="$2"
    grep -qE "^${field}:" "$file"
}

eval_count=0

for eval_dir in "$EVALS_DIR"/*/; do
    [[ -d "$eval_dir" ]] || continue
    skill=$(basename "$eval_dir")
    echo "Checking evals/$skill/"
    eval_count=$((eval_count + 1))

    # --- Required files ---

    if [[ -f "$eval_dir/eval.yaml" ]]; then
        pass "eval.yaml exists"
    else
        fail "eval.yaml missing"
        continue
    fi

    if [[ -f "$eval_dir/prompt.txt" ]]; then
        pass "prompt.txt exists"
    else
        fail "prompt.txt missing"
    fi

    if [[ -f "$eval_dir/README.md" ]]; then
        pass "README.md exists"
    else
        warn "README.md missing"
    fi

    # --- eval.yaml required fields ---

    missing_fields=()
    for field in description providers tests; do
        if ! check_yaml_field "$eval_dir/eval.yaml" "$field"; then
            missing_fields+=("$field")
        fi
    done

    if [[ ${#missing_fields[@]} -eq 0 ]]; then
        pass "eval.yaml has required fields (description, providers, tests)"
    else
        fail "eval.yaml missing required fields: ${missing_fields[*]}"
    fi

    # --- graders/ directory ---

    if [[ -d "$eval_dir/graders" ]]; then
        grader_count=0
        for grader in "$eval_dir"/graders/*.py; do
            [[ -f "$grader" ]] || continue
            grader_name=$(basename "$grader")
            grader_count=$((grader_count + 1))
            if grep -q "def get_assert" "$grader"; then
                pass "graders/$grader_name defines get_assert()"
            else
                fail "graders/$grader_name missing get_assert() function"
            fi
        done
        if [[ $grader_count -eq 0 ]]; then
            warn "graders/ is empty — no .py files"
        fi
    else
        warn "graders/ directory missing"
    fi

    # --- fixtures/ directory ---

    if [[ -d "$eval_dir/fixtures" ]]; then
        fixture_count=$(find "$eval_dir/fixtures" -type f | wc -l)
        if [[ $fixture_count -gt 0 ]]; then
            pass "fixtures/ has $fixture_count file(s)"
        else
            warn "fixtures/ is empty"
        fi
    else
        warn "fixtures/ directory missing"
    fi

    # --- Corresponding skill exists ---

    if [[ -f "$REPO_ROOT/skills/$skill/SKILL.md" ]]; then
        pass "skills/$skill/SKILL.md exists"
    else
        warn "no matching skill — skills/$skill/SKILL.md not found"
    fi

    echo ""
done

if [[ $eval_count -eq 0 ]]; then
    echo -e "${YELLOW}No eval directories found under evals/${NC}"
    exit 0
fi

passed=$((checks - errors - warnings))
echo "---"
echo -e "Checked $eval_count eval(s): ${GREEN}${passed} passed${NC}, ${RED}$errors error(s)${NC}, ${YELLOW}$warnings warning(s)${NC}"

if [[ $errors -gt 0 ]]; then
    exit 1
fi

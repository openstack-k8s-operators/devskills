#!/usr/bin/env bash

# Validate skill and agent structure for openstack-k8s-agent-tools
# Usage: ./tests/validate-skills.sh [skill-or-agent-name]
#   No argument: validate all skills and agents
#   With argument: validate only the named skill or agent

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

pass() { echo -e "  ${GREEN}PASS${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}FAIL${NC} $1"; FAIL=$((FAIL + 1)); }
warn() { echo -e "  ${YELLOW}WARN${NC} $1"; WARN=$((WARN + 1)); }

get_frontmatter() {
    local file="$1"
    sed -n '2,/^---$/p' "$file" | head -n -1
}

has_field() {
    local frontmatter="$1"
    local field="$2"
    echo "$frontmatter" | grep -q "^${field}:"
}

get_field() {
    local frontmatter="$1"
    local field="$2"
    echo "$frontmatter" | grep "^${field}:" | sed "s/^${field}:[[:space:]]*//"
}

validate_skill() {
    local name="$1"
    local dir="${REPO_ROOT}/skills/${name}"
    local file="${dir}/SKILL.md"

    echo -e "\n${BLUE}[skill: ${name}]${NC}"

    if [[ ! -f "$file" ]]; then
        fail "SKILL.md exists"
        return
    fi
    pass "SKILL.md exists"

    # Check frontmatter delimiters
    local first_line
    first_line=$(head -1 "$file")
    if [[ "$first_line" != "---" ]]; then
        fail "frontmatter starts with ---"
        return
    fi
    pass "frontmatter starts with ---"

    local frontmatter
    frontmatter=$(get_frontmatter "$file")

    # Required fields
    for field in name description user-invocable; do
        if has_field "$frontmatter" "$field"; then
            pass "has '${field}' field"
        else
            fail "has '${field}' field"
        fi
    done

    # Name matches directory
    local fm_name
    fm_name=$(get_field "$frontmatter" "name" | tr -d '"' | tr -d "'")
    if [[ "$fm_name" == "$name" ]]; then
        pass "name field matches directory (${name})"
    else
        fail "name field '${fm_name}' does not match directory '${name}'"
    fi

    # Content length (>10 lines)
    local lines
    lines=$(wc -l < "$file")
    if [[ "$lines" -gt 10 ]]; then
        pass "has content (${lines} lines)"
    else
        fail "too short (${lines} lines, need >10)"
    fi

    # Check for TODO placeholders
    if grep -q "^TODO:" "$file"; then
        warn "contains TODO placeholders"
    fi

    # If skill has Agent in allowed-tools, check dispatch syntax
    if has_field "$frontmatter" "allowed-tools"; then
        local tools
        tools=$(get_field "$frontmatter" "allowed-tools")
        if echo "$tools" | grep -q '"Agent"'; then
            # Should have a matching agent or reference one
            if grep -q "subagent_type=" "$file"; then
                pass "has agent dispatch block"
                # Validate subagent_type format
                if grep -q "openstack-k8s-agent-tools:" "$file"; then
                    pass "subagent_type uses correct prefix"
                else
                    fail "subagent_type missing 'openstack-k8s-agent-tools:' prefix"
                fi
            elif grep -q "skills/.*/SKILL.md" "$file"; then
                pass "delegates dispatch to another skill"
            elif [[ -d "${REPO_ROOT}/agents/${name}" ]]; then
                warn "has Agent in allowed-tools but no dispatch block (may delegate via another skill)"
            else
                fail "has Agent in allowed-tools but no dispatch block and no matching agent"
            fi
        fi
    fi
}

validate_agent() {
    local name="$1"
    local dir="${REPO_ROOT}/agents/${name}"
    local file="${dir}/AGENT.md"

    echo -e "\n${BLUE}[agent: ${name}]${NC}"

    if [[ ! -f "$file" ]]; then
        fail "AGENT.md exists"
        return
    fi
    pass "AGENT.md exists"

    # Check frontmatter delimiters
    local first_line
    first_line=$(head -1 "$file")
    if [[ "$first_line" != "---" ]]; then
        fail "frontmatter starts with ---"
        return
    fi
    pass "frontmatter starts with ---"

    local frontmatter
    frontmatter=$(get_frontmatter "$file")

    # Required fields
    for field in name description; do
        if has_field "$frontmatter" "$field"; then
            pass "has '${field}' field"
        else
            fail "has '${field}' field"
        fi
    done

    # Name matches directory
    local fm_name
    fm_name=$(get_field "$frontmatter" "name" | tr -d '"' | tr -d "'")
    if [[ "$fm_name" == "$name" ]]; then
        pass "name field matches directory (${name})"
    else
        fail "name field '${fm_name}' does not match directory '${name}'"
    fi

    # Content length (>10 lines)
    local lines
    lines=$(wc -l < "$file")
    if [[ "$lines" -gt 10 ]]; then
        pass "has content (${lines} lines)"
    else
        fail "too short (${lines} lines, need >10)"
    fi

    # Check for TODO placeholders
    if grep -q "^TODO:" "$file"; then
        warn "contains TODO placeholders"
    fi

    # Check model field
    if has_field "$frontmatter" "model"; then
        local model
        model=$(get_field "$frontmatter" "model" | tr -d '"' | tr -d "'")
        if [[ "$model" == "inherit" ]]; then
            pass "model is 'inherit'"
        else
            warn "model is '${model}' (expected 'inherit')"
        fi
    else
        warn "no 'model' field (defaults may vary)"
    fi

    # If agent lists skills, verify they exist
    if has_field "$frontmatter" "skills"; then
        local skills_list
        skills_list=$(get_field "$frontmatter" "skills" | tr -d '[]"' | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed '/^$/d')
        if [[ -n "$skills_list" ]]; then
            while IFS= read -r skill; do
                [[ -z "$skill" ]] && continue
                if [[ -d "${REPO_ROOT}/skills/${skill}" ]]; then
                    pass "referenced skill '${skill}' exists"
                else
                    fail "referenced skill '${skill}' not found"
                fi
            done <<< "$skills_list"
        fi
    fi
}

# Main
echo -e "${BLUE}openstack-k8s-agent-tools Skill & Agent Validator${NC}"
echo "=================================================="

TARGET="${1:-}"

if [[ -n "$TARGET" ]]; then
    # Validate a specific skill or agent
    if [[ -d "${REPO_ROOT}/skills/${TARGET}" ]]; then
        validate_skill "$TARGET"
    fi
    if [[ -d "${REPO_ROOT}/agents/${TARGET}" ]]; then
        validate_agent "$TARGET"
    fi
    if [[ ! -d "${REPO_ROOT}/skills/${TARGET}" && ! -d "${REPO_ROOT}/agents/${TARGET}" ]]; then
        echo -e "${RED}No skill or agent named '${TARGET}' found${NC}"
        exit 1
    fi
else
    # Validate all
    for skill_dir in "${REPO_ROOT}"/skills/*/; do
        [[ -d "$skill_dir" ]] || continue
        validate_skill "$(basename "$skill_dir")"
    done

    for agent_dir in "${REPO_ROOT}"/agents/*/; do
        [[ -d "$agent_dir" ]] || continue
        validate_agent "$(basename "$agent_dir")"
    done
fi

# Summary
echo
echo "=================================================="
echo -e "${BLUE}Validation Summary${NC}"
echo "=================================================="
TOTAL=$((PASS + FAIL + WARN))
echo -e "Total:    $TOTAL"
echo -e "Passed:   ${GREEN}${PASS}${NC}"
echo -e "Failed:   ${RED}${FAIL}${NC}"
echo -e "Warnings: ${YELLOW}${WARN}${NC}"
echo

if [[ "$FAIL" -eq 0 ]]; then
    echo -e "${GREEN}All validations passed!${NC}"
    exit 0
else
    echo -e "${RED}${FAIL} validation(s) failed${NC}"
    exit 1
fi

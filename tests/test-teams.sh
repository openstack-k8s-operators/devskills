#!/bin/bash

# Test agent teams infrastructure: team-helpers.sh, new agent definitions,
# and skill team-mode sections.
#
# Usage: bash tests/test-teams.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
TOTAL=0

pass() { PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); echo -e "  ${GREEN}PASS${NC} $1"; }
fail() { FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo -e "  ${RED}FAIL${NC} $1"; }

# Setup: create a temp directory for worktree tests
TMPDIR=$(mktemp -d)
OPERATOR_REPO="$TMPDIR/operator-repo"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$OPERATOR_REPO"

# Initialize a git repo (needed for worktree tests)
cd "$OPERATOR_REPO"
git init -q
git config --local core.hooksPath /dev/null
git config --local commit.gpgsign false
echo "test" > README.md
git add . && git commit -q --no-verify -m "init"
cd "$SCRIPT_DIR"

echo -e "${BLUE}Testing agent teams infrastructure${NC}"
echo "=========================================="

# -----------------------------------------------
echo -e "\n${YELLOW}Phase 1: team-helpers.sh functions${NC}"
# -----------------------------------------------

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/team-helpers.sh"

# Test: teams_enabled returns false when not set
unset CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS 2>/dev/null || true
if ! teams_enabled; then
    pass "teams_enabled returns false when env var unset"
else
    fail "teams_enabled should return false when env var unset"
fi

# Test: teams_enabled returns false when set to 0
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS="0"
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
if ! teams_enabled; then
    pass "teams_enabled returns false when env var is '0'"
else
    fail "teams_enabled should return false when env var is '0'"
fi

# Test: teams_enabled returns true when set to 1
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS="1"
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
if teams_enabled; then
    pass "teams_enabled returns true when env var is '1'"
else
    fail "teams_enabled should return true when env var is '1'"
fi

# Test: should_use_team_review returns false for small diffs
SMALL_DIFF=" file1.go | 10 ++++------
 2 files changed, 4 insertions(+), 6 deletions(-)"
if ! echo "$SMALL_DIFF" | should_use_team_review; then
    pass "should_use_team_review returns false for small diffs"
else
    fail "should_use_team_review should return false for small diffs"
fi

# Test: should_use_team_review returns true for large diffs (many files)
LARGE_DIFF=" file1.go | 10 ++++------
 file2.go | 20 ++++++++----------
 file3.go | 15 +++++++---------
 file4.go | 8 +++++---
 file5.go | 12 ++++++------
 5 files changed, 30 insertions(+), 35 deletions(-)"
if echo "$LARGE_DIFF" | should_use_team_review; then
    pass "should_use_team_review returns true for large diffs (5+ files)"
else
    fail "should_use_team_review should return true for large diffs"
fi

# Test: create_team_worktree creates a worktree
cd "$OPERATOR_REPO"
WORKTREE_PATH=$(create_team_worktree "TEST-001" "1")
if [ -d "$WORKTREE_PATH" ]; then
    pass "create_team_worktree creates a worktree directory"
else
    fail "create_team_worktree should create a worktree directory"
fi

# Test: create_team_worktree adds .worktrees to gitignore
if grep -q '.worktrees' .gitignore 2>/dev/null; then
    pass "create_team_worktree adds .worktrees to gitignore"
else
    fail "create_team_worktree should add .worktrees to gitignore"
fi

# Test: create_team_worktree creates correct branch
BRANCH=$(git -C "$WORKTREE_PATH" rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$BRANCH" = "feature/TEST-001-group-1" ]; then
    pass "create_team_worktree creates correct branch name"
else
    fail "create_team_worktree should create branch feature/TEST-001-group-1 (got: $BRANCH)"
fi

# Test: remove_team_worktree cleans up
remove_team_worktree "$WORKTREE_PATH"
if [ ! -d "$WORKTREE_PATH" ]; then
    pass "remove_team_worktree removes worktree directory"
else
    fail "remove_team_worktree should remove the worktree directory"
fi

# Test: remove_team_worktree removes branch
if ! git branch --list "feature/TEST-001-group-1" | grep -q .; then
    pass "remove_team_worktree removes the branch"
else
    fail "remove_team_worktree should remove the branch"
fi

cd "$SCRIPT_DIR"

# -----------------------------------------------
echo -e "\n${YELLOW}Phase 2: Agent definition validation${NC}"
# -----------------------------------------------

AGENTS_DIR="$SCRIPT_DIR/agents"

# Researcher agent
AGENT_FILE="$AGENTS_DIR/researcher/AGENT.md"
if [ -f "$AGENT_FILE" ]; then
    pass "researcher agent exists"
else
    fail "researcher agent missing"
fi

if grep -q '^name: researcher' "$AGENT_FILE" 2>/dev/null; then
    pass "researcher agent has name field"
else
    fail "researcher agent missing name field"
fi

if grep -q '^description:' "$AGENT_FILE" 2>/dev/null; then
    pass "researcher agent has description field"
else
    fail "researcher agent missing description field"
fi

if grep -q '^model: inherit' "$AGENT_FILE" 2>/dev/null; then
    pass "researcher agent has model field"
else
    fail "researcher agent missing model field"
fi

if grep -q 'disallowedTools' "$AGENT_FILE" 2>/dev/null; then
    pass "researcher agent has disallowedTools"
else
    fail "researcher agent should have disallowedTools (read-only)"
fi

if grep -q 'Write' "$AGENT_FILE" 2>/dev/null && grep -q 'Edit' "$AGENT_FILE" 2>/dev/null; then
    pass "researcher agent disallows Write and Edit"
else
    fail "researcher agent should disallow Write and Edit"
fi

LINES=$(wc -l < "$AGENT_FILE")
if [ "$LINES" -gt 20 ]; then
    pass "researcher agent has substantial content ($LINES lines)"
else
    fail "researcher agent has too little content ($LINES lines)"
fi

# Implementer agent
AGENT_FILE="$AGENTS_DIR/implementer/AGENT.md"
if [ -f "$AGENT_FILE" ]; then
    pass "implementer agent exists"
else
    fail "implementer agent missing"
fi

if grep -q '^name: implementer' "$AGENT_FILE" 2>/dev/null; then
    pass "implementer agent has name field"
else
    fail "implementer agent missing name field"
fi

if grep -q '^description:' "$AGENT_FILE" 2>/dev/null; then
    pass "implementer agent has description field"
else
    fail "implementer agent missing description field"
fi

if ! grep -q 'disallowedTools' "$AGENT_FILE" 2>/dev/null; then
    pass "implementer agent does NOT have disallowedTools (write-capable)"
else
    fail "implementer agent should not have disallowedTools"
fi

# Check that code quality standards are inlined
if grep -q 'Import Grouping' "$AGENT_FILE" 2>/dev/null; then
    pass "implementer agent has inlined code quality standards"
else
    fail "implementer agent should inline code quality standards"
fi

if grep -q 'lib-common First' "$AGENT_FILE" 2>/dev/null; then
    pass "implementer agent has lib-common-first rule"
else
    fail "implementer agent should have lib-common-first rule"
fi

LINES=$(wc -l < "$AGENT_FILE")
if [ "$LINES" -gt 20 ]; then
    pass "implementer agent has substantial content ($LINES lines)"
else
    fail "implementer agent has too little content ($LINES lines)"
fi

# Reviewer agent
AGENT_FILE="$AGENTS_DIR/reviewer/AGENT.md"
if [ -f "$AGENT_FILE" ]; then
    pass "reviewer agent exists"
else
    fail "reviewer agent missing"
fi

if grep -q '^name: reviewer' "$AGENT_FILE" 2>/dev/null; then
    pass "reviewer agent has name field"
else
    fail "reviewer agent missing name field"
fi

if grep -q '^description:' "$AGENT_FILE" 2>/dev/null; then
    pass "reviewer agent has description field"
else
    fail "reviewer agent missing description field"
fi

if grep -q 'disallowedTools' "$AGENT_FILE" 2>/dev/null; then
    pass "reviewer agent has disallowedTools"
else
    fail "reviewer agent should have disallowedTools (read-only)"
fi

# Check focus areas
if grep -q 'Focus A: Conventions' "$AGENT_FILE" 2>/dev/null; then
    pass "reviewer agent has Focus A (Conventions)"
else
    fail "reviewer agent should have Focus A (Conventions)"
fi

if grep -q 'Focus B: Quality' "$AGENT_FILE" 2>/dev/null; then
    pass "reviewer agent has Focus B (Quality)"
else
    fail "reviewer agent should have Focus B (Quality)"
fi

if grep -q 'Focus C: Security' "$AGENT_FILE" 2>/dev/null; then
    pass "reviewer agent has Focus C (Security)"
else
    fail "reviewer agent should have Focus C (Security)"
fi

if grep -q 'Cross-Validation' "$AGENT_FILE" 2>/dev/null; then
    pass "reviewer agent has Cross-Validation protocol"
else
    fail "reviewer agent should have Cross-Validation protocol"
fi

LINES=$(wc -l < "$AGENT_FILE")
if [ "$LINES" -gt 20 ]; then
    pass "reviewer agent has substantial content ($LINES lines)"
else
    fail "reviewer agent has too little content ($LINES lines)"
fi

# -----------------------------------------------
echo -e "\n${YELLOW}Phase 3: Skill team-mode sections${NC}"
# -----------------------------------------------

SKILLS_DIR="$SCRIPT_DIR/skills"

for skill in code-review feature task-executor debug-operator; do
    SKILL_FILE="$SKILLS_DIR/$skill/SKILL.md"
    if [ ! -f "$SKILL_FILE" ]; then
        fail "$skill skill file missing"
        continue
    fi

    if grep -q 'Team Mode' "$SKILL_FILE" 2>/dev/null; then
        pass "$skill skill has Team Mode section"
    else
        fail "$skill skill missing Team Mode section"
    fi

    if grep -q 'Fallback' "$SKILL_FILE" 2>/dev/null; then
        pass "$skill skill has Fallback subsection"
    else
        fail "$skill skill missing Fallback subsection"
    fi
done

# -----------------------------------------------
echo -e "\n${YELLOW}Phase 4: Team helpers integration${NC}"
# -----------------------------------------------

HELPERS_FILE="$SCRIPT_DIR/lib/team-helpers.sh"

if [ -f "$HELPERS_FILE" ]; then
    pass "team-helpers.sh exists"
else
    fail "team-helpers.sh missing"
fi

if [ -x "$HELPERS_FILE" ]; then
    pass "team-helpers.sh is executable"
else
    fail "team-helpers.sh should be executable"
fi

# Syntax check
if bash -n "$HELPERS_FILE" 2>/dev/null; then
    pass "team-helpers.sh passes syntax check"
else
    fail "team-helpers.sh has syntax errors"
fi

# -----------------------------------------------
echo ""
echo "=========================================="
echo -e "${BLUE}Results: ${PASS} passed, ${FAIL} failed (${TOTAL} total)${NC}"

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}FAIL${NC}"
    exit 1
else
    echo -e "${GREEN}ALL PASSED${NC}"
fi

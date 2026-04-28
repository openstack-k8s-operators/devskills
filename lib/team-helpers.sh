#!/usr/bin/env bash
# Team lifecycle helpers for openstack-k8s-agent-tools skills.
# Sourced by skills that orchestrate agent teams.

set -euo pipefail

# Check if agent teams are enabled.
teams_enabled() {
    [ "${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-}" = "1" ]
}

# Determine if a diff warrants team-mode review.
# Reads diffstat from stdin (git diff --stat format).
# Returns 0 (true) if the diff is large enough for team review.
# Thresholds: 5+ files changed OR 500+ lines changed.
should_use_team_review() {
    local diff_stat="${1:-}"
    if [ -z "$diff_stat" ]; then
        diff_stat="$(cat)"
    fi

    local files_changed
    files_changed=$(echo "$diff_stat" | grep -c '|' || echo 0)

    local lines_changed
    lines_changed=$(echo "$diff_stat" | tail -1 | grep -oP '\d+ insertion' | grep -oP '\d+' || echo 0)
    local deletions
    deletions=$(echo "$diff_stat" | tail -1 | grep -oP '\d+ deletion' | grep -oP '\d+' || echo 0)
    lines_changed=$((lines_changed + deletions))

    [ "$files_changed" -ge 5 ] || [ "$lines_changed" -ge 500 ]
}

# Create a worktree for a teammate.
# Args: $1 = ticket-id, $2 = group-number
# Prints the worktree directory path.
create_team_worktree() {
    local ticket="$1"
    local group="$2"
    local worktree_dir=".worktrees/${ticket}-group-${group}"
    local branch="feature/${ticket}-group-${group}"

    # Ensure .worktrees/ is gitignored
    if ! grep -q '\.worktrees' .gitignore 2>/dev/null; then
        echo ".worktrees/" >> .gitignore
    fi

    git worktree add -b "$branch" "$worktree_dir" >/dev/null 2>&1
    echo "$worktree_dir"
}

# Remove a team worktree and its branch.
# Args: $1 = worktree-dir
remove_team_worktree() {
    local worktree_dir="$1"

    # Derive branch from worktree
    local branch
    branch=$(git -C "$worktree_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

    git worktree remove "$worktree_dir" --force 2>/dev/null || true
    if [ -n "$branch" ] && [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
        git branch -D "$branch" 2>/dev/null || true
    fi
}

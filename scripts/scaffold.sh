#!/bin/bash
# Scaffold new skills and agents for the openstack-k8s-agent-tools plugin.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $(basename "$0") --skill <name>
       $(basename "$0") --agent <name>

Scaffold a new skill or agent with correct frontmatter and directory layout.

Options:
  --skill <name>   Create skills/<name>/SKILL.md
  --agent <name>   Create agents/<name>/AGENT.md
  --help           Show this help

Name must be lowercase alphanumeric with hyphens (e.g., my-skill).
EOF
    exit 0
}

validate_name() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: name is required${NC}" >&2
        exit 1
    fi
    if ! [[ "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
        echo -e "${RED}Error: name must be lowercase alphanumeric with hyphens (got: ${name})${NC}" >&2
        exit 1
    fi
}

scaffold_skill() {
    local name="$1"
    local dir="${REPO_ROOT}/skills/${name}"
    local file="${dir}/SKILL.md"

    if [[ -d "$dir" ]]; then
        echo -e "${RED}Error: skills/${name}/ already exists${NC}" >&2
        exit 1
    fi

    mkdir -p "$dir"
    cat > "$file" <<TEMPLATE
---
name: ${name}
description: "TODO: describe what this skill does"
argument-hint: ""
user-invocable: true
allowed-tools: ["Bash", "Read"]
context: fork
---

# TODO: Skill title

TODO: Describe the skill's purpose and workflow.

## Input Routing

TODO: How the skill determines what to do with user input.

## Workflow

TODO: Step-by-step workflow.
TEMPLATE

    echo -e "${GREEN}Created ${file}${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Edit the TODO placeholders in skills/${name}/SKILL.md"
    echo "  2. If dispatching an agent, add \"Agent\" to allowed-tools and add the dispatch block:"
    echo "       Agent(subagent_type=\"openstack-k8s-agent-tools:${name}:${name}\", ...)"
    echo "  3. Run 'make test' to validate"
    echo "  4. Add the skill to the table in AGENTS.md"
}

scaffold_agent() {
    local name="$1"
    local dir="${REPO_ROOT}/agents/${name}"
    local file="${dir}/AGENT.md"

    if [[ -d "$dir" ]]; then
        echo -e "${RED}Error: agents/${name}/ already exists${NC}" >&2
        exit 1
    fi

    mkdir -p "$dir"
    cat > "$file" <<TEMPLATE
---
name: ${name}
description: "TODO: describe what this agent does"
model: inherit
skills: []
---

# TODO: Agent title

TODO: Describe the agent's role, expertise, and domain.

## Process

TODO: Numbered step-by-step process the agent follows.

## Criteria

TODO: Evaluation criteria, principles, or rules.
TEMPLATE

    echo -e "${GREEN}Created ${file}${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Edit the TODO placeholders in agents/${name}/AGENT.md"
    echo "  2. If this agent is invoked by a skill, ensure the skill has \"Agent\" in allowed-tools"
    echo "  3. Add sub-skills to the skills: [] list if needed"
    echo "  4. Run 'make test' to validate"
    echo "  5. Add the agent to the table in AGENTS.md"
}

if [[ $# -eq 0 ]]; then
    usage
fi

case "$1" in
    --skill)
        [[ $# -lt 2 ]] && { echo -e "${RED}Error: --skill requires a name${NC}" >&2; exit 1; }
        validate_name "$2"
        scaffold_skill "$2"
        ;;
    --agent)
        [[ $# -lt 2 ]] && { echo -e "${RED}Error: --agent requires a name${NC}" >&2; exit 1; }
        validate_name "$2"
        scaffold_agent "$2"
        ;;
    --help|-h)
        usage
        ;;
    *)
        echo -e "${RED}Error: unknown option: $1${NC}" >&2
        usage
        ;;
esac

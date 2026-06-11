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
       $(basename "$0") --eval <name>

Scaffold a new skill, agent, or eval with correct structure.

Options:
  --skill <name>   Create skills/<name>/SKILL.md
  --agent <name>   Create agents/<name>/AGENT.md
  --eval <name>    Create evals/<name>/ with eval.yaml, prompt, grader, README
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

scaffold_eval() {
    local name="$1"
    local dir="${REPO_ROOT}/evals/${name}"

    if [[ -d "$dir" ]]; then
        echo -e "${RED}Error: evals/${name}/ already exists${NC}" >&2
        exit 1
    fi

    # Check that the skill exists
    if [[ ! -f "${REPO_ROOT}/skills/${name}/SKILL.md" ]]; then
        echo -e "${YELLOW}Warning: skills/${name}/SKILL.md not found — scaffold the skill first${NC}" >&2
    fi

    mkdir -p "$dir/fixtures" "$dir/graders"

    # eval.yaml
    cat > "$dir/eval.yaml" <<TEMPLATE
description: "Evals for /${name} skill"

providers:
  - id: anthropic:claude-agent-sdk
    label: claude-code
    config:
      model: claude-sonnet-4-6
      working_dir: ../../
      plugins:
        - type: local
          path: ../../
      skills:
        - openstack-k8s-agent-tools:${name}
      append_allowed_tools: ["Skill", "Read", "Bash", "Grep", "Glob"]
      permission_mode: auto
      max_turns: 20
      max_budget_usd: 1.50
      ask_user_question:
        behavior: first_option

prompts:
  - file://prompt.txt

defaultTest:
  options:
    disableVarExpansion: true

tests:
  # --- Smoke ---

  - description: "smoke/produces-output"
    vars:
      target: "TODO"
    assert:
      - type: python
        threshold: 0.4
        value: file://graders/smoke.py
      - type: latency
        threshold: 120000

  # --- Standard ---

  - description: "standard/skill-invocation"
    vars:
      target: "TODO"
    assert:
      - type: skill-used
        value: openstack-k8s-agent-tools:${name}
TEMPLATE

    # prompt.txt
    cat > "$dir/prompt.txt" <<TEMPLATE
TODO: write the prompt template for ${name}. Use {{target}} for variable substitution.
TEMPLATE

    # smoke grader
    cat > "$dir/graders/smoke.py" <<'TEMPLATE'
import re


def get_assert(output, context):
    text = output.lower()
    score = 0.0
    # TODO: add indicator patterns relevant to this skill's output
    indicators = [
        r'TODO_pattern_1',
        r'TODO_pattern_2',
        r'TODO_pattern_3',
    ]
    for pattern in indicators:
        if re.search(pattern, text):
            score += 1.0 / len(indicators)

    matched = sum(1 for p in indicators if re.search(p, text))
    return {
        "pass": score >= 0.4,
        "score": score,
        "reason": f"Score {score:.1f}/1.0 — matched {matched}/{len(indicators)} indicator groups",
    }
TEMPLATE

    # README
    cat > "$dir/README.md" <<TEMPLATE
# ${name} Eval

Tests the \`/${name}\` skill.

## Providers

| Provider | Model | Prompt | Status |
|----------|-------|--------|--------|
| \`anthropic:claude-agent-sdk\` | \`claude-sonnet-4-6\` | Natural language (\`prompt.txt\`) | Active |
| \`opencode:sdk\` | — | — | Not yet configured |

## Fixtures

| File | Purpose |
|------|---------|
| TODO | TODO |

## Tests

| Test | Tier | Grader | Threshold | What it checks |
|------|------|--------|-----------|----------------|
| \`smoke/produces-output\` | smoke | \`smoke.py\` | 0.4 | TODO |
| \`standard/skill-invocation\` | standard | \`skill-used\` (builtin) | — | Skill tool was invoked |

## Graders

| Grader | Checks | Score model |
|--------|--------|-------------|
| \`smoke.py\` | TODO | TODO |
TEMPLATE

    echo -e "${GREEN}Created eval scaffold:${NC}"
    echo "  evals/${name}/"
    echo "  ├── eval.yaml"
    echo "  ├── prompt.txt"
    echo "  ├── README.md"
    echo "  ├── graders/"
    echo "  │   └── smoke.py"
    echo "  └── fixtures/"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Add fixture files to evals/${name}/fixtures/"
    echo "  2. Edit prompt.txt with the skill invocation prompt"
    echo "  3. Update graders/smoke.py with output-specific patterns"
    echo "  4. Fill in the TODO placeholders in eval.yaml and README.md"
    echo "  5. Run: make eval EVAL_SKILL=${name}"
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
    --eval)
        [[ $# -lt 2 ]] && { echo -e "${RED}Error: --eval requires a name${NC}" >&2; exit 1; }
        validate_name "$2"
        scaffold_eval "$2"
        ;;
    --help|-h)
        usage
        ;;
    *)
        echo -e "${RED}Error: unknown option: $1${NC}" >&2
        usage
        ;;
esac

# Developer Guide

Guide for extending and evolving the openstack-k8s-agent-tools plugin.

## Architecture

```
                         openstack-k8s-agent-tools
+------------------------------------------------------------------------+
|                                                                        |
|  SKILLS (skills/*/SKILL.md)          AGENTS (agents/*/AGENT.md)        |
|  User-facing entry points            Specialized worker processes      |
|                                                                        |
|  +---------------------------+       +---------------------------+     |
|  | /feature                  |       | feature                   |     |
|  | - parses input (Jira/spec)|  -->  | - cross-repo analysis     |     |
|  | - checks resume state     | dispatch| - planning checklist    |     |
|  | - dispatches agent        |       | - strategy evaluation     |     |
|  +---------------------------+       | - task breakdown           |     |
|                                      +---------------------------+     |
|  +---------------------------+       +---------------------------+     |
|  | /task-executor            |       | task-executor              |     |
|  | - loads plan file         |  -->  | - sequential execution    |     |
|  | - detects progress        | dispatch| - code quality standards |     |
|  | - dispatches agent        |       | - checkpointing           |     |
|  +---------------------------+       | - commit & completion     |     |
|                                      +---------------------------+     |
|  +---------------------------+       +---------------------------+     |
|  | /code-review              |       | code-review               |     |
|  | - determines scope        |  -->  | - 10 review criteria      |     |
|  | - collects changed files  | dispatch| - severity classification|     |
|  | - dispatches agent        |       | - structured verdict      |     |
|  +---------------------------+       +---------------------------+     |
|                                                                        |
|  +---------------------------+                                         |
|  | /debug-operator           |  Self-contained skills                  |
|  | /test-operator            |  (no agent, all logic in SKILL.md)      |
|  | /code-style               |                                         |
|  | /analyze-logs             |                                         |
|  | /explain-flow             |                                         |
|  +---------------------------+                                         |
|                                                                        |
|  SCRIPTS (scripts/)                                                   |
|  Utility scripts (install, scaffold)                                  |
|                                                                        |
+------------------------------------------------------------------------+
```

## How Skills and Agents Work Together

Skills and agents are separate concerns:

- **Skills** (`skills/*/SKILL.md`) are user-facing. They handle input parsing, state management (resume detection, plan loading), and orchestration. Users invoke them with `/skill-name`.
- **Agents** (`agents/*/AGENT.md`) are workers. They contain domain knowledge, methodology, and behavioral rules. Skills dispatch agents via the `Agent` tool with `subagent_type`.

### The Dispatch Pattern

When a skill needs an agent, it uses the `Agent` tool:

```
Agent(
  subagent_type="openstack-k8s-agent-tools:<agent-dir>:<agent-name>",
  description="<short description>",
  prompt="<context and task for the agent>"
)
```

The naming convention is `<plugin-name>:<agent-directory>:<agent-name>`:

```
openstack-k8s-agent-tools:feature:feature
openstack-k8s-agent-tools:task-executor:task-executor
openstack-k8s-agent-tools:code-review:code-review
```

Claude Code discovers agents from the plugin's `agents/` directory automatically when the plugin is installed via marketplace.

### Flow Diagram

```
User types: /feature OSPRH-2345
       |
       v
+------------------+
| SKILL.md         |  skills/feature/SKILL.md
| (orchestrator)   |
+------------------+
       |
       | 1. Parse input: "OSPRH-2345" is a Jira ticket
       | 2. Check ~/.openstack-k8s-agent-plans/glance-operator/ for existing plan
       | 3. No existing plan found
       |
       v
+------------------+
| Fetch Jira       |  via Atlassian MCP
| ticket content   |
+------------------+
       |
       | 4. Normalize into Context Summary
       |
       v
+------------------+
| Agent(           |  Dispatch to the feature agent
|   subagent_type= |
|   "...feature",  |
|   prompt=<ctx>   |
| )                |
+------------------+
       |
       v
+------------------+
| AGENT.md         |  agents/feature/AGENT.md
| (worker)         |  Runs in its own context with full methodology
+------------------+
       |
       | - Reads operator codebase
       | - Cross-references lib-common, peer operators, dev-docs
       | - Runs 11-principle planning checklist
       | - Proposes 2-3 strategies
       | - Produces task breakdown
       |
       v
+------------------+
| Returns result   |  Plan content back to the skill
+------------------+
       |
       v
+------------------+
| SKILL.md         |  Back in the orchestrator
| (orchestrator)   |
+------------------+
       |
       | 5. Present strategies to user, wait for approval
       | 6. Write plan to ~/.openstack-k8s-agent-plans/<operator>/
       | 7. Create TaskCreate items for tracking
       | 8. Suggest: "Run /task-executor to execute"
       |
       v
     Done
```

### When NOT to Use an Agent

Not every skill needs an agent. Use agents when:

- The skill needs deep domain knowledge (review criteria, planning methodology)
- The work is complex enough to benefit from isolated context
- The methodology is reusable across different inputs

Self-contained skills (like `/debug-operator`, `/test-operator`) embed their logic directly in the SKILL.md. They're simpler and don't need the orchestrator/worker split.

## Project Structure

```
openstack-k8s-agent-tools/
+-- .claude-plugin/
|   +-- plugin.json            # Plugin metadata (name, version, description)
|   +-- marketplace.json       # Marketplace registration
+-- skills/                    # User-facing skill entry points
|   +-- feature/SKILL.md       # /feature - dispatches feature agent
|   +-- task-executor/SKILL.md # /task-executor - dispatches task-executor agent
|   +-- code-review/SKILL.md   # /code-review - dispatches code-review agent
|   +-- debug-operator/SKILL.md# /debug-operator - self-contained
|   +-- test-operator/SKILL.md # /test-operator - self-contained
|   +-- code-style/SKILL.md    # /code-style - self-contained
|   +-- analyze-logs/SKILL.md  # /analyze-logs - self-contained
|   +-- explain-flow/SKILL.md  # /explain-flow - self-contained
+-- agents/                    # Agent worker definitions
|   +-- feature/AGENT.md       # Planning methodology
|   +-- task-executor/AGENT.md # Execution principles
|   +-- code-review/AGENT.md   # Review criteria
+-- scripts/                   # Utility scripts
|   +-- install.sh             # Cross-platform installer
|   +-- scaffold.sh            # Scaffold new skills and agents
+-- tests/                     # Validation
|   +-- test-plugin.sh         # Discovery-based plugin validation
|   +-- validate-skills.sh     # Operator-level skill validation
+-- docs/                      # Documentation
+-- .github/workflows/         # CI validation
+-- .pre-commit-config.yaml    # Pre-commit hooks
```

## Creating Skills

### SKILL.md Format

```yaml
---
name: my-skill
description: What this skill does and when to use it
user-invocable: true
allowed-tools: ["Bash", "Read", "Grep"]
context: fork
---

Instructions for Claude when this skill is invoked.
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill identifier (kebab-case, must match directory name) |
| `description` | Yes | One-line summary (Claude uses this for auto-discovery) |
| `user-invocable` | No | `true` (default) for `/slash-command`, `false` for background knowledge |
| `allowed-tools` | No | Tools the skill can use without permission prompts |
| `context` | No | `fork` for isolated subagent context |
| `agent` | No | Agent type to use when `context: fork` is set |

### Self-Contained vs Agent-Backed

**Self-contained** (all logic in SKILL.md):

```yaml
---
name: my-simple-skill
description: Does something straightforward
user-invocable: true
allowed-tools: ["Bash", "Read"]
context: fork
---

When invoked:
1. Do step 1
2. Do step 2
3. Report results
```

**Agent-backed** (SKILL.md orchestrates, AGENT.md does the work):

```yaml
---
name: my-complex-skill
description: Does something that needs deep domain knowledge
user-invocable: true
allowed-tools: ["Bash", "Read", "Write", "Agent"]
context: fork
---

You orchestrate this workflow. Parse input, then dispatch the agent:

## Workflow
1. Parse user input
2. Dispatch the agent:
   Agent(subagent_type="openstack-k8s-agent-tools:my-agent:my-agent", ...)
3. Present results to user
```

## Creating Agents

### AGENT.md Format

```yaml
---
name: my-agent
description: What this agent specializes in
model: inherit
---

You are a specialist in <domain>.

## Methodology
...

## Behavioral Rules
...
```

### Agent Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Agent identifier (kebab-case, must match directory name) |
| `description` | Yes | When Claude should delegate to this agent |
| `model` | No | `inherit` (default), `sonnet`, `opus`, `haiku`, or a full model ID |
| `tools` | No | Tools the agent can use (inherits all if omitted) |
| `disallowedTools` | No | Tools to deny from inherited set |
| `maxTurns` | No | Maximum agentic turns before stopping |
| `skills` | No | Skills to preload into the agent's context |
| `memory` | No | Persistent memory scope: `user`, `project`, or `local` |

### Agent Discovery

When the plugin is installed via marketplace:

```
claude plugin marketplace add https://github.com/fmount/openstack-k8s-agent-tools
claude plugin install openstack-k8s-agent-tools
```

Claude Code automatically discovers agents from the plugin's `agents/` directory. No file path resolution is needed in the SKILL.md.

Skills dispatch agents using the naming convention:

```
<plugin-name>:<agent-directory>:<agent-name>
```

## Testing

### Automated Tests

```bash
# Run all structure tests (discovery-based)
bash tests/test-plugin.sh structure

# Run functional tests
bash tests/test-plugin.sh functional

# Run everything
bash tests/test-plugin.sh all
```

The test suite is discovery-based. Adding new skills, agents, or lib scripts does not require updating `test-plugin.sh`.

### Manual Testing

```bash
# Test in Claude Code against an operator repo
cd /path/to/your-operator
claude
/feature OSPRH-2345
/task-executor
/code-review
```

### Pre-commit Hooks

```bash
pre-commit install
pre-commit run --all-files
```

Hooks: trailing-whitespace, end-of-file-fixer, check-yaml, check-json, shellcheck, markdownlint.

### CI

GitHub Actions workflow at `.github/workflows/validate.yml` runs on push/PR:

- Plugin structure validation
- Plugin functionality tests
- Shell script syntax checking

## Versioning

Update `.claude-plugin/plugin.json` and `package.json` when releasing:

- **Major** (x.0.0): Breaking changes to skill interfaces or agent contracts
- **Minor** (0.x.0): New skills, agents, or significant enhancements
- **Patch** (0.0.x): Bug fixes, documentation updates

## Reference

- [Claude Code Skills](https://code.claude.com/docs/en/skills) - official skills documentation
- [Claude Code Subagents](https://code.claude.com/docs/en/sub-agents) - official agents documentation
- [Claude Code Plugins](https://code.claude.com/docs/en/plugins) - plugin packaging and distribution
- [openstack-k8s-operators/dev-docs](https://github.com/openstack-k8s-operators/dev-docs) - operator development conventions
- [lib-common](https://github.com/openstack-k8s-operators/lib-common) - shared operator libraries

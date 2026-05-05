# openstack-k8s-operators Operator Tools

Claude Code plugin for [openstack-k8s-operators](https://github.com/openstack-k8s-operators/) development — debugging, testing, code review, feature planning, and plan execution.

[![asciicast](https://asciinema.org/a/886205.svg)](https://asciinema.org/a/886205)

## Installation

### Claude Code (recommended)

Add the marketplace and install the plugin (two steps):

```bash
claude plugin marketplace add https://github.com/fmount/openstack-k8s-agent-tools
claude plugin install openstack-k8s-agent-tools
```

To update to the latest version:

```bash
claude plugin update openstack-k8s-agent-tools
```

### Cursor

Cursor reads Claude Code plugins from `~/.claude/plugins/cache/` automatically.
If you have the Claude Code CLI installed, run the same marketplace commands:

```bash
claude plugin marketplace add https://github.com/fmount/openstack-k8s-agent-tools
claude plugin install openstack-k8s-agent-tools
```

Restart Cursor after installing. Skills will appear in Cursor's agent skill
list and can be invoked from chat.

If you do not have the Claude Code CLI, clone the repo and use the manual
install target instead:

```bash
git clone https://github.com/fmount/openstack-k8s-agent-tools.git
cd openstack-k8s-agent-tools
make install-claude
```

This copies skills to `~/.claude/skills/` and agents to `~/.claude/agents/`,
which Cursor also discovers.

### OpenCode

```bash
git clone https://github.com/fmount/openstack-k8s-agent-tools.git
cd openstack-k8s-agent-tools
make install-opencode
```

### Manual install (Claude Code, without marketplace)

```bash
make install-claude
```

## Dependencies

| Dependency | Required | Purpose |
|-----------|----------|---------|
| Go toolchain | Yes | Operator development, tests, linting |
| make | Yes | Build system (make test, make manifests, etc.) |
| gh (GitHub CLI) | Optional | Cross-repo analysis in `/feature` when local checkouts aren't available |
| Atlassian MCP | Optional | Jira integration for `/feature` and `/jira` - see [MCP Setup](docs/mcp-setup.md) |
| golangci-lint | Optional | Enhanced linting in `/test-operator` |
| gosec, govulncheck | Optional | Security scanning in `/test-operator security` |

## Skills

| Skill | Agent | Purpose |
|-------|-------|---------|
| `/debug-operator` | — | Development workflow + runtime debugging |
| `/test-operator` | — | Testing & QA — quick, standard, full, security, coverage |
| `/code-style` | — | Go code style enforcement (gopls modernize, conventions) |
| `/analyze-logs` | — | Log pattern recognition (25+ patterns) |
| `/analyze-must-gather` | — | Analyze must-gather archives for operator issues |
| `/analyze-zuul-ci-logs` | — | Analyze logs downloaded from a Zuul CI job |
| `/explain-flow` | — | Code flow analysis for controllers |
| `/feature` | `feature` | Feature/bug planning with Jira, cross-repo analysis, structured strategies |
| `/bug` | `feature` | Bug fix planning — alias for `/feature` with bug-focused context |
| `/code-review` | `code-review` | Code review against openstack-k8s-operators conventions (PR number, branch diff, or specific files) |
| `/task-executor` | `task-executor` | Execute plans task-by-task with checkpointing and resume |
| `/backport-review` | — | Compare downstream backport change requests against upstream Gerrit patches |
| `/jira` | — | Jira integration — ticket inspection, hierarchy validation, outcome posting |

Skills with an agent load an `AGENT.md` file that contains the full domain knowledge and methodology. Skills without an agent are self-contained in their `SKILL.md`.

## Quickstart

### Create a new skill or agent

```bash
# Scaffold a new skill
make new-skill my-skill

# Scaffold a new agent
make new-agent my-agent

# Validate structure
make validate
```

See the [DEVELOPMENT](docs/DEVELOPMENT.md) guide for more details on extending
the plugin.

For usage examples, workflows, and skill reference, see the [GETTING-STARTED](docs/GETTING-STARTED.md) guide.

## Documentation

- **[Getting Started](docs/GETTING-STARTED.md)** — usage examples, workflows, and skill reference
- **[MCP Setup](docs/mcp-setup.md)** — Atlassian MCP configuration for Jira integration
- **[Development Guide](docs/DEVELOPMENT.md)** — extending the plugin with new skills
- **[Feature Planning](docs/design/feature.md)** — detailed walkthrough with use case
- **[Memory and State](docs/design/memory-docs.md)** — shared memory, state tracking, worktrees, dependencies
- **[AGENTS.md](AGENTS.md)** — project conventions for AI agents

## Roadmap

- [x] `install.sh` — manual installation script with platform support (Claude Code, OpenCode)
- [x] Code review accepts PR number, branch, or specific files
- [x] Shared memory (MEMORY.md), state tracking (state.json), worktree isolation, dependency resolution
- [x] `/analyze-must-gather` — must-gather archive analysis
- [x] `/bug` — bug fix planning alias
- [x] `make new-skill` / `make new-agent` — scaffold new skills and agents
- [ ] Guidelines on sandboxing
- [ ] Jira sub-task export from task breakdowns
- [ ] Plan diffing (detect Jira ticket changes after plan creation)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).

# openstack-k8s-operators Operator Tools - Documentation

Documentation for openstack-k8s-operators operator development and troubleshooting skills.

## Quick Start

- **[Getting Started](GETTING-STARTED.md)** - Quick reference for all skills
- **[MCP Setup](mcp-setup.md)** - Optional MCP server integrations (Jira)
- **[Development Guide](DEVELOPMENT.md)** - Extending the plugin

## Installation

```bash
cd /path/to/openstack-k8s-agent-tools
./scripts/install.sh --claude-code

# For operator projects
cd /path/to/your-operator
cp -r /path/to/openstack-k8s-agent-tools/skills .claude/
cp /path/to/openstack-k8s-agent-tools/CLAUDE.md .
```

## Skills Overview

| Skill | Purpose | Quick Usage |
|-------|---------|-------------|
| **debug-operator** | Development workflow + testing | `/debug-operator` |
| **test-operator** | Testing & quality assurance | `/test-operator quick` |
| **code-style** | Go style enforcement | `/code-style` |
| **analyze-logs** | Log pattern analysis | `/analyze-logs` |
| **explain-flow** | Code flow analysis | `/explain-flow` |
| **feature** | Feature planning with Jira integration | `/feature OSPRH-2345` |
| **task-executor** | Plan execution with checkpointing | `/task-executor` |
| **code-review** | Code review (dev-docs conventions) | `/code-review` |
| **backport-review** | Downstream vs upstream patch comparison | `/backport-review` |
| **jira** | Jira hierarchy validation and integration | `/jira OSPRH-2345` |

## Common Workflows

### Development

```bash
/test-operator quick              # Fast validation
/debug-operator focus-test "..."  # Focused testing
```

### Pre-Commit

```bash
/test-operator standard
/code-style
```

### Pre-PR

```bash
/debug-operator
/test-operator full
/test-operator security
/code-review
```

## Integration

All skills integrate with:

- [openstack-k8s-operators/dev-docs](https://github.com/openstack-k8s-operators/dev-docs)
- [lib-common](https://github.com/openstack-k8s-operators/lib-common)
- Ginkgo testing framework
- Controller-runtime best practices

## Design

Architecture and design decisions behind the plugin:

- **[Feature Planning](design/feature.md)** - How `/feature` works: input routing, cross-repo analysis, strategy evaluation
- **[Memory Architecture](design/memory-docs.md)** - Shared memory, state tracking, worktrees, and dependency resolution

## Troubleshooting

**Skills not showing**: Ensure in `.claude/skills/` and restart Claude

**Make targets fail**: Verify in operator directory with Makefile

**Permissions**: `chmod +x skills/**/*.sh scripts/*.sh`

Use the following skills to understand more about the failure:

```bash
/analyze-logs
/explain-flow
```

## Additional Resources

- [CLAUDE.md](../CLAUDE.md) - Development guidelines
- [README.md](../README.md) - Project overview

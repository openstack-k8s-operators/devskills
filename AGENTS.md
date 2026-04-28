# AGENTS Guidelines for This Repository

This plugin provides a collection of skills and agents specialized in
openstack-k8s-operators operator development and troubleshooting.
Follow these guidelines when working in this codebase.

## Architecture

- `skills/*/SKILL.md` are thin entry points (input routing, frontmatter).
- `agents/*/AGENT.md` hold full domain knowledge and methodology.
- Skills dispatch agents via `Agent(subagent_type="openstack-k8s-agent-tools:<dir>:<name>")`.
- Agents can preload other skills via the `skills:` frontmatter field (e.g., `jira`, `code-style`).
- Plan files are stored at `~/.openstack-k8s-agent-plans/<operator>/` and shared across sessions.

## Project Layout

| Directory | Contents |
|-----------|----------|
| `skills/` | SKILL.md entry points (one per skill) |
| `agents/` | AGENT.md domain knowledge (code-review, feature, task-executor, researcher, implementer, reviewer) |
| `lib/` | Shared helper scripts (shell, Python) |
| `scripts/` | Utility scripts (install, operator-tools, crd-tools) |
| `docs/` | User-facing documentation and design decisions |
| `examples/` | Example outputs (sample plans) |
| `tests/` | Plugin validation tests |

## Available Skills

| Skill | Purpose |
|-------|---------|
| `/debug-operator` | Systematic debugging: pod status, logs, CRs, events |
| `/explain-flow` | Code flow analysis: reconciliation logic, state transitions |
| `/feature` | Feature/bug planning with Jira, cross-repo analysis, strategies |
| `/task-executor` | Execute plans task-by-task with checkpointing and resume |
| `/analyze-logs` | Log pattern analysis: errors, performance, reconciliation |
| `/code-style` | Go style enforcement: gopls modernize, operator conventions |
| `/test-operator` | Testing and QA: quick/standard/full, lint, security scanning |
| `/code-review` | Code review against dev-docs conventions and lib-common patterns |
| `/backport-review` | Compare downstream backports against upstream Gerrit patches |
| `/jira` | Jira integration: hierarchy validation, outcome posting |
| `/bug` | Bug fix planning — alias for `/feature` with bug-focused context |

## Agent Teams (Experimental)

When `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set, several skills support
parallel execution via agent teams. When not enabled, all skills fall back to
their standard sequential behavior.

| Skill | Team Mode | Teammates |
|-------|-----------|-----------|
| `/code-review` | 3 parallel reviewers (conventions, quality, security) | reviewer |
| `/feature` | 4 parallel researchers (lib-common, peers, dev-docs, devil's advocate) | researcher |
| `/task-executor` | Parallel independent task groups in worktrees | implementer |
| `/debug-operator` | Parallel hypothesis testing | researcher |

Team-specific agents:

| Agent | Role | Write Access |
|-------|------|--------------|
| `researcher` | Read-only analysis and investigation | No |
| `implementer` | Task execution in isolated worktree | Yes |
| `reviewer` | Focused code review with cross-validation | No |

See [docs/design/teams.md](docs/design/teams.md) for architecture details.

## Coding Conventions

- Skills follow the SKILL.md + AGENT.md pattern. Do not put domain logic in SKILL.md.
- Shell scripts must pass `shellcheck`. Markdown must pass `markdownlint`.
- Run `pre-commit run --all-files` before committing to catch lint issues.
- Never hardcode absolute paths. Use relative paths or `~` expansion.
- All commits must be signed: `git commit -s -S`.
- All external comments (Jira, GitHub) must start with `[AI-GENERATED]`.
- Only use emojis if the user explicitly requests it. Avoid using emojis unless asked.

## Command Reference

| Command | Purpose |
|---------|---------|
| `make install` | Install plugin for Claude Code |
| `make install-opencode` | Install plugin for OpenCode |
| `make test` | Run plugin validation tests |
| `make test-memory` | Run memory/state/worktree tests |
| `make test-teams` | Run agent teams infrastructure tests |
| `pre-commit run --all-files` | Lint all files (shellcheck, markdownlint, yaml, json) |

## References

- [dev-docs](https://github.com/openstack-k8s-operators/dev-docs) — operator development conventions
- [lib-common](https://github.com/openstack-k8s-operators/lib-common) — shared libraries and patterns
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) — extending this plugin
- [docs/mcp-setup.md](docs/mcp-setup.md) — MCP server setup (Jira)

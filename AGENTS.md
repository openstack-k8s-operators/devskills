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
| `agents/` | AGENT.md domain knowledge (code-review, feature, task-executor) |
| `scripts/` | Utility scripts (install, scaffold) |
| `docs/` | User-facing documentation and design decisions |
| `tests/` | Plugin validation tests |

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
| `pre-commit run --all-files` | Lint all files (shellcheck, markdownlint, yaml, json) |

## References

- [dev-docs](https://github.com/openstack-k8s-operators/dev-docs) — operator development conventions
- [lib-common](https://github.com/openstack-k8s-operators/lib-common) — shared libraries and patterns
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) — extending this plugin
- [docs/mcp-setup.md](docs/mcp-setup.md) — MCP server setup (Jira)

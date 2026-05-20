# Contributing

Contributions are welcome. Here's how to get started.

## Getting Started

1. Fork the repository
2. Clone your fork and create a feature branch
3. Install the plugin locally for testing:

   ```bash
   ./scripts/install.sh --claude-code
   ```

## Adding Skills

Skills are the primary extensibility mechanism. See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for the full guide.

### Quick checklist

- Create `skills/<skill-name>/SKILL.md` with YAML frontmatter (name, description, user-invocable, allowed-tools, context)
- If the skill needs domain knowledge, create `agents/<skill-name>/AGENT.md` and have the SKILL.md load it as a mandatory first step
- Copy the SKILL.md to `.claude/skills/<skill-name>/SKILL.md` for local auto-discovery during development
- Update `CLAUDE.md` with the new skill documentation
- Update `README.md` skills table

### Choosing a pattern

Most skills fall into one of two patterns. If the skill performs a
straightforward workflow (run commands, parse output, report), keep it
self-contained. If it needs deep domain knowledge, complex evaluation criteria,
or a reusable methodology, split it into a skill (orchestrator) and an agent
(worker) -- the agent runs in its own context and holds all the domain logic.

When using the agent-backed pattern, scaffold both pieces and wire them
together:

```bash
make new-skill my-skill
make new-agent my-skill
```

Then add `"Agent"` to the skill's `allowed-tools` and add the dispatch call:

```
Agent(subagent_type="openstack-k8s-agent-tools:my-skill:my-skill", ...)
```

### Pattern examples

- **Self-contained skill**: see `skills/debug-operator/SKILL.md`
- **Skill + agent**: see `skills/code-review/SKILL.md` + `agents/code-review/AGENT.md`

## Testing

Test your changes with real openstack-k8s-operators operators:

```bash
# Validate existing skills still work
./tests/validate-skills.sh

# Test in Claude Code against an operator repo
cd /path/to/your-operator
claude
/<your-skill>
```

## Submitting Changes

1. Keep commits focused — one logical change per commit
2. Write clear commit messages explaining the "why"
3. Ensure existing skills are not broken by your changes
4. Submit a pull request with a description of what you're adding and why

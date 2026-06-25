# Evals

Behavioral testing for openstack-k8s-agent-tools skills and sub-agents.

Evals test whether skills produce correct, well-structured output when
given known inputs. They complement the structural validation in `tests/`
by invoking skills through the Claude Agent SDK and asserting on the
output using score-based Python graders.

## Framework

Evals use [promptfoo](https://promptfoo.dev) with the following providers:

| Provider | ID | Notes |
|----------|-----|-------|
| Claude Code | `anthropic:claude-agent-sdk` | Default. Uses Vertex AI or `ANTHROPIC_API_KEY` |
| OpenCode | `opencode:sdk` | It might be run via local url: `opencode serve --port 8222` running locally |

Each skill has its own directory under `evals/` containing a self-contained
eval configuration.

## Quick Start

```bash
make eval-setup                      # install dependencies (one-time)
make eval EVAL_SKILL=code-review     # run evals for a single skill
make eval                            # run all evals
make eval-view                       # browse results in promptfoo web UI
make eval-clean                      # remove dependencies and artifacts
```

## Eval Directory Structure

Each skill eval is self-contained:

```
evals/<skill>/
  eval.yaml         # promptfoo config: providers, prompts, tests, assertions
  prompt.txt        # prompt template with {{target_file}} substitution
  graders/          # Python scoring scripts (score-based, threshold-gated)
  fixtures/         # input files the skill will process
```

## Skills

| Skill | Tests | Description |
|-------|-------|-------------|
| [code-review](code-review/README.md) | 5 | Structured review output, severity classification, skill invocation, agent methodology |
| [code-style](code-style/README.md) | 4 | Style recommendations, error handling detection, modernization issue detection |
| [onboarding-buddy](onboarding-buddy/README.md) | 5 | Track A/B input routing, fixture repo discovery, explain-flow delegation |

## Adding Evals for a New Skill

1. Create `evals/<skill-name>/` with:
   - `eval.yaml` — copy from an existing skill, change the skill name and tests
   - `prompt.txt` — one-line prompt template
   - `fixtures/` — input files the skill will process
   - `graders/` — Python scoring scripts

2. Each grader is a Python file with a `get_assert(output, context)` function
   that returns `{"pass": bool, "score": float, "reason": str}`.

3. Run: `make eval EVAL_SKILL=<skill-name>`

## Test Tiers

- **Smoke** — structural checks: "did the skill produce output that looks
  right?" Uses broad pattern matching with low thresholds (0.4).
- **Standard** — behavioral checks: "did the skill catch the planted issues
  and follow its methodology?" Uses specific pattern matching with higher
  thresholds (0.5-0.75).

## Graders

Graders are score-based Python scripts under `graders/`. Each checks
multiple indicator patterns and returns a score between 0.0 and 1.0.
A test passes when the score meets the configured threshold.

This approach is resilient to LLM output variation — the model can use
different wording and still pass, as long as enough indicator patterns
match.

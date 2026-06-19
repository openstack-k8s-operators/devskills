# code-style Eval

Tests the `/code-style` skill (self-contained, no sub-agent dispatch).

## Providers

| Provider | Model | Prompt | Status |
|----------|-------|--------|--------|
| `anthropic:claude-agent-sdk` | `claude-sonnet-4-6` | Natural language (`prompt.txt`) | Active |
| `opencode:sdk` | — | — | Not yet configured for this skill |

## Prompts

- `prompt.txt` — `Analyze the Go file ... for code style issues following openstack-k8s-operators conventions.`

## Fixtures

| File | Purpose |
|------|---------|
| `needs-modernize.go` | Old-style slice/map declarations, string concatenation in loops, `Get` prefix on accessor |
| `bad-error-handling.go` | Capitalized error strings, discarded errors, unnecessary else after return, missing `%w` wrapping |

## Tests

| Test | Tier | Grader | Threshold | What it checks |
|------|------|--------|-----------|----------------|
| `smoke/needs-modernize-gets-recommendations` | smoke | `smoke_recommendations.py` | 0.4 | Output contains style-related indicators (style, convention, declaration, error, fix) |
| `smoke/bad-error-handling-gets-findings` | smoke | `smoke_recommendations.py` | 0.4 | Same broad check for the error handling fixture |
| `standard/catches-error-handling-issues` | standard | `error_handling_issues.py` | 0.5 | Detects capitalized errors, missing wrapping, discarded errors, unnecessary else |
| `standard/catches-modernization-issues` | standard | `modernization_issues.py` | 0.5 | Detects old-style declarations, string concatenation, naming issues |

## Graders

| Grader | Checks | Score model |
|--------|--------|-------------|
| `smoke_recommendations.py` | style/convention keywords, declaration patterns, concat/builder, naming, error handling | 5 groups, 0.2 each |
| `error_handling_issues.py` | error casing, error wrapping, discarded errors, unnecessary else | 4 groups, 0.25 each |
| `modernization_issues.py` | slice declarations, map declarations, string concatenation, naming conventions | 4 groups, 0.25 each |

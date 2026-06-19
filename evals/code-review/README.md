# code-review Eval

Tests the `/code-review` skill and its sub-agent dispatch.

## Providers

| Provider | Model | Prompt | Status |
|----------|-------|--------|--------|
| `anthropic:claude-agent-sdk` | `claude-sonnet-4-6` | Natural language (`prompt.txt`) | Active |
| `opencode:sdk` | `claude-sonnet-4-20250514` | Explicit invocation (`prompt-explicit.txt`) | Commented out — requires `opencode serve --port 8222` |

## Prompts

- `prompt.txt` — `Review the Go file ... for openstack-k8s-operators conventions.`
- `prompt-explicit.txt` — `/code-review ...` (explicit skill invocation)

## Fixtures

| File | Purpose |
|------|---------|
| `bad-controller.go` | GlanceAPI controller with 8 planted issues (missing finalizer, no ObservedGeneration, hardcoded image, fmt.Printf, wrong condition severity, missing error wrapping, read-after-write race, long receiver name) |
| `good-controller.go` | Clean GlanceAPI controller following all openstack-k8s-operators conventions |

## Tests

| Test | Tier | Grader | Threshold | What it checks |
|------|------|--------|-----------|----------------|
| `smoke/bad-controller-request-changes` | smoke | `smoke_review_structure.py` | 0.4 | Output contains review structure (headings, severity, verdict, findings, line refs) + `REQUEST CHANGES` verdict |
| `smoke/good-controller-produces-review` | smoke | `smoke_review_structure.py` | 0.4 | Clean code still produces a structured review |
| `standard/bad-controller-finds-finalizer-issue` | standard | `finds_finalizer_issue.py` | 0.5 | Identifies finalizer, ObservedGeneration, and error wrapping issues at Critical severity |
| `standard/skill-invocation` | standard | `skill-used` (builtin) | — | Verifies the `Skill` tool was called for `openstack-k8s-agent-tools:code-review` |
| `standard/agent-methodology-followed` | standard | `agent_methodology.py` | 0.75 | Output has Critical + Major severity levels, file:line references, and a verdict |

## Graders

| Grader | Checks | Score model |
|--------|--------|-------------|
| `smoke_review_structure.py` | review heading, severity keywords, verdict, findings, line references | 5 groups, 0.2 each |
| `finds_finalizer_issue.py` | finalizer, critical severity, ObservedGeneration, error wrapping | 4 groups, 0.25 each |
| `agent_methodology.py` | Critical present, Major present, line references, verdict | 4 checks, 0.25 each |

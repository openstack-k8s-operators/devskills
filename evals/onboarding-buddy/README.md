# onboarding-buddy Eval

Behavioral tests for the `/onboarding-buddy` skill — input routing, repo
discovery, and `/explain-flow` delegation. These are smoke/standard checks,
not full conversational e2e runs (token cost would be too high).

## Providers

| Provider | Model | Working dir | Status |
|----------|-------|-------------|--------|
| `anthropic:claude-agent-sdk` | `claude-sonnet-4-6` | `fixtures/sample-operator/` | Active |

Uses `ask_user_question.behavior: deny` so eval runs stay single-turn and do not
auto-chain through interactive menus (which caused Track A/B routing drift).
Prompts also include `Automated eval — respond in ONE turn` instructions.

## Prompts

| File | Track | Purpose |
|------|-------|---------|
| `prompt-fundamentals.txt` | A | `/onboarding-buddy basics` — operator stack fundamentals |
| `prompt-repo.txt` | B | `/onboarding-buddy repo` — repo tour from fixture operator |
| `prompt-cr.txt` | B | `/onboarding-buddy Nova` — CR-specific routing |
| `prompt-explain-flow.txt` | B | Deep reconciler trace — should delegate to `/explain-flow` |
| `prompt-skill-invoke.txt` | B | Natural-language repo tour (no `/onboarding-buddy` prefix) |
| `prompt.txt` | B | Alias of repo tour (required by validate-evals.sh) |

## Fixtures

`fixtures/sample-operator/` is a minimal mock operator repo with:

| Path | Purpose |
|------|---------|
| `AGENTS.md` | CR catalog (Nova, GlanceAPI), directory map, reconcile path |
| `doc/design.md` | Operator-specific design notes |
| `AGENTS.md` | Build/test commands and conventions |
| `api/nova/v1beta1/nova_types.go` | Nova CR type |
| `api/glance/v1beta1/glanceapi_types.go` | GlanceAPI CR type |
| `internal/controller/nova/nova_controller.go` | Reconciler stub for explain-flow handoff |

Evals use the fixture as the working directory instead of cloning a real
operator repo — keeps runs fast, offline, and deterministic.

## Tests

| Test | Tier | Grader / assertion | Threshold | What it checks |
|------|------|-------------------|-----------|----------------|
| `smoke/track-a-fundamentals` | smoke | `track_a_fundamentals.py` | 0.5 | Track A: mentions client-go, controller-runtime, kubebuilder |
| `smoke/track-b-repo-discovery` | smoke | `track_b_repo_discovery.py` | 0.5 | Track B: reads AGENTS.md, CRs, layout, reconcile path |
| `smoke/cr-routing-nova` | smoke | `cr_routing.py` | 0.5 | CR arg routes to Nova — OpenStack role, API type, controller paths |
| `standard/natural-language-repo-tour` | standard | `natural_language_repo_tour.py` | 0.5 | Natural-language prompt gives full tour (rejects Step 0 menus) |
| `standard/explain-flow-delegation` | standard | `explain_flow_handoff.py` + `skill-used` | 0.5 | Hands off to `explain-flow` for reconciler trace |

## Graders

| Grader | Checks | Score model |
|--------|--------|-------------|
| `track_a_fundamentals.py` | client-go, controller-runtime, kubebuilder, teaching style | 4 groups, 0.25 each |
| `natural_language_repo_tour.py` | Rejects Step 0 menus; requires Nova/GlanceAPI CR catalog | 4 groups + mandatory CR catalog |
| `track_b_repo_discovery.py` | CR catalog, directory layout, reconcile path, tour framing | 4 groups, 0.25 each |
| `cr_routing.py` | Nova CR, OpenStack compute role, API path, controller path | 4 groups, 0.25 each |
| `explain_flow_handoff.py` | explain-flow mention, Nova controller, flow artifact, handoff context | 4 groups, 0.25 each |

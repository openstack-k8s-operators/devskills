# create-dt Evals

Behavioral tests for the `/create-dt` skill and its sub-agent.

## Provider

| Provider | Model | Label |
|----------|-------|-------|
| `anthropic:claude-agent-sdk` | `claude-sonnet-4-6` | claude-code |

4 tests across smoke and standard tiers.

## Prompt

`prompt.txt` asks the agent to create a DT from requirements and an
existing topology listing, following all 7 steps of the create-dt process.

## Fixtures

| File | Purpose |
|------|---------|
| `sample-dt-request.md` | Nova + Ceph HCI + 3 computes + IPv4 VLANs + MetalLB L2 |
| `sample-architecture-tree.txt` | Simulated `find dt/ va/` output with uni01alpha, uni07epsilon, nova02beta, va/hci |
| `expected-context-summary.md` | Expected Step 1 output structure with all required fields |
| `expected-automation-vars.yaml` | Expected automation vars with stages (nncp, network, control-plane, edpm) |

## Tests

| Test | Tier | Key Check |
|------|------|-----------|
| `produces-dt-structure` | smoke | Output contains kustomize structure, automation vars, stage ordering, DT paths |
| `context-summary-fields` | smoke | Context Summary has services, storage, network, node roles |
| `identifies-hci-base` | standard | Agent identifies closest HCI base, scores candidates, notes VA-vs-DT |
| `agent-methodology-followed` | standard | Output covers analysis, strategy, generation steps with stage references |

## Graders

| Grader | Checks | Threshold |
|--------|--------|-----------|
| `smoke_dt_structure.py` | kustomize kind, automation vars, stage ordering, DT paths, values files (0.2 each) | 0.4 |
| `context_summary.py` | services, storage, network, nodes, summary heading (0.2 each) | 0.4 |
| `identifies_hci_base.py` | HCI base identification, candidate scoring, ceph references, VA-vs-DT distinction (0.25 each) | 0.5 |
| `agent_methodology.py` | analysis, strategy, generation, stage references (0.25 each) | 0.75 |

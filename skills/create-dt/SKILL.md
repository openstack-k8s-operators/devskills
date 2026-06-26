---
name: create-dt
description: "Scaffold RHOSO Deployment Topologies/Validated Architectures for the architecture repo with existing DT/VA analysis, kustomize generation, and staged automation"
argument-hint: "<ticket-id | spec-file.md | requirements text> [--continue]"
user-invocable: true
allowed-tools: ["Bash", "Read", "Write", "Grep", "Glob", "WebFetch", "Agent", "TaskCreate", "TaskUpdate"]
context: fork
---

# /create-dt — Deployment Topology Generator

Orchestrator skill that scaffolds new Deployment Topologies (DTs) in the
[architecture repo](https://github.com/openstack-k8s-operators/architecture).
Analyzes both existing DTs and VAs as candidates, then dispatches a
`create-dt` agent for generation.

## Input Routing

Determine the input source from the user's argument:

| Pattern | Source | Action |
|---------|--------|--------|
| `OSPRH-\d+`, `OSPA-\d+`, or `[A-Z]+-\d+` Jira key | Jira ticket | Fetch ticket via Atlassian MCP. Extract services needed, hardware specs, storage backend, network topology, node count and roles from the description and acceptance criteria. If MCP is unavailable, ask the user to paste the ticket description. |
| Path to a `.md`, `.yaml`, `.yml`, or `.txt` file | Spec file | Read the file. Extract requirements from its content. |
| `--continue` (with or without other args) | Resume | Skip input routing and resume from the most recent matching plan file. |
| Anything else | Free-text | Treat the entire argument as a requirements description. |
| No argument | Interactive | Ask the user what topology they need. |

## Resume Detection

Check for existing DT plans:

```
~/.openstack-k8s-agent-plans/architecture/YYYY-MM-DD-<ticket-or-slug>-dt-plan.md
```

If a matching plan exists:
- **Incomplete** → offer to resume from the first missing section
- **Strategy not yet approved** → re-present strategies for approval
- **Complete but not generated** → offer to generate files
- **Fully generated** → note completion, ask if they want to start fresh

## Prerequisites

| Dependency | Required | Purpose |
|------------|----------|---------|
| Architecture repo clone | **Yes** | Must be run from or have access to a local clone of `openstack-k8s-operators/architecture` |
| `kustomize` or `oc` | **Yes** | Build and validate kustomize overlays |
| `yamllint` | **Yes** | YAML validation |
| `yamale` | **Yes** | Automation schema validation |
| Atlassian MCP | Optional | Fetch Jira ticket details for requirements |
| `gh` CLI | Optional | Create PR after generation |

## Workflow

1. **Determine input** — route per table above
2. **Locate architecture repo** — find the local clone (check cwd, common paths, ask user)
3. **Pre-flight check** — verify each required tool individually:
   - `kustomize` or `oc` (at least one)
   - `yamllint` (`pip install yamllint`)
   - `yamale` — YAML schema validator (`pip install yamale`), used by the architecture repo to validate automation vars against `.ci/automation-schema.yaml`

   If any tool is missing, list the missing ones with install instructions and stop.
4. **Check for existing plan** — resume if found
5. **Dispatch agent** — single dispatch; the agent handles the full flow
   (analysis, strategy proposal, HITL gate, generation, validation) internally:

```
Agent(
  subagent_type="openstack-k8s-agent-tools:create-dt:create-dt",
  prompt="<context summary with requirements, architecture repo path, and any existing plan>"
)
```

6. **Report results** — relay the agent's output: generated files, validation status, environment-specific action items

## Architecture Repo Location

The skill must locate a local clone of `openstack-k8s-operators/architecture`. Search order:

1. Current working directory (if it contains `lib/` and `dt/` directories)
2. Parent directories (up to 3 levels)
3. `~/projects/architecture`, `~/go/src/github.com/openstack-k8s-operators/architecture`
4. Ask the user for the path

## Output

The agent writes a plan file to:
```
~/.openstack-k8s-agent-plans/architecture/YYYY-MM-DD-<ticket-or-slug>-dt-plan.md
```

Generated DT files go directly into the architecture repo working tree.

## Quick Reference — Generated DT Components

Every new DT requires these components (the agent also reads existing VAs
with the same structure during analysis):

| Component | Path | Description |
|-----------|------|-------------|
| Kustomization | `dt/<name>/kustomization.yaml` | Kustomize Component assembling services from `lib/` |
| Network values | `dt/<name>/values.yaml` | Subnets, VLANs, IPs, MetalLB config |
| Service values | `dt/<name>/service-values.yaml` | Service-specific config (replicas, features) |
| Control plane | `dt/<name>/control-plane/` | Control plane overlays |
| Dataplane | `dt/<name>/edpm*/` | EDPM nodeset and deployment definitions |
| Networking | `dt/<name>/networking/` | MetalLB, NAD, netconfig (if needed) |
| Automation vars | `automation/vars/<name>.yaml` | Staged deployment pipeline |
| Examples | `examples/dt/<name>/` | User-facing customizable layer |
| Documentation | `dt/<name>/README.md` | Topology description and usage |

## Validation

The agent runs all required validation checks (yamllint, test-kustomizations,
yamale, schema-paths, zuul-jobs) as part of its Step 5. See AGENT.md for the
full validation sequence.

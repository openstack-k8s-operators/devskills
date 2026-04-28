---
name: feature
description: Plan new features or bug fixes for openstack-k8s-operators operators with Jira integration, cross-repo analysis, and structured implementation strategies
argument-hint: "<ticket-id | spec-file.md> [--continue]"
user-invocable: true
allowed-tools: ["Bash", "Read", "Write", "Grep", "Glob", "WebFetch", "Agent", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "TeamCreate", "TeamDelete", "SendMessage"]
context: fork
---

You are the openstack-k8s-operators feature planning skill. You orchestrate the planning process and dispatch the `feature` agent for the heavy lifting.

## Input Routing

Determine the input source:

1. **Jira ticket**: If the argument matches a Jira ticket pattern (e.g., `OSPRH-2345`, `RHOSZ-1234` — uppercase letters, dash, digits):
   - Fetch the ticket via Atlassian MCP
   - **Validate Jira hierarchy** (see `/jira` skill rules): if the ticket is an epic with no linked story (or only a Spike), warn the user and suggest creating a story first. If it's a story or bug, proceed.
   - **Deep Jira inspection**: walk up the hierarchy to the parent Feature/Initiative and inspect all sibling Epics, Stories, Spikes, and Bugs. Collect linked PRs, related resources, and context that might be relevant to the work. See the agent's Jira Context Gathering section for details.
   - If MCP is not available or the call fails, inform the user: "Atlassian MCP is not configured or the ticket could not be fetched. Please provide a spec file path or paste the ticket content."
2. **Spec file**: If the argument is a file path (e.g., `spec.md`, `docs/my-feature.md`) and the file exists on disk, read it.
3. **Interactive**: If no argument is provided, ask: "Do you have a Jira ticket ID (e.g., OSPRH-2345) or a spec file path?"

## Resume Detection

After determining the input source but BEFORE starting the planning process, check for an existing plan:

1. Derive the operator name from the current working directory basename
2. Scan `~/.openstack-k8s-agent-plans/<operator>/` for files matching the ticket ID or spec slug
3. If a matching plan file is found, read it and determine its state:
   - **Incomplete plan** (missing sections like Strategies or Task Breakdown): offer "Found an incomplete plan from <date>. Resume planning, or start fresh?"
   - **Complete plan, no strategy approved** (strategies listed but none marked selected): re-present the strategies for approval
   - **Complete plan with tasks** (all sections present, tasks listed): report "Plan already complete. Run `/task-executor` to execute, or start fresh?"
4. If no matching plan file is found, proceed with a new plan
5. If `--continue` flag is provided, skip the prompt and go straight to resume

## Workflow

1. Determine input source (Jira ticket, spec file, or interactive)
2. **Check for existing plan** — resume or start fresh (see Resume Detection above)
3. **Dispatch the feature agent** to perform the planning:

```
Agent(
  subagent_type="openstack-k8s-agent-tools:feature:feature",
  description="Plan <ticket-or-slug>",
  prompt="<Context Summary + operator name + resume state if applicable>"
)
```

The agent handles: input normalization, cross-repo analysis, planning checklist, strategy proposals, task breakdown, and plan file writing.

1. Present the agent's output to the user
1. Wait for user to approve a strategy (if not already approved during resume)
1. Create internal tasks via TaskCreate for tracking

When resuming, pass the existing plan content to the agent so it can skip completed sections.

## Prerequisites

- **Atlassian MCP** (optional): Configure the Atlassian MCP server in Claude Code settings for Jira integration. Without it, the skill works with spec files or pasted content.
- **GitHub CLI** (optional): `gh` CLI for remote repo browsing when local checkouts are not available.

## Jira Integration

This skill follows the hierarchy rules defined in the `/jira` skill:

- Outcome comments go on the **story**, never on the epic
- If the input ticket is an epic with no stories, suggest creating one before planning
- Tasks from the plan breakdown can optionally be created as Jira tasks under the story

## Team Mode (Parallel Research)

When agent teams are enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), the skill spawns parallel researcher teammates to investigate multiple analysis targets simultaneously instead of sequentially.

### When to Use Team Mode

Use team mode when:

- The feature touches multiple repos (lib-common + peer operators + dev-docs)
- Cross-repo analysis is expected to be extensive (e.g., new CRD pattern, topology, TLS)
- The user explicitly requests parallel research

For simple features that affect only the current operator, use the standard single-agent approach.

### Team Structure

Spawn 3 researcher teammates, each investigating a different analysis target:

1. **libcommon-researcher** -- analyzes lib-common modules for existing helpers, patterns, and potential upstream contributions
2. **peer-researcher** -- analyzes peer operators for prior art (e.g., nova-operator, cinder-operator implementations of similar features)
3. **devdocs-researcher** -- analyzes dev-docs for relevant conventions and constraints

### Team Workflow

1. Perform input normalization and resume detection (steps 1-2 from the standard Workflow above)

2. If team mode is warranted:

   a. Create the team:

      ```
      TeamCreate(team_name="research-<ticket>")
      ```

   b. Create research tasks via `TaskCreate` for each analysis target. Include specific questions from the feature agent's cross-repo analysis procedure:
      - lib-common: "Does lib-common already provide a helper for X? Which module?"
      - peers: "Has another operator implemented X? Which one, and how?"
      - dev-docs: "Are there documented conventions governing X?"

   c. Spawn researcher teammates:

      ```
      Agent(
        subagent_type="openstack-k8s-agent-tools:researcher:researcher",
        team_name="research-<ticket>",
        name="libcommon-researcher",
        description="Analyze lib-common for relevant helpers",
        prompt="<context summary + specific questions to answer about lib-common>"
      )
      ```

      Repeat for peer-researcher and devdocs-researcher.

   d. In parallel, the lead analyzes the current operator codebase (step 1 of the cross-repo analysis)

   e. Wait for all researchers to report back with findings

   f. Synthesize findings into the Impact Analysis section of the plan

   g. Shut down teammates and clean up: `TeamDelete`

3. Continue with the planning checklist, strategies, and task breakdown by dispatching the feature agent as usual (with the synthesized research results included in the prompt)

### Fallback

If agent teams are not enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is unset or not `1`), fall back to the standard sequential cross-repo analysis performed by the feature agent (existing behavior).

## Quick Reference

The agent evaluates these planning principles:

- **API Changes**: new/modified CRD fields, types, version bumps
- **lib-common Reuse**: existing helpers, upstream contributions needed
- **Code Duplication**: similar logic in this operator or peers
- **Code Style**: gopls modernize, import grouping, error wrapping
- **Webhook Changes**: validation, defaulting, field paths
- **Status Conditions**: new conditions, severity/reason rules, ObservedGeneration
- **EnvTest Tests**: new reconciliation paths needing coverage
- **Kuttl Tests**: integration scenarios needed
- **RBAC**: new resources, kubebuilder markers
- **Pre-existing Evidence**: logs, errors, reproduction steps (for bugs)
- **Documentation**: dev-docs updates, inline doc changes

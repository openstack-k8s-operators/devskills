# Agent Teams Design

Architecture and design decisions for agent team support in
openstack-k8s-agent-tools.

## Overview

Agent teams allow multiple Claude Code instances to work in parallel on
a shared task list, communicating directly with each other. This plugin
uses teams to parallelize four workflows: code review, feature research,
task execution, and debugging.

Teams are **experimental** and gated behind
`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. When not enabled, all skills
fall back to their existing sequential behavior.

## Architecture

```
                    User
                      |
                      v
                 +----------+
                 |  Skill   |  (SKILL.md — orchestrator)
                 +----------+
                      |
          +-----------+-----------+
          |                       |
     teams enabled?          teams disabled
          |                       |
          v                       v
   +-------------+        +-------------+
   | TeamCreate  |        | Agent(...)  |  Standard subagent dispatch
   +-------------+        +-------------+
          |
   +------+------+------+
   |      |      |      |
   v      v      v      v
  T1     T2     T3    Lead
  (researcher/   (lead does own
   implementer/   work in parallel)
   reviewer)
          |
   All report findings via SendMessage
          |
          v
   +-------------+
   | Synthesize  |  Lead combines results
   +-------------+
          |
          v
   +-------------+
   | TeamDelete  |  Cleanup
   +-------------+
```

## Team Roles

Three new agent definitions (in `agents/`) provide specialized team
roles. They are separate from the existing agents (`feature`,
`task-executor`, `code-review`) because team roles need narrower scope,
coordination awareness (SendMessage, TaskList), and in the case of the
implementer, inlined code quality standards.

| Agent | File | Purpose | Write Access |
|-------|------|---------|-------------|
| `researcher` | `agents/researcher/AGENT.md` | Read-only investigation | No |
| `implementer` | `agents/implementer/AGENT.md` | Task execution in worktree | Yes |
| `reviewer` | `agents/reviewer/AGENT.md` | Focused code review | No |

### Why Separate Agents?

The existing agents (`feature`, `task-executor`, `code-review`) are
complex workers with deep methodology designed for the subagent dispatch
pattern. Team roles need:

1. **Narrower scope** — a reviewer checks one focus area, not all 11
   criteria
2. **Coordination awareness** — teammates use SendMessage, TaskList,
   TaskUpdate
3. **Inlined standards** — the `skills:` frontmatter field is NOT
   applied when an agent runs as a teammate, so the implementer must
   inline code quality rules
4. **Read-only enforcement** — researcher and reviewer use
   `disallowedTools` to prevent writes

## Workflows

### 1. Parallel Code Review (`/code-review`)

```
Skill detects large diff (5+ files or 500+ lines)
    |
    v
TeamCreate("review-<scope>")
    |
    +-- conventions-reviewer (Focus A: criteria 1-6)
    +-- quality-reviewer (Focus B: criteria 7-11)
    +-- security-reviewer (Focus C: cross-cutting security)
    |
    v
Each reviewer produces initial findings
    |
    v
Lead shares findings cross-team for adversarial validation
    |
    v
Reviewers produce second-pass (agreements/disagreements)
    |
    v
Lead synthesizes into unified review report
    |
    v
TeamDelete
```

### 2. Parallel Feature Research (`/feature`)

```
Skill detects cross-repo feature
    |
    v
TeamCreate("research-<ticket>")
    |
    +-- libcommon-researcher (lib-common modules)
    +-- peer-researcher (peer operator prior art)
    +-- devdocs-researcher (convention docs)
    |
    | Lead analyzes current operator in parallel
    v
3 researchers report findings
    |
    v
Spawn devils-advocate with all findings
    |
    v
Devil's advocate critiques: unsupported assumptions,
missed alternatives, risks, convention gaps
    |
    v
Lead synthesizes findings + critique into Impact Analysis
    |
    v
TeamDelete
    |
    v
Continue with planning (dispatch feature agent with research results)
```

### 3. Parallel Task Execution (`/task-executor`)

```
Skill analyzes plan dependency graph
    |
    v
Identify parallel waves (independent groups)
    |
    v
TeamCreate("execute-<ticket>")
    |
    +-- implementer-group-1 (worktree: .worktrees/<ticket>-group-1)
    +-- implementer-group-5 (worktree: .worktrees/<ticket>-group-5)
    |
    v
Each implementer executes its group's tasks
    |
    v
On group completion: code-review agent dispatched per group
    |
    v
All parallel groups done → merge worktrees
    |
    v
Next wave (or sequential groups)
    |
    v
Final review, commit, TeamDelete, worktree cleanup
```

### 4. Parallel Debugging (`/debug-operator`)

```
Skill triages symptoms → forms 2-3 hypotheses
    |
    v
TeamCreate("debug-<operator>")
    |
    +-- hypothesis-1 (researcher investigating theory A)
    +-- hypothesis-2 (researcher investigating theory B)
    +-- hypothesis-3 (researcher investigating theory C)
    |
    v
Each investigator reports findings
    |
    v
Lead shares findings cross-team for adversarial validation
    |
    v
Lead identifies best-supported hypothesis
    |
    v
Present consolidated diagnosis, TeamDelete
```

## State Coordination

### MEMORY.md

No format changes. The team lead reads and writes MEMORY.md. Teammates
do not access MEMORY.md directly — they report findings to the lead,
who updates MEMORY.md.

### state.json

When multiple implementer teammates work in parallel worktrees, each
is registered as a separate entry in `active_tasks` with distinct
worktree paths and branch names.

### Team Config (~/.claude/teams/)

Team metadata is managed by Claude Code's built-in TeamCreate/TeamDelete
tools. The plugin does not manage this directly. Teams are ephemeral —
created at skill invocation and deleted when the work completes.

## Worktree Management

The `lib/team-helpers.sh` script provides helpers:

- `create_team_worktree <ticket> <group>` — creates
  `.worktrees/<ticket>-group-<group>` with branch
  `feature/<ticket>-group-<group>`
- `remove_team_worktree <worktree-dir>` — removes worktree and branch

After all implementer teammates complete, the lead merges worktrees.
Merge conflicts are resolved at the lead level and presented to the user.

## Key Constraints

1. **`skills:` frontmatter not applied to teammates** — the
   implementer inlines code quality rules; the reviewer inlines review
   criteria
2. **Separate context windows** — each teammate gets the spawn prompt
   plus project context (CLAUDE.md, MCP), but not the lead's
   conversation history
3. **No nested teams** — teammates cannot spawn their own teams
4. **One team per session** — clean up before starting a new team
5. **Team overhead** — spawning 3 teammates for a 10-line change is
   wasteful; skills include heuristics to avoid this

## Graceful Degradation

Every skill that supports team mode includes a **Fallback** section.
When `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is unset or not `1`, the
skill uses its standard sequential workflow — dispatching a single
subagent as before. The user experience is identical to pre-team
behavior.

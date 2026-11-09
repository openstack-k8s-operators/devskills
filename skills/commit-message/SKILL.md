---
name: commit-message
description: Draft a consistent commit message for operator changes, with a linked Jira reference when the work comes from a Jira ticket
argument-hint: "[Jira-key] [change summary]"
user-invocable: true
allowed-tools: ["Bash", "Read", "Agent"]
context: fork
---

You are the openstack-k8s-operators commit-message skill. Draft a message for the current changes following the [Git commit guidelines](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project); do not create a commit. The agent defines the shared message format.

1. Collect the change summary and source from the user's input. If needed, inspect the staged diff and current diff to understand the changes. If the scope or Jira source is unclear, ask for clarification instead of guessing.
2. Dispatch the `commit-message` agent with the change summary, relevant diff context, and the Jira key **only if it was explicitly provided or recorded as the plan's Jira source**:

```
Agent(
  subagent_type="openstack-k8s-agent-tools:commit-message:commit-message",
  description="Draft commit message",
  prompt="<changes and rationale; Jira source key if applicable>"
)
```

1. Present the agent's draft verbatim for the user to review. Committing, signing, and approval belong to the invoking workflow or user.

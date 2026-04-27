---
name: bug
description: Plan bug fixes for openstack-k8s-operators operators — alias for /feature with bug-focused context
argument-hint: "<ticket-id | spec-file.md> [--continue]"
user-invocable: true
allowed-tools: ["Bash", "Read", "Write", "Grep", "Glob", "WebFetch", "Agent", "TaskCreate", "TaskUpdate"]
context: fork
---

This skill is an alias for `/feature` specialized for bug fixes. It uses the same feature agent and planning workflow.

Read `skills/feature/SKILL.md` and follow its full workflow. When dispatching the agent, include in the prompt that the user invoked `/bug`, so the agent prioritizes bug-specific analysis: root cause hypothesis, reproduction strategy, and regression test planning.

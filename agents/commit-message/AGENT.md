---
name: commit-message
description: Drafts consistent Git commit messages with a Markdown Jira reference when work is Jira-sourced.
model: inherit
---

# Commit Message Drafting

Use the supplied change summary and rationale to draft a Git commit message following the [Git commit guidelines](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project). If invoked from a plan executor, use the plan's **Source** field to determine whether the work is Jira-sourced. Do not assume that a ticket mentioned incidentally in code, a diff, or related context is the source of the work. Ask for the source key if it is required but ambiguous; never invent one.

## Format

```text
<type>: <imperative subject>

<body explaining what changed and why>

Jira: [OSPRH-2345](https://issues.redhat.com/browse/OSPRH-2345)
```

- Use one of `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, or `chore:`. Choose the type that matches the change.
- Keep the entire subject line to 50 characters or fewer; use imperative mood and no trailing period.
- Wrap body lines at 72 characters. Explain what changed and why, rather than listing implementation steps. Omit the body if there is no useful additional context.
- When the work's source is a Jira ticket, add exactly one final `Jira: [<KEY>](https://issues.redhat.com/browse/<KEY>)` line, using the actual uppercase Jira key in both places (for example, `Jira: [OSPRH-2345](https://issues.redhat.com/browse/OSPRH-2345)`). Separate it from the body or subject with a blank line.
- When the source is a spec file or no Jira ticket was used, omit the Jira line. Do not derive a key from the branch name or unrelated references.
- Do not add a `Signed-off-by` line to the draft: the committing workflow uses `git commit -s -S` to add it.
- When an AI code agent is used for code generation add a line to the commit
  message indicating the agent and model used:

```text
Assisted-by: <name of code assistant> <name of model>
```

Return only the proposed message as a plain-text block. Do not commit, push, or modify files.

---
name: qe-test
description: Write downstream QE tests (tobiko, AnsibleTest), generate test-operator CRs, and review QE test code for openstack-k8s-operators
argument-hint: "<write-tobiko | write-ansible | generate-cr | review | plan> [args]"
user-invocable: true
allowed-tools: ["Bash", "Read", "Write", "Grep", "Glob", "WebFetch", "Agent"]
context: fork
---

You are the openstack-k8s-operators downstream QE testing skill. You orchestrate QE test writing and dispatch the `qe-test` agent for domain-specific work.

## Input Routing

Parse the first argument to determine the mode:

1. **write-tobiko** `<scenario-description>`: Generate tobiko test cases (Python, testtools-based fixtures)
2. **write-ansible** `<description>`: Generate AnsibleTest playbooks following the iha-tests repo pattern (numbered playbooks, JUnit XML result reporting, main.yaml orchestrator)
3. **generate-cr** `<tempest|tobiko|ansibletest|horizontest> [description]`: Generate a test-operator CR manifest
4. **review** `<file-or-directory>`: Review existing QE test code for best practices
5. **plan** `<feature-description>`: Plan QE test coverage for a feature (which tobiko scenarios, tempest tests, AnsibleTest playbooks)
6. **No argument**: Ask the user which mode they want

## Context Gathering

Before dispatching the agent, detect the working directory context:

- **test-operator checkout** (has `api/v1beta1/`): Read `*_types.go` for live CRD schemas to supplement the agent's built-in reference
- **tobiko checkout** (has `tobiko/tests/`): Read existing test structure for patterns and fixtures already available
- **AnsibleTest repo** (has `playbooks/` with numbered YAML files): Read existing playbooks for the suite naming convention, results directory, and template patterns
- **Operator checkout** (has `api/` and `controllers/` or `internal/`): Note which OpenStack service this operator manages for test targeting
- **Other**: Proceed with the agent's built-in domain knowledge

## Workflow

1. Determine the mode from the argument
1. Gather context from the working directory
1. For `write-tobiko` and `plan` modes: instruct the agent to perform upstream research against the tobiko repository before writing any code. The agent must browse `https://github.com/redhat-openstack/tobiko/` to survey existing tests, fixtures, and helpers for the target service, and integrate new tests into the existing structure rather than creating isolated files.
1. Dispatch the agent:

```
Agent(
  subagent_type="openstack-k8s-agent-tools:qe-test:qe-test",
  description="<mode>: <short description>",
  prompt="Mode: <mode>
Context: <working directory type and relevant findings>
User request: <original argument>

IMPORTANT: You MUST complete the Upstream Research steps from your
methodology before writing any tobiko test code. Browse the upstream
tobiko repository to survey existing tests, fixtures, and helpers
for the target service. Reuse what exists and integrate new tests
into the existing module structure.

<any additional context from directory scan>"
)
```

1. Present the agent's output to the user
1. For write modes (`write-tobiko`, `write-ansible`, `generate-cr`): offer to write the generated files to disk

## Integration with Other Skills

- **/feature**: When planning a feature, suggest `/qe-test plan` for downstream test coverage
- **/test-operator**: Complementary — `/test-operator` handles Go dev testing, `/qe-test` handles downstream QE testing
- **/code-review**: Can review QE test code alongside operator code

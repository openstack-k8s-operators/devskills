---
name: pqc
description: "PQC compliance workflow for openstack-k8s-operators (TLS 1.3, kRSA blocking)"
argument-hint: "<OSPRH-TICKET-KEY | --operator=NAME> [--execute] [--status] [--scan]"
user-invocable: true
allowed-tools: ["Bash", "Read", "Write", "Edit", "Grep", "Glob",
                "WebFetch", "Agent", "TaskCreate", "TaskUpdate"]
context: fork
---

# /pqc -- PQC Compliance for openstack-k8s-operators

Post-Quantum Cryptography compliance workflow for
[openstack-k8s-operators](https://github.com/openstack-k8s-operators/).
Implements TLS 1.3 enforcement and kRSA cipher blocking across multiple operators.

## Supported Operators

| Operator | PQC Patterns | Status |
|----------|-------------|--------|
| horizon-operator | Go TLS + Apache SSL | Tickets assigned (OSPRH-27427) |
| keystone-operator | Go TLS + Apache SSL | Scan needed |
| nova-operator | Go TLS | Scan needed |
| glance-operator | Go TLS | Scan needed |

## Usage

- `/pqc` -- Show usage and list supported operators
- `/pqc --status` -- Show compliance status across all profiled operators
- `/pqc --operator=horizon` -- Show single-operator PQC status and ticket table
- `/pqc OSPRH-28889` -- Plan PQC changes for specific ticket
- `/pqc OSPRH-28889 --execute` -- Plan and execute immediately
- `/pqc --operator=glance --scan` -- Scan operator repo for PQC compliance gaps

## Operator Detection

Determine which operator to target, in priority order:

1. `--operator=<name>` flag (explicit, takes precedence)
2. OSPRH ticket key (look up in the agent's operator profile ticket tables)
3. `basename "$PWD"` (same pattern as `/feature`)
4. If none match a known profile: "Operator not recognized. Run
   `/pqc --operator=<name> --scan` in the operator directory to analyze."

## Workflow

1. Parse arguments and determine operator + invocation mode
2. If `--status`: dispatch agent in status-report mode
3. If `--scan`: dispatch agent in scan mode for the target operator
4. If ticket key: look up in agent profiles, check blocked/closed status,
   report and stop if not actionable
5. Dispatch the PQC agent:

   ```text
   Agent(
     subagent_type="openstack-k8s-agent-tools:pqc:pqc",
     description="PQC compliance expert for <operator>",
     prompt="Implement PQC compliance changes.
       Mode: <plan|execute|scan|status>
       Operator: <operator-name>
       Ticket: <ticket-key> (if provided)
       Target repo: <repo-url from operator profile>
       Validation: go build ./..., go test ./..., make test"
   )
   ```

6. Present the plan for approval
7. If `--execute`: proceed with implementation

## Prerequisites

- Go 1.24+ (for PQC key exchange support and validation)
- gh CLI (for GitHub PR submission)
- GitHub authentication (`gh auth login`)

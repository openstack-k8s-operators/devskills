---
name: horizon-pqc
description: "PQC compliance workflow for horizon-operator (TLS 1.3, kRSA blocking)"
argument-hint: "<OSPRH-TICKET-KEY> [--execute] [--status]"
user-invocable: true
allowed-tools: ["Bash", "Read", "Write", "Edit", "Grep", "Glob",
                "WebFetch", "Agent", "TaskCreate", "TaskUpdate"]
context: fork
---

# /horizon-pqc -- PQC Compliance for horizon-operator

Post-Quantum Cryptography compliance workflow for
[horizon-operator](https://github.com/openstack-k8s-operators/horizon-operator).
Implements TLS 1.3 enforcement and kRSA cipher blocking.

## Usage

- `/horizon-pqc OSPRH-28889` -- Plan PQC changes for specific ticket
- `/horizon-pqc OSPRH-28889 --execute` -- Plan and execute immediately
- `/horizon-pqc --status` -- Show compliance status for all PQC stories
- `/horizon-pqc` -- Show usage and valid tickets

## Ticket Routing

| Ticket       | PR   | Description                              |
|--------------|------|------------------------------------------|
| OSPRH-28889  | #1   | TLS 1.3 MinVersion in cmd/main.go        |
| OSPRH-28891  | #2   | Apache SSL hardening (SSLCipherSuite)    |
| OSPRH-28892  | #2   | Apache SSL hardening (SSLProtocol)       |
| OSPRH-27427  | Both | Parent epic -- both PRs                 |

### Blocked Tickets

**OSPRH-28890**: Blocked on Nova team (OSPRH-27628). jsencrypt RSA password
decryption depends on Nova's os-server-password API.

Three closure paths:

- A: Nova deprecates RSA password storage -> Horizon removes "Retrieve Password" UI
- B: Nova adds PQC -> Horizon adds multi-algorithm decryption
- C: Accept risk -> Document HNDL exposure (low -- VM admin passwords are transient)

### Closed Tickets

**OSPRH-28888**: Already closed. cert-manager PQC is handled upstream; no change needed.

## Status Report

When `--status` is passed, display this compliance table:

```
PQC Compliance Status -- OSPRH-27427
=======================================================

Story          | Status          | Action
-------------- | --------------- | ------
OSPRH-28888    | CLOSED          | No action (cert-manager upstream)
OSPRH-28889    | Ready           | PS-1 / PR #1: cmd/main.go TLS 1.3
OSPRH-28890    | BLOCKED (Nova)  | Waiting on OSPRH-27628
OSPRH-28891    | Ready           | PS-2 / PR #2: ssl.conf SSLCipherSuite
OSPRH-28892    | Ready           | PS-2 / PR #2: ssl.conf SSLProtocol (combined)

Actionable PRs: 2 (closing 3 stories)
Blocked: 1 (OSPRH-28890 -- Nova team dependency)
Already closed: 1 (OSPRH-28888)
```

## Workflow

1. Parse ticket key and route to PR mapping
2. If ticket is blocked or closed, report status and stop
3. Dispatch the PQC agent:

   ```text
   Agent(
     subagent_type="openstack-k8s-agent-tools:horizon-pqc:horizon-pqc",
     description="PQC compliance expert for horizon-operator",
     prompt="Implement PQC compliance changes for horizon-operator.
       Ticket: <ticket-key>
       PR: <pr-number>
       Target repo: https://github.com/openstack-k8s-operators/horizon-operator (main)
       Validation: go build ./..., go test ./..., make test"
   )
   ```

4. Present the plan for approval
5. If `--execute`: proceed with implementation

## Prerequisites

- Go 1.24+ (for validation and PQC key exchange support)
- gh CLI (for GitHub PR submission)
- GitHub authentication (`gh auth login`)

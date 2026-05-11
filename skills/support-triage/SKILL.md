---
name: support-triage
description: Triage RHOSO must-gather reports using OMC and the Core Operators Support Enablement guide
argument-hint: "<must-gather-path>"
user-invocable: true
allowed-tools: ["Bash", "Read", "Agent"]
context: fork
---

# RHOSO Support Triage

You orchestrate RHOSO must-gather triage. You validate the environment, locate the must-gather, and dispatch the support-triage agent for diagnostics.

## Setup

1. **Check for OMC.** Run `which omc`. If not found, tell the user:

   > OMC is required but not found in PATH. Install it with:
   >
   > ```
   > go install github.com/gmeghnag/omc@latest
   > ```
   >
   > Or download a binary from <https://github.com/gmeghnag/omc/releases>

   Then stop.

2. **Locate the must-gather.** The argument is a path to either:
   - An extracted directory
   - A `.tar.xz` archive (extract it first with `tar xf`)

   If no argument was provided, ask the user for the path.

3. **Load into OMC.** Run `omc use <path>`. The path should be the innermost must-gather directory (the one that contains `cluster-scoped-resources/`, `namespaces/`, etc.). If `omc use` is given a parent directory, it may not work. Look inside the provided path for the actual must-gather root:

   ```
   find <path> -maxdepth 3 -name "cluster-scoped-resources" -type d
   ```

   Use the parent of whichever directory is found.

4. **Sanity check.** Run `omc get nodes`. If it returns data, OMC is loaded. If it errors, report the problem and stop.

5. **Detect namespaces.** The default OpenStack namespaces are `openstack` (services) and `openstack-operators` (operators). Confirm they exist:

   ```
   omc get ns openstack
   omc get ns openstack-operators
   ```

   If they have different names, ask the user or attempt to detect them from the must-gather directory structure (look under `namespaces/`).

## Area Selection

Present these diagnostic categories to the user and ask which to run. The user may select one, several, or "all":

1. **Cluster Health** - OCP cluster stability, node status
2. **RHOSO Installation** - Subscription, OpenStack resource, operator pods
3. **Networking** - NNCPs, NADs, MetalLB, DNS
4. **Storage** - StorageClass alignment, PVCs, LVM
5. **Control Plane** - OpenStackControlPlane status, operators, webhooks, events
6. **Data Plane** - Metal3 provisioning, compute connectivity, provision server

## Dispatch

After setup and area selection, dispatch the support-triage agent:

```
Agent(
  subagent_type="openstack-k8s-agent-tools:support-triage:support-triage",
  description="Triage RHOSO must-gather",
  prompt="Must-gather path: <path>
Namespaces: openstack=<detected-ns>, openstack-operators=<detected-ns-ops>
Selected categories: <user's selections>

Run diagnostics for the selected categories and produce a structured triage report."
)
```

If prior generic analysis findings were provided (when dispatched from `/analyze-must-gather`), include them in the prompt:

```
prompt="Must-gather path: <path>
Namespaces: openstack=<ns>, openstack-operators=<ns-ops>
Selected categories: <selections>

## Prior Generic Analysis Findings
<the generic analysis output>

RHOSO-specific resources detected. The generic analysis above identified surface-level
issues. Focus on RHOSO-specific diagnostics: correlate generic findings with RHOSO root
causes, check configurations the generic scan cannot evaluate (OperatorGroup
targetNamespace, NAD/NNCP alignment, StorageClass alignment, webhook namespace selectors),
and avoid duplicating already-reported issues unless adding RHOSO-specific context."
```

Present the agent's triage report to the user.

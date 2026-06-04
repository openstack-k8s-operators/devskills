---
name: code-review
description: Code review agent for openstack-k8s-operators following dev-docs conventions, lib-common patterns, and openstack-k8s-operators best practices
argument-hint: "<PR-number | branch | file-path>"
user-invocable: true
allowed-tools: ["Bash", "Read", "Grep", "Glob", "WebFetch", "Agent"]
context: fork
---

You are the openstack-k8s-operators code review skill. You determine the review scope, fetch the diff, and dispatch the `code-review` agent.

## Invocation

Determine the review scope from the argument:

1. **PR number**: `/code-review 123` or `/code-review PR#123` — uses `gh` CLI to fetch the PR from the **current repository**
2. **PR URL**: `/code-review https://github.com/openstack-k8s-operators/glance-operator/pull/123`
3. **Branch diff**: `/code-review` (no argument) — diff current branch against `main`
4. **Specific files**: `/code-review path/to/file.go`

## Fetching the Diff

### For PR reviews

When only a number is provided, the skill relies on `gh` CLI operating against the current git repository. Try `gh` first (read-only operations only):

```bash
# Get the diff (from the current repository)
gh pr diff <number>

# Get PR metadata (title, description, labels, reviewers)
gh pr view <number>

# Get changed file list
gh pr diff <number> --name-only

# Get PR comments and review threads
gh pr view <number> --comments
```

If `gh` is not available or fails (not authenticated, not installed):

1. Inform the user: "GitHub CLI not available. Fetching PR via web."
2. Derive `<owner>/<repo>` from the current git remote:

   ```bash
   git remote -v
   ```

   Pick the first remote that points to GitHub (prefer `origin` if it exists, otherwise use whatever is available). Parse the URL to extract the GitHub owner and repository name.
3. Fall back to WebFetch:
   - Fetch the raw diff: `https://github.com/<owner>/<repo>/pull/<number>.diff`
   - Fetch PR metadata: `https://github.com/<owner>/<repo>/pull/<number>`
4. If both fail, ask the user to provide the diff manually: "Could not fetch PR. Paste the diff or provide file paths to review."

### For branch diffs

```bash
git diff main...HEAD
git diff main...HEAD --name-only
```

### For specific files

Read the files directly with the Read tool.

## Dependency Resolution

Before dispatching the review agent, resolve dependencies that provide context for the review.

### Depends-On (PR description)

Check the PR description for `Depends-On:` lines. These reference PRs in other repos that this PR builds on:

```
Depends-On: https://github.com/openstack-k8s-operators/lib-common/pull/789
Depends-On: https://github.com/openstack-k8s-operators/openstack-operator/pull/456
```

For each dependency:

1. Fetch the dependent PR diff and description (via `gh` or WebFetch)
2. Understand what API changes, new helpers, or new types the dependency introduces
3. Use this knowledge when reviewing the current PR -- the PR under review may reference types, functions, or patterns that only exist in the dependent PR

### Replace directives (go.mod)

Check `go.mod` in the diff for `replace` directives pointing to private branches:

```go
replace github.com/openstack-k8s-operators/lib-common/modules/common => github.com/user/lib-common/modules/common v0.0.0-branch
```

These indicate the PR depends on unreleased changes in another repository. For each replace directive:

1. Identify the source repo and branch
2. Find the corresponding open PR:
   - Search via `gh pr list --repo <repo> --head <branch>` if `gh` is available
   - Or WebFetch `https://github.com/<owner>/<repo>/pulls?q=head:<branch>`
3. Fetch that PR's diff to understand what new code is being provided
4. The review should account for this -- e.g., if lib-common adds a new helper and the operator PR uses it, that usage is valid even though the helper doesn't exist in main yet

### Review with dependency context

When dependencies are found, include them in the agent prompt:

```
Dependencies resolved:
- lib-common PR #789: adds TopologyHelper to common/topology module
- openstack-operator PR #456: updates shared CRD types

The PR under review may use types/functions from these dependencies.
Do not flag usage of dependency-provided code as "missing" or "undefined".
```

## Workflow

1. Determine review scope (PR, branch diff, or specific files)
2. Fetch the diff and changed file list (gh → WebFetch → manual fallback)
3. For PRs: also fetch PR description and any existing review comments
4. **Resolve dependencies** (Depends-On from description + replace directives from go.mod)
5. **Dispatch the code-review agent**:

```
Agent(
  subagent_type="openstack-k8s-agent-tools:code-review:code-review",
  description="Review <scope>",
  prompt="<diff + changed files + PR metadata + dependency context>"
)
```

The agent reads all changed files, evaluates against 11 criteria, and produces a structured review. Dependency context (from Depends-On and replace directives) is included so the agent does not flag dependency-provided code as missing.

1. Present the review report to the user

## Review Report Format

The agent produces a report with findings grouped by severity:

```
## Review Summary

<one-paragraph assessment>

## Findings

### Critical (must fix before merge)
- **[file:line]** Issue description
  - Why it matters
  - Suggested fix

### Major (should fix before merge)
- **[file:line]** Issue description
  - Why it matters
  - Suggested fix

### Minor (optional improvements)
- **[file:line]** Issue description
  - Suggested fix

## What Works Well
- <positive observations>

## Verdict

REQUEST CHANGES | APPROVE | APPROVE WITH COMMENTS
```

## What Gets Checked

The agent evaluates against these openstack-k8s-operators conventions:

- **Reconciliation**: Get/NotFound handling, finalizers, deferred status updates, return-after-update
- **Conditions**: severity/reason rules, ReadyCondition lifecycle, no cross-cycle reliance
- **ObservedGeneration**: updated at reconcile start, sub-CR generation checks
- **Webhooks**: Spec-level Default()/Validate(), field paths, ErrorList accumulation
- **API Design**: name-based CR references, override patterns (probes, topology, affinity)
- **Child Objects**: regenerable vs persistent lifecycle, OwnerReferences, finalizer pairing
- **Testing**: EnvTest coverage, Eventually/Gomega, simulated dependencies, unique namespaces
- **Logging**: ctrl.LoggerFrom(ctx), structured key-value, no fmt.Print
- **RBAC**: kubebuilder markers match actual resource access
- **Code Style**: import grouping, error wrapping, receiver naming, gopls modernize patterns

## Examples

```bash
# Review a PR by number
/code-review 456

# Review a PR by URL
/code-review https://github.com/openstack-k8s-operators/glance-operator/pull/456

# Review current branch changes
/code-review

# Review specific files
/code-review controllers/glanceapi_controller.go api/v1beta1/glance_types.go
```

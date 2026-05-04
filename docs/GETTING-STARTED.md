# openstack-k8s-operators Operator Skills - Quick Reference

## debug-operator

```bash
/debug-operator                           # Auto-run workflow
/debug-operator focus-test "pattern"      # Focused testing
```

**Runs**: pre-commit -> manifests -> generate -> lint -> build -> test

---

## test-operator

```bash
/test-operator quick           # fmt+vet+tidy (~10s)
/test-operator standard        # +lint+test (~2-5min)
/test-operator full            # +security (~5-10min)
/test-operator focus "pattern" # Focused tests
/test-operator security        # gosec+govulncheck
/test-operator coverage        # Coverage report
/test-operator fix             # Auto-fix issues
```

**Make targets**:

```bash
make fmt vet test golangci operator-lint
make test GINKGO_ARGS="--focus 'pattern'"
```

---

## code-style

```bash
/code-style                    # Analyze code
```

**Detects**: old syntax, missing error wrapping, controller anti-patterns

---

## analyze-logs

```bash
/analyze-logs                  # Interactive
```

**Finds**: errors (API/RBAC/runtime), performance issues, OpenStack problems

---

## explain-flow

```bash
/explain-flow                  # Parse current dir
```

**Extracts**: reconcile functions, flow steps, error handling, CRDs

---

## code-review

```bash
/code-review                   # Review current branch diff
/code-review PR#123            # Review a PR
/code-review file.go           # Review specific file
```

**Checks**: reconciliation, conditions, webhooks, RBAC, testing, API design

---

## feature

```bash
/feature                       # Interactive planning
/feature OSPRH-2345            # Plan from Jira ticket
/feature spec.md               # Plan from spec file
```

**Provides**: architecture analysis, design suggestions, task breakdown

---

## Common Workflows

**Development loop**:

```bash
/test-operator quick -> /debug-operator focus-test "..." -> iterate
```

**Pre-commit**:

```bash
/test-operator standard && /code-style
```

**Pre-PR**:

```bash
/debug-operator && /test-operator full && /code-review
```

**Debugging**:

```bash
kubectl logs pod > log.txt
/analyze-logs -> /explain-flow -> /debug-operator
```

---

## Installation

```bash
make install-claude
```

---

## Tips

- Use `quick` for fast feedback during development
- Focused tests speed up iteration
- Auto-fix before manual fixes

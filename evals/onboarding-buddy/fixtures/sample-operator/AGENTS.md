# sample-operator — agent guidelines

Minimal fixture operator used by devskills evals. Not a real OpenStack deployment.

## Build and test

| Command | Purpose |
|---------|---------|
| `make generate` | Regenerate DeepCopy in `api/` |
| `make manifests` | Regenerate CRDs and RBAC in `config/` |
| `make test` | envtest + Ginkgo functional tests |
| `make run` | Run the manager locally against kubeconfig |

## Custom resources

| CR | OpenStack role | Controller | API type |
|----|----------------|------------|----------|
| `Nova` | Compute (VM lifecycle) | `internal/controller/nova/` | `api/nova/v1beta1/nova_types.go` |
| `GlanceAPI` | Image service API | `internal/controller/glance/` | `api/glance/v1beta1/glanceapi_types.go` |

## Directory layout

| Path | Purpose |
|------|---------|
| `api/` | CRD Go types and kubebuilder markers |
| `cmd/main.go` | Manager setup, scheme registration, controller wiring |
| `config/` | CRDs, RBAC, kustomize overlays (generated + hand-written) |
| `internal/controller/` | Reconcilers — one subdirectory per service CR |
| `internal/nova/`, `internal/glance/` | Resource builders (Deployments, Services, Secrets) |
| `templates/` | Config templates rendered into Secrets |
| `doc/design.md` | Operator-specific naming and architecture decisions |

## Conventions

- CR types live under `api/<service>/v1beta1/`.
- Reconcilers live under `internal/controller/<service>/`.
- Resource builders live under `internal/<service>/`.
- Cross-operator conventions: [dev-docs](https://github.com/openstack-k8s-operators/dev-docs).

## Reconcile request path

1. User applies a CR (e.g. `Nova`).
2. API server stores it; controller-runtime watch enqueues the object.
3. `NovaReconciler` in `internal/controller/nova/` runs `Reconcile()`.
4. Reconciler builds child resources via helpers in `internal/nova/`.
5. Status and conditions are updated on the CR.

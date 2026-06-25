# sample-operator design notes

Operator-specific choices for this fixture (not cross-operator conventions).

## Naming

- Service CRs use the OpenStack service name (`Nova`, `GlanceAPI`).
- `GlanceAPI` (not `Glance`) denotes the API tier CR pattern used across operators.

## Layout

- Reconcile logic lives in `internal/controller/<service>/`.
- Resource builders live in `internal/<service>/` — kept separate from reconcilers.

For project-wide conventions (conditions, webhooks, envtest), see
[dev-docs](https://github.com/openstack-k8s-operators/dev-docs).

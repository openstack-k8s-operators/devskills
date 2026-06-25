package nova

import (
	"context"

	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
)

// NovaReconciler reconciles a Nova object.
type NovaReconciler struct {
	client.Client
}

// Reconcile handles Nova create/update/delete events.
func (r *NovaReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	// Fixture stub — evals only need a recognizable reconciler entry point.
	return ctrl.Result{}, nil
}

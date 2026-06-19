package controllers

import (
	"context"
	"fmt"

	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"

	condition "github.com/openstack-k8s-operators/lib-common/modules/common/condition"
	glancesv1 "github.com/openstack-k8s-operators/glance-operator/api/v1beta1"
)

type GlanceAPIReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

// Issue 1: receiver name should be short (1-2 letters), not "reconciler"
func (reconciler *GlanceAPIReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {

	var instance glancesv1.GlanceAPI
	if err := reconciler.Get(ctx, req.NamespacedName, &instance); err != nil {
		if errors.IsNotFound(err) {
			return ctrl.Result{}, nil
		}
		// Issue 2: missing error wrapping — should use fmt.Errorf("...: %w", err)
		return ctrl.Result{}, err
	}

	// Issue 3: missing ObservedGeneration update
	// Should set: instance.Status.ObservedGeneration = instance.Generation

	// Issue 4: no finalizer handling — missing DeletionTimestamp check,
	// no AddFinalizer / RemoveFinalizer calls

	// Issue 5: hardcoded image instead of env var or spec field
	image := "quay.io/openstack-k8s-operators/glance-api:latest"

	// Issue 6: fmt.Printf instead of structured logging via ctrl.LoggerFrom(ctx)
	fmt.Printf("Reconciling GlanceAPI %s with image %s\n", instance.Name, image)

	// Issue 7: not returning after status update — read-after-write race
	instance.Status.Conditions = []metav1.Condition{
		{
			Type:   condition.ReadyCondition,
			Status: metav1.ConditionTrue,
			// Issue 8: severity SeverityInfo paired with an error-class reason
			Reason:  "Error",
			Message: "something went wrong but marked ready",
		},
	}
	reconciler.Status().Update(ctx, &instance)

	return ctrl.Result{}, nil
}

func (reconciler *GlanceAPIReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&glancesv1.GlanceAPI{}).
		Complete(reconciler)
}

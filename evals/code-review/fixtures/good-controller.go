package controllers

import (
	"context"
	"fmt"

	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"

	condition "github.com/openstack-k8s-operators/lib-common/modules/common/condition"
	glancesv1 "github.com/openstack-k8s-operators/glance-operator/api/v1beta1"
)

const glanceFinalizerName = "glance.openstack.org/glanceapi"

type GlanceAPIReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

func (r *GlanceAPIReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := ctrl.LoggerFrom(ctx)

	var instance glancesv1.GlanceAPI
	if err := r.Get(ctx, req.NamespacedName, &instance); err != nil {
		if errors.IsNotFound(err) {
			log.Info("GlanceAPI resource not found, likely deleted")
			return ctrl.Result{}, nil
		}
		return ctrl.Result{}, fmt.Errorf("failed to get GlanceAPI: %w", err)
	}

	if instance.DeletionTimestamp != nil {
		if controllerutil.ContainsFinalizer(&instance, glanceFinalizerName) {
			if err := r.cleanup(ctx, &instance); err != nil {
				return ctrl.Result{}, fmt.Errorf("failed to clean up GlanceAPI resources: %w", err)
			}
			controllerutil.RemoveFinalizer(&instance, glanceFinalizerName)
			if err := r.Update(ctx, &instance); err != nil {
				return ctrl.Result{}, fmt.Errorf("failed to remove finalizer: %w", err)
			}
		}
		return ctrl.Result{}, nil
	}

	if !controllerutil.ContainsFinalizer(&instance, glanceFinalizerName) {
		controllerutil.AddFinalizer(&instance, glanceFinalizerName)
		if err := r.Update(ctx, &instance); err != nil {
			return ctrl.Result{}, fmt.Errorf("failed to add finalizer: %w", err)
		}
		return ctrl.Result{}, nil
	}

	instance.Status.ObservedGeneration = instance.Generation

	log.Info("reconciling GlanceAPI", "image", instance.Spec.ContainerImage)

	condition.SetStatusCondition(&instance.Status.Conditions, metav1.Condition{
		Type:    condition.ReadyCondition,
		Status:  metav1.ConditionTrue,
		Reason:  condition.ReadyMessage,
		Message: "GlanceAPI reconciled successfully",
	})

	if err := r.Status().Update(ctx, &instance); err != nil {
		return ctrl.Result{}, fmt.Errorf("failed to update status: %w", err)
	}
	return ctrl.Result{}, nil
}

func (r *GlanceAPIReconciler) cleanup(ctx context.Context, instance *glancesv1.GlanceAPI) error {
	log := ctrl.LoggerFrom(ctx)
	log.Info("cleaning up GlanceAPI resources", "instance", instance.Name)
	return nil
}

func (r *GlanceAPIReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&glancesv1.GlanceAPI{}).
		Complete(r)
}

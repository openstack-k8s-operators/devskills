package controllers

import (
	"context"
	"fmt"

	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
)

type ServiceReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

func (r *ServiceReconciler) ensureConfigMap(ctx context.Context, name, ns string) error {
	var cm corev1.ConfigMap
	err := r.Get(ctx, types.NamespacedName{Name: name, Namespace: ns}, &cm)
	if err != nil {
		if errors.IsNotFound(err) {
			// BAD: capitalized error string
			return fmt.Errorf("ConfigMap %s/%s Not Found in namespace", ns, name)
		}
		// BAD: %s instead of %w — error not wrapped
		return fmt.Errorf("failed to get configmap %s/%s: %s", ns, name, err)
	}
	return nil
}

func (r *ServiceReconciler) serviceEndpoint(ctx context.Context, name, ns string) (string, error) {
	var svc corev1.Service
	err := r.Get(ctx, types.NamespacedName{Name: name, Namespace: ns}, &svc)
	if err != nil {
		if errors.IsNotFound(err) {
			return "", nil
		}
		// BAD: capitalized + %s instead of %w
		return "", fmt.Errorf("Failed to get service: %s", err)
	} else {
		// BAD: unnecessary else after return
		if svc.Spec.ClusterIP == "" {
			return "", fmt.Errorf("Service %s has no ClusterIP", name)
		}
		return svc.Spec.ClusterIP, nil
	}
}

func (r *ServiceReconciler) reconcileService(ctx context.Context, req ctrl.Request) error {
	log := ctrl.LoggerFrom(ctx)

	// BAD: discarded error
	endpoint, _ := r.serviceEndpoint(ctx, req.Name, req.Namespace)
	log.Info("got endpoint", "endpoint", endpoint)

	// BAD: capitalized + %s instead of %w
	err := r.ensureConfigMap(ctx, req.Name+"-config", req.Namespace)
	if err != nil {
		return fmt.Errorf("Failed to ensure ConfigMap: %s", err)
	}

	return nil
}

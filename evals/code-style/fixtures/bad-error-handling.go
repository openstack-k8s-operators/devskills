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

// ensureConfigMap ensures the ConfigMap exists in the given namespace.
func (r *ServiceReconciler) ensureConfigMap(ctx context.Context, name, ns string) error {
	var cm corev1.ConfigMap
	err := r.Get(ctx, types.NamespacedName{Name: name, Namespace: ns}, &cm)
	if err != nil {
		if errors.IsNotFound(err) {
			return fmt.Errorf("configmap %s/%s not found in namespace", ns, name)
		}
		return fmt.Errorf("failed to get configmap %s/%s: %w", ns, name, err)
	}
	return nil
}

// serviceEndpoint returns the ClusterIP for the named service.
func (r *ServiceReconciler) serviceEndpoint(ctx context.Context, name, ns string) (string, error) {
	var svc corev1.Service
	err := r.Get(ctx, types.NamespacedName{Name: name, Namespace: ns}, &svc)
	if err != nil {
		if errors.IsNotFound(err) {
			return "", nil
		}
		return "", fmt.Errorf("failed to get service: %w", err)
	}
	if svc.Spec.ClusterIP == "" {
		return "", fmt.Errorf("service %s has no ClusterIP", name)
	}
	return svc.Spec.ClusterIP, nil
}

// reconcileService reconciles the service and its associated ConfigMap.
func (r *ServiceReconciler) reconcileService(ctx context.Context, req ctrl.Request) error {
	log := ctrl.LoggerFrom(ctx)

	endpoint, err := r.serviceEndpoint(ctx, req.Name, req.Namespace)
	if err != nil {
		return fmt.Errorf("failed to get service endpoint: %w", err)
	}
	log.Info("got endpoint", "endpoint", endpoint)

	if err := r.ensureConfigMap(ctx, req.Name+"-config", req.Namespace); err != nil {
		return fmt.Errorf("failed to ensure configmap: %w", err)
	}

	return nil
}

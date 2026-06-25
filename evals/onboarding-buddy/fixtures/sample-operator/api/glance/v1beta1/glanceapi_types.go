package v1beta1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// GlanceAPISpec defines the desired state of GlanceAPI.
type GlanceAPISpec struct {
	// Secret is the name of the config Secret.
	Secret string `json:"secret,omitempty"`
}

// GlanceAPIStatus defines the observed state of GlanceAPI.
type GlanceAPIStatus struct {
	Ready bool `json:"ready,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// GlanceAPI is the Schema for the glanceapis API.
type GlanceAPI struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   GlanceAPISpec   `json:"spec,omitempty"`
	Status GlanceAPIStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true
type GlanceAPIList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []GlanceAPI `json:"items"`
}

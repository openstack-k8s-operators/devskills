package v1beta1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// NovaSpec defines the desired state of Nova.
type NovaSpec struct {
	// Replicas is the number of nova-conductor pods.
	Replicas int32 `json:"replicas,omitempty"`
}

// NovaStatus defines the observed state of Nova.
type NovaStatus struct {
	// Ready indicates the Nova service is operational.
	Ready bool `json:"ready,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// Nova is the Schema for the novas API.
type Nova struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   NovaSpec   `json:"spec,omitempty"`
	Status NovaStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true
type NovaList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []Nova `json:"items"`
}

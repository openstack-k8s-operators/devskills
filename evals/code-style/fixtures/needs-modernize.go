package controllers

import (
	"strings"
)

// Old-style variable declarations — modernized to zero-value / short form
var names []string
var endpoints []string
var labelMap = make(map[string]string)

// Owner returns the owner annotation value.
func Owner(annotations map[string]string) string {
	return annotations["owner"]
}

// AppName returns the application name.
func AppName() string {
	return "glance"
}

// BuildLabels builds a label map for the given names and namespace.
func BuildLabels(names []string, namespace string) map[string]string {
	labels := make(map[string]string)
	labels["app"] = "glance"
	labels["namespace"] = namespace

	for _, name := range names {
		if name != "" {
			labels[name] = "true"
		}
	}

	return labels
}

// FormatEndpoints joins endpoints with a comma separator.
func FormatEndpoints(endpoints []string) string {
	return strings.Join(endpoints, ",")
}

// AllNames returns all non-empty names from the input slice.
func AllNames(names []string) []string {
	var out []string
	for _, name := range names {
		if name != "" {
			out = append(out, name)
		}
	}
	return out
}

// BuildConfig builds a single-entry config map from the given key and value.
func BuildConfig(key, value string) map[string]string {
	return map[string]string{key: value}
}

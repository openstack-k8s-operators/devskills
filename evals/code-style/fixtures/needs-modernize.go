package controllers

import (
	"fmt"
)

// BAD: old-style variable declarations — should use short form
var names []string = []string{}
var endpoints []string = []string{}
var labelMap map[string]string = map[string]string{}

// BAD: Get prefix — should be just Owner
func GetOwner(annotations map[string]string) string {
	return annotations["owner"]
}

// BAD: Get prefix — should be just AppName
func GetAppName() string {
	return "glance"
}

func BuildLabels(names []string, namespace string) map[string]string {
	// BAD: old-style map declaration
	var labels map[string]string = map[string]string{}
	labels["app"] = "glance"
	labels["namespace"] = namespace

	// BAD: C-style loop instead of range
	for i := 0; i < len(names); i++ {
		if names[i] != "" {
			labels[names[i]] = "true"
		}
	}

	return labels
}

// BAD: string concatenation in loop instead of strings.Join
func FormatEndpoints(endpoints []string) string {
	var result string = ""
	for i := 0; i < len(endpoints); i++ {
		if i > 0 {
			result = result + ","
		}
		result = result + endpoints[i]
	}
	return result
}

// BAD: C-style loop instead of range
func AllNames(names []string) []string {
	var out []string = []string{}
	for i := 0; i < len(names); i++ {
		if names[i] != "" {
			out = append(out, names[i])
		}
	}
	return out
}

// BAD: unnecessary Sprintf for simple key-value
func BuildConfig(key, value string) map[string]string {
	var config map[string]string = map[string]string{}
	config[fmt.Sprintf("%s", key)] = fmt.Sprintf("%s", value)
	return config
}

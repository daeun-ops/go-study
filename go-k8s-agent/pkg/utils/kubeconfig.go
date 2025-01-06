package utils

import (
	"fmt"
	"os"
)

func GetKubeconfigPath() string {
	path := os.Getenv("KUBECONFIG")
	if path == "" {
		path = fmt.Sprintf("%s/.kube/config", os.Getenv("HOME"))
	}
	return path
}

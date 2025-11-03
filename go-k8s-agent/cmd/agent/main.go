package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/daeun-ops/go-study/go-k8s-agent/pkg/collector"
	"github.com/daeun-ops/go-study/go-k8s-agent/pkg/exporter"
)

func main() {
	fmt.Println("🚀 Starting mini Kubernetes Agent")

	go func() {
		for {
			collector.CollectClusterMetrics()
			time.Sleep(10 * time.Second)
		}
	}()

	http.Handle("/metrics", exporter.Handler())
	log.Println("Prometheus exporter listening on :8080/metrics")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

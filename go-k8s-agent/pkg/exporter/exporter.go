package exporter

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	NodeGauge = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "k8s_nodes_total",
		Help: "Total number of nodes in cluster",
	})
	PodGauge = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "k8s_pods_total",
		Help: "Total number of pods running",
	})
)

func init() {
	prometheus.MustRegister(NodeGauge, PodGauge)
}

func Handler() http.Handler {
	return promhttp.Handler()
}

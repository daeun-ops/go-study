package collector

import (
	"fmt"
	"math/rand"
)

func CollectClusterMetrics() {
	nodes := rand.Intn(5) + 1
	pods := rand.Intn(50) + 10
	cpu := rand.Float64() * 80
	mem := rand.Float64() * 70

	fmt.Printf("[Collector] Nodes=%d Pods=%d CPU=%.2f%% Mem=%.2f%%\n", nodes, pods, cpu, mem)
}

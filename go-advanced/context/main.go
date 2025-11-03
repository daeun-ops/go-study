package main
import (
	"context"
	"fmt"
	"time"
)
func task(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			fmt.Println("context cancelled")
			return
		default:
			fmt.Println("working...")
			time.Sleep(500 * time.Millisecond)
		}
	}
}
func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	task(ctx)
}

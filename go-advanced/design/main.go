package main
import "fmt"
type Logger interface { Log(msg string) }
type ConsoleLogger struct{}
func (ConsoleLogger) Log(msg string) { fmt.Println("[INFO]", msg) }
func main() {
	var l Logger = ConsoleLogger{}
	l.Log("service started")
}

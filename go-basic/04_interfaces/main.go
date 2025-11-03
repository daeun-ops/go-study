package main
import "fmt"
type Notifier interface { Notify() }
type Email struct { Address string }
func (e Email) Notify() { fmt.Println("Sending email to:", e.Address) }
func main() {
	var n Notifier = Email{Address: "hello@example.com"}
	n.Notify()
}

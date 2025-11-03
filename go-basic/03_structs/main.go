package main
import "fmt"
type User struct { Name string; Age int }
func main() {
	u := User{Name: "Sophie", Age: 24}
	fmt.Printf("User: %+v\n", u)
}

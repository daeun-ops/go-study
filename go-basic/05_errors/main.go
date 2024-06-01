package main
import (
	"errors"
	"fmt"
)
func divide(a, b float64) (float64, error) {
	if b == 0 { return 0, errors.New("cannot divide by zero") }
	return a / b, nil
}
func main() {
	res, err := divide(10, 2)
	if err != nil { fmt.Println("Error:", err); return }
	fmt.Println("Result:", res)
}

package main
import (
	"fmt"
	"reflect"
)
func main() {
	x := 42
	v := reflect.ValueOf(x)
	fmt.Println("Type:", v.Type(), "Kind:", v.Kind(), "Value:", v.Int())
}

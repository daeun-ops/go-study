// Generic stack demonstrates type parameter usage.
package main
type Stack[T any] struct{ s []T }
func (st *Stack[T]) Push(v T){ st.s=append(st.s,v) }
func (st *Stack[T]) Pop()(T,bool){ n:=len(st.s); if n==0{var z T; return z,false}; v:=st.s[n-1]; st.s=st.s[:n-1]; return v,true }

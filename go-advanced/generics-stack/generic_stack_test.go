package main
import "testing"
func TestStack(t *testing.T){ var s Stack[int]; s.Push(7); v,ok:=s.Pop(); if !ok||v!=7 { t.Fatal("stack failed") } }

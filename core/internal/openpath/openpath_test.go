package openpath

import (
	"path/filepath"
	"testing"
)

func TestResolveFileURI(t *testing.T) {
	got, err := Resolve("file:///etc/hosts")
	if err != nil {
		t.Fatal(err)
	}
	if got != "/etc/hosts" {
		t.Fatalf("got %q", got)
	}
}

func TestResolveEncodedURI(t *testing.T) {
	got, err := Resolve("file:///tmp/my%20dir")
	if err != nil {
		t.Fatal(err)
	}
	if got != "/tmp/my dir" {
		t.Fatalf("got %q", got)
	}
}

func TestResolveAbs(t *testing.T) {
	got, err := Resolve("/etc")
	if err != nil {
		t.Fatal(err)
	}
	if got != "/etc" {
		t.Fatalf("got %q", got)
	}
}

func TestResolveRelative(t *testing.T) {
	got, err := Resolve(".")
	if err != nil {
		t.Fatal(err)
	}
	abs, err := filepath.Abs(".")
	if err != nil {
		t.Fatal(err)
	}
	if got != abs {
		t.Fatalf("got %q want %q", got, abs)
	}
}

func TestResolveEmpty(t *testing.T) {
	got, err := Resolve("  ")
	if err != nil {
		t.Fatal(err)
	}
	if got != "" {
		t.Fatalf("got %q", got)
	}
}

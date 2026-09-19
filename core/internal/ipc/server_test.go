package ipc

import "testing"

func TestPublishUIPendingThenFlush(t *testing.T) {
	s := New()
	s.publishUI(map[string]any{"action": "browse", "path": "/etc"})
	s.mu.Lock()
	if s.pending["action"] != "browse" {
		t.Fatalf("pending = %#v", s.pending)
	}
	s.mu.Unlock()

	// No live subscribers: onSubscribe still consumes the stash.
	s.onSubscribe([]string{"ui"}, nil)
	s.mu.Lock()
	if s.pending != nil {
		t.Fatalf("pending still set: %#v", s.pending)
	}
	s.mu.Unlock()
}

func TestCurrentPathAfterBrowseStore(t *testing.T) {
	s := New()
	s.mu.Lock()
	s.path = "/tmp"
	s.mu.Unlock()
	if s.CurrentPath() != "/tmp" {
		t.Fatalf("got %q", s.CurrentPath())
	}
}

package ipc

import (
	"context"
	"strings"
	"sync"

	dankipc "github.com/AvengeMedia/dankgo/ipc"
	"github.com/AvengeMedia/dankgo/ipc/params"
)

const appName = "dankfm"

type Server struct {
	inner *dankipc.Server
	bus   *dankipc.EventBus

	Version string
	Commit  string
	Built   string

	mu      sync.Mutex
	path    string
	pending map[string]any
}

func New() *Server {
	bus := dankipc.NewEventBus()
	s := &Server{bus: bus}
	mux := dankipc.NewMux()
	mux.HandlePrefix("ui.", s.handleUI)
	s.inner = dankipc.NewServer(dankipc.Config{
		AppName:                appName,
		APIVersion:             1,
		Capabilities:           []string{"ui"},
		DefaultSubscribeTopics: []string{"ui"},
		Bus:                    bus,
		OnSubscribe:            s.onSubscribe,
	}, mux.ServeIPC)
	return s
}

func (s *Server) Listen() error { return s.inner.Listen() }

func (s *Server) Serve(ctx context.Context) error { return s.inner.Serve(ctx) }

func (s *Server) SocketPath() string { return s.inner.SocketPath() }

func (s *Server) Close() {
	if s.inner != nil {
		_ = s.inner.Close()
	}
}

func (s *Server) CurrentPath() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.path
}

func (s *Server) onSubscribe(topics []string, _ *dankipc.Subscriber) {
	want := false
	for _, t := range topics {
		if t == "ui" {
			want = true
			break
		}
	}
	if !want {
		return
	}
	s.mu.Lock()
	pending := s.pending
	s.pending = nil
	s.mu.Unlock()
	if pending != nil {
		s.bus.Publish("ui", pending)
	}
}

func (s *Server) publishUI(payload map[string]any) {
	if s.bus.HasSubscriber("ui") {
		s.bus.Publish("ui", payload)
		return
	}
	s.mu.Lock()
	s.pending = payload
	s.mu.Unlock()
}

func (s *Server) handleUI(_ context.Context, w *dankipc.ConnWriter, req dankipc.Request, _ *dankipc.Subscriber) {
	switch req.Method {
	case "ui.show", "ui.hide", "ui.toggle":
		s.publishUI(map[string]any{"action": strings.TrimPrefix(req.Method, "ui.")})
		dankipc.Respond(w, req.ID, map[string]any{"ok": true})
	case "ui.browse":
		path := strings.TrimSpace(params.StringOpt(req.Params, "path", ""))
		if path == "" {
			dankipc.RespondError(w, req.ID, "ui.browse requires a path")
			return
		}
		s.mu.Lock()
		s.path = path
		s.mu.Unlock()
		s.publishUI(map[string]any{"action": "browse", "path": path})
		dankipc.Respond(w, req.ID, map[string]any{"ok": true})
	case "ui.report":
		path := strings.TrimSpace(params.StringOpt(req.Params, "path", ""))
		s.mu.Lock()
		s.path = path
		s.mu.Unlock()
		dankipc.Respond(w, req.ID, map[string]any{"ok": true})
	case "ui.status":
		dankipc.Respond(w, req.ID, map[string]any{
			"path":    s.CurrentPath(),
			"version": s.Version,
			"commit":  s.Commit,
			"built":   s.Built,
		})
	case "ui.version":
		dankipc.Respond(w, req.ID, map[string]any{
			"version": s.Version,
			"commit":  s.Commit,
			"built":   s.Built,
		})
	default:
		dankipc.RespondError(w, req.ID, "unknown ui method: "+req.Method)
	}
}

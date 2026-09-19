package main

import (
	"context"

	"github.com/AvengeMedia/dankgo/shellapp"
	appipc "github.com/kmf/dankfm/core/internal/ipc"
	"github.com/kmf/dankfm/core/internal/shellembed"
)

var shellApp = shellapp.New(shellapp.Config{
	ID:         "dankfm",
	QSAppID:    "com.danklinux.dankfm",
	Version:    Version,
	Embedded:   embeddedShell{},
	Boot:       bootBackend,
	ShowMethod: "ui.show",
	ExtraEnv: func(string) []string {
		return []string{
			"DANKFM_VERSION=" + Version,
			"DANKFM_COMMIT=" + Commit,
			"DANKFM_BUILD_TIME=" + BuildTime,
		}
	},
})

func bootBackend(ctx context.Context) (shellapp.Backend, error) {
	srv := appipc.New()
	srv.Version = Version
	srv.Commit = Commit
	srv.Built = BuildTime
	if err := srv.Listen(); err != nil {
		return nil, err
	}
	go func() {
		_ = srv.Serve(ctx)
	}()
	return srv, nil
}

type embeddedShell struct{}

func (embeddedShell) Available() bool { return shellembed.Available() }

func (embeddedShell) Extract(baseDir string) (string, error) { return shellembed.Extract(baseDir) }

func (embeddedShell) Prune(baseDir, keep string) { shellembed.Prune(baseDir, keep) }

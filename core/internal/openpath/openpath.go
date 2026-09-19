// Package openpath turns a CLI argument (path or file:// URI) into a
// filesystem path.
package openpath

import (
	"net/url"
	"path/filepath"
	"strings"
)

func Resolve(raw string) (string, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return "", nil
	}
	if strings.HasPrefix(raw, "file://") {
		u, err := url.Parse(raw)
		if err != nil {
			return "", err
		}
		return filepath.Clean(u.Path), nil
	}
	if filepath.IsAbs(raw) {
		return filepath.Clean(raw), nil
	}
	abs, err := filepath.Abs(raw)
	if err != nil {
		return "", err
	}
	return abs, nil
}

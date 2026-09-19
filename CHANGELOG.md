# Changelog

All notable changes to DankFM are recorded here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Preview pane for text and code with syntax highlighting. Modified git files show the diff in the pane; `.diff` / `.patch` files use the same colouring as the diff dialog.
- Settings window matching Dank Calendar (toolbar gear, sidebar, About page with version, links, and daemon status). `Ctrl+,` opens it.
- Version numbering from the `VERSION` file (`0.1.0`); untagged builds are `0.1.0+gitN.hash`.
- Copy, cut and paste on the selection (`Ctrl+C` / `Ctrl+X` / `Ctrl+V`, and the context menu).
- Paste goes into the directory on screen. A name that already exists becomes `name (copy)`, then `name (copy 2)`; nothing is overwritten.
- Copy out of the trash is allowed. Cut and paste into the trash are refused. A successful cut clears the clipboard.

## [0.1.0] - 2026-09-19

First release. Port of the DankFiles prototype into a Dank Calendar-shaped app: a Go `dfm` binary that embeds the Quickshell UI and works from any directory.

### Added

- Miller-column, list and icon-grid views.
- `dfm` CLI (`show`, `toggle`, `open`, `run`, `kill`, `status`) over a unix-socket daemon. Closing the window hides it.
- Embedded UI (`go:embed`); `dfm -c` / `DANKFM_SHELL_DIR` for a live tree.
- Desktop entry (`inode/directory`), AppStream metainfo, and Makefile install of the binary (no QML share tree).
- Path editor (`Ctrl+L`), places sidebar, preview pane, bookmarks.
- XDG trash with restore, permanent delete, empty, and `Ctrl+Z` undo.
- Multi-select (`Ctrl+click`, `Shift+click`, `Ctrl+A`).
- Open with, rename, new folder, terminal here.
- Git status, stage/unstage, and a diff dialog.
- Theme follows `~/.cache/DankMaterialShell/dms-colors.json`.

[Unreleased]: https://github.com/kmf/dankfm/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/kmf/dankfm/releases/tag/v0.1.0

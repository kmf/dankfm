# DankFM

A miller-column file manager for the Dank Linux suite, built with
[Quickshell](https://quickshell.org/) and [Go](https://go.dev/).

The `dfm` binary embeds the UI. A copy dropped into any directory runs without
the source tree. Closing the window hides it; `dfm kill` quits.

## Requirements

Building requires Go 1.26 or newer, GNU Make, Git, and `tar`. Clone the
repository with its Dank QML Common submodule:

```sh
git clone --recurse-submodules https://github.com/kmf/dankfm.git
cd dankfm
```

If the repository was cloned without submodules, initialize them separately:

```sh
git submodule update --init --recursive
```

Running DankFM requires Quickshell 0.3.1+, Qt 6 QML with
`Qt.labs.folderlistmodel`, `gio`, `xdg-utils`, `gtk-launch`, and Git.
`ffmpegthumbnailer` is optional and enables video thumbnails.

## Build

Build the standalone binary with the QML interface embedded:

```sh
make
./core/bin/dfm
```

The output is `core/bin/dfm`. It does not need the source tree at runtime.
Use `make clean` to remove generated build files.

For development, build the faster non-embedded binary and run it against the
live `quickshell/` tree:

```sh
make run
```

Before submitting changes, run the available checks:

```sh
make test       # Go tests
make vet        # Go static analysis
make check      # load the QML configuration and fail on warnings
```

`make check` requires the `qs` executable and GNU `timeout`.

## Install

After building, install the binary, desktop entry, icon, and AppStream metadata:

```sh
sudo make install
```

The default prefix is `/usr/local`. Override it when needed, or use `DESTDIR`
for package staging:

```sh
make PREFIX="$HOME/.local" install
make DESTDIR=/tmp/dankfm-package PREFIX=/usr install
```

Remove files installed under the same prefix with:

```sh
sudo make uninstall
```

```
dfm                 # show, or launch
dfm /etc            # browse a path
dfm toggle          # compositor keybind
dfm kill            # quit
dfm run -d --hidden # daemon, window hidden
```

`dfm -c <dir>` or `DANKFM_SHELL_DIR` uses a live `shell.qml` tree instead of
the embed.

The UI follows `~/.cache/DankMaterialShell/dms-colors.json` when present.

Copy, cut and paste act on the selection (`Ctrl+C` / `Ctrl+X` / `Ctrl+V`, and the context menu). Paste goes into the directory on screen. A name that already exists gets ` (copy)` rather than being overwritten. Cut/paste out of the trash is restore; paste into the trash is refused.

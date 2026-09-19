# DankFM

A miller-column file manager for the Dank Linux suite, built with
[Quickshell](https://quickshell.org/) and [Go](https://go.dev/).

The `dfm` binary embeds the UI. A copy dropped into any directory runs without
the source tree. Closing the window hides it; `dfm kill` quits.

```
git clone --recurse-submodules git@github.com:kmf/dankfm.git
cd dankfm
make            # builds dfm with the UI embedded
make run        # development: dfm run -c ./quickshell
make check      # QML config loads without warnings
make test       # Go tests
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

Requires Quickshell 0.3.1+, Qt 6 QML (`Qt.labs.folderlistmodel`), `gio`,
`xdg-utils`, `gtk-launch`, and `git`. Optional:
`ffmpegthumbnailer` for video thumbnails.

The UI follows `~/.cache/DankMaterialShell/dms-colors.json` when present.

Copy, cut and paste act on the selection (`Ctrl+C` / `Ctrl+X` / `Ctrl+V`, and the context menu). Paste goes into the directory on screen. A name that already exists gets ` (copy)` rather than being overwritten. Cut/paste out of the trash is restore; paste into the trash is refused.

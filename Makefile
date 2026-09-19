# Root Makefile for DankFM.
# Orchestrates the Go core build and local installation of the
# binary (with the quickshell UI embedded), icon, desktop entry,
# and AppStream metainfo.

BINARY_NAME=dfm
CORE_DIR=core
BUILD_DIR=$(CORE_DIR)/bin
PREFIX ?= /usr/local
DESTDIR ?=
INSTALL_DIR=$(PREFIX)/bin
DATA_DIR=$(PREFIX)/share
ICON_DIR=$(DATA_DIR)/icons/hicolor/scalable/apps
APPLICATIONS_DIR=$(DATA_DIR)/applications
METAINFO_DIR=$(DATA_DIR)/metainfo

SHELL_DIR=quickshell
ASSETS_DIR=assets
DESKTOP_ID=com.danklinux.dankfm

export PATH := $(HOME)/.local/go/bin:$(PATH)

.PHONY: all build dev run clean test fmt vet check install install-bin install-icon install-desktop install-metainfo uninstall uninstall-bin uninstall-icon uninstall-desktop help

all: build

build:
	@$(MAKE) -C $(CORE_DIR) build

dev:
	@$(MAKE) -C $(CORE_DIR) dev

run: dev
	@$(BUILD_DIR)/$(BINARY_NAME) run -c $(CURDIR)/$(SHELL_DIR)

clean:
	@$(MAKE) -C $(CORE_DIR) clean

test:
	@$(MAKE) -C $(CORE_DIR) test

fmt:
	@$(MAKE) -C $(CORE_DIR) fmt

vet:
	@$(MAKE) -C $(CORE_DIR) vet

## check - load the QML config and fail on any warning. The portal's
## "Could not register app ID" is expected until the desktop entry is installed.
check:
	@out=$$(timeout 10 qs -p $(CURDIR)/$(SHELL_DIR) 2>&1 \
	  | grep -vE "INFO|CachingImage|thumbnails" \
	  | grep -v "Could not register app ID" || true); \
	if [ -n "$$out" ]; then echo "$$out"; exit 1; fi; \
	echo "config loads clean"

install-bin:
	@test -f $(BUILD_DIR)/$(BINARY_NAME) || { echo "$(BUILD_DIR)/$(BINARY_NAME) not found; run 'make' first"; exit 1; }
	@install -D -m 755 $(BUILD_DIR)/$(BINARY_NAME) $(DESTDIR)$(INSTALL_DIR)/$(BINARY_NAME)

install-icon:
	@echo "Installing icon..."
	@install -D -m 644 $(ASSETS_DIR)/$(DESKTOP_ID).svg $(DESTDIR)$(ICON_DIR)/$(DESKTOP_ID).svg
	@test -n "$(DESTDIR)" || gtk-update-icon-cache -q $(DATA_DIR)/icons/hicolor 2>/dev/null || true

install-desktop:
	@echo "Installing desktop entry..."
	@install -D -m 644 $(ASSETS_DIR)/$(DESKTOP_ID).desktop $(DESTDIR)$(APPLICATIONS_DIR)/$(DESKTOP_ID).desktop
	@test -n "$(DESTDIR)" || update-desktop-database -q $(APPLICATIONS_DIR) 2>/dev/null || true

install-metainfo:
	@echo "Installing AppStream metainfo..."
	@install -D -m 644 $(ASSETS_DIR)/$(DESKTOP_ID).metainfo.xml $(DESTDIR)$(METAINFO_DIR)/$(DESKTOP_ID).metainfo.xml

install: install-bin install-icon install-desktop install-metainfo
	@echo ""
	@echo "Installation complete."
	@echo "Launch with 'dfm' or the DankFM desktop entry."

uninstall-bin:
	@rm -f $(DESTDIR)$(INSTALL_DIR)/$(BINARY_NAME)

uninstall-icon:
	@rm -f $(DESTDIR)$(ICON_DIR)/$(DESKTOP_ID).svg
	@test -n "$(DESTDIR)" || gtk-update-icon-cache -q $(DATA_DIR)/icons/hicolor 2>/dev/null || true

uninstall-desktop:
	@rm -f $(DESTDIR)$(APPLICATIONS_DIR)/$(DESKTOP_ID).desktop
	@test -n "$(DESTDIR)" || update-desktop-database -q $(APPLICATIONS_DIR) 2>/dev/null || true

uninstall-metainfo:
	@rm -f $(DESTDIR)$(METAINFO_DIR)/$(DESKTOP_ID).metainfo.xml

uninstall: uninstall-desktop uninstall-icon uninstall-metainfo uninstall-bin
	@echo "Uninstallation complete."

help:
	@echo "Build:"
	@echo "  build     - Build the dfm binary (UI embedded)"
	@echo "  dev       - Fast development build (no embed)"
	@echo "  run       - Build and run against ./quickshell"
	@echo "  check     - Load the QML config and fail on warnings"
	@echo "  test/fmt/vet"
	@echo ""
	@echo "Install (PREFIX=$(PREFIX)):"
	@echo "  install   - Binary (UI embedded), icon, desktop entry, metainfo"
	@echo "  uninstall - Remove everything"

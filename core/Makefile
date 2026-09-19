BINARY_NAME=dfm
SOURCE_DIR=cmd/dfm
BUILD_DIR=bin
SHELL_SRC=../quickshell
EMBED_DIR=internal/shellembed/dist
COMPLETIONS_DIR=$(BUILD_DIR)/completions
PREFIX ?= /usr/local
INSTALL_DIR=$(PREFIX)/bin
BASHCOMP_DIR=$(PREFIX)/share/bash-completion/completions
ZSHCOMP_DIR=$(PREFIX)/share/zsh/site-functions
FISHCOMP_DIR=$(PREFIX)/share/fish/vendor_completions.d

GO ?= go
export PATH := $(HOME)/.local/go/bin:$(PATH)

FILE_VERSION=$(shell test -f ../VERSION && tr -d '[:space:]' < ../VERSION || echo 0.1.0)
EXACT_TAG=$(shell git describe --tags --exact-match 2>/dev/null | sed 's/^v//')
COMMIT_COUNT=$(shell git rev-list --count HEAD 2>/dev/null || echo "0")
COMMIT_HASH=$(shell git rev-parse --short=8 HEAD 2>/dev/null || echo "unknown")
VERSION?=$(if $(EXACT_TAG),$(EXACT_TAG),$(FILE_VERSION)+git$(COMMIT_COUNT).$(COMMIT_HASH))
BUILD_TIME?=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
COMMIT?=$(COMMIT_HASH)

BUILD_LDFLAGS=-ldflags='-s -w -X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME) -X main.Commit=$(COMMIT)'

.PHONY: all build dev sync-shell completions install install-completions uninstall clean test fmt vet help

all: build

# Copy the quickshell UI into the embed dir (gitignored) so tagged builds
# can bake it into the binary. tar -h dereferences the DankCommon submodule
# symlink; go:embed rejects symlinks. .qmlls.ini is excluded at copy time.
sync-shell:
	@test -f $(SHELL_SRC)/DankCommon/Widgets/DankIcon.qml || { echo "DankCommon missing: run git submodule update --init"; exit 1; }
	@rm -rf $(EMBED_DIR)
	@mkdir -p $(EMBED_DIR)
	@tar -C $(SHELL_SRC) --exclude=.qmlls.ini -chf - . | tar -C $(EMBED_DIR) -xf -

build: sync-shell
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 $(GO) build -tags withshell $(BUILD_LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) ./$(SOURCE_DIR)
	@echo "Build complete: $(BUILD_DIR)/$(BINARY_NAME)"

dev:
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 $(GO) build -o $(BUILD_DIR)/$(BINARY_NAME) ./$(SOURCE_DIR)

completions: build
	@mkdir -p $(COMPLETIONS_DIR)
	@$(BUILD_DIR)/$(BINARY_NAME) completion bash > $(COMPLETIONS_DIR)/$(BINARY_NAME)
	@$(BUILD_DIR)/$(BINARY_NAME) completion zsh > $(COMPLETIONS_DIR)/_$(BINARY_NAME)
	@$(BUILD_DIR)/$(BINARY_NAME) completion fish > $(COMPLETIONS_DIR)/$(BINARY_NAME).fish
	@echo "Completions written to $(COMPLETIONS_DIR)"

install: install-completions
	@install -D -m 755 $(BUILD_DIR)/$(BINARY_NAME) $(DESTDIR)$(INSTALL_DIR)/$(BINARY_NAME)

install-completions:
	@test -d $(COMPLETIONS_DIR) || $(MAKE) completions
	@install -D -m 644 $(COMPLETIONS_DIR)/$(BINARY_NAME) $(DESTDIR)$(BASHCOMP_DIR)/$(BINARY_NAME)
	@install -D -m 644 $(COMPLETIONS_DIR)/_$(BINARY_NAME) $(DESTDIR)$(ZSHCOMP_DIR)/_$(BINARY_NAME)
	@install -D -m 644 $(COMPLETIONS_DIR)/$(BINARY_NAME).fish $(DESTDIR)$(FISHCOMP_DIR)/$(BINARY_NAME).fish

uninstall:
	@rm -f $(DESTDIR)$(INSTALL_DIR)/$(BINARY_NAME)
	@rm -f $(DESTDIR)$(BASHCOMP_DIR)/$(BINARY_NAME)
	@rm -f $(DESTDIR)$(ZSHCOMP_DIR)/_$(BINARY_NAME)
	@rm -f $(DESTDIR)$(FISHCOMP_DIR)/$(BINARY_NAME).fish

clean:
	@rm -rf $(BUILD_DIR) $(EMBED_DIR)

test:
	CGO_ENABLED=0 $(GO) test ./...

fmt:
	$(GO) fmt ./...

vet:
	CGO_ENABLED=0 $(GO) vet ./...

help:
	@echo "Targets: build dev sync-shell completions install clean test fmt vet"

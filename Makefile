# [TAU]: For macOS, Accomdate default PREFIX=/usr/local
# IMHO, this should be the default PREFIX for all OS (not only macOS).
# For the moment, keeping backwards compatibility with the previous version of this 'Makefile'
# which means, by default, PREFIX=/usr    -- for all Operating Systems except macOS (Darwin).
os=$(shell uname -s)
ifeq ($(os),Darwin)
    PREFIX   ?=/usr/local
else
    PREFIX   ?=/usr
endif

# installation paths
INSTALL_DIR=$(DESTDIR)$(PREFIX)/bin
MOUNT_INSTALL_DIR=$(DESTDIR)$(PREFIX)/sbin
MAN_INSTALL_DIR=$(DESTDIR)$(PREFIX)/share/man/man1
ZSH_COMP_INSTALL_DIR=$(DESTDIR)$(PREFIX)/share/zsh/site-functions

# other vars
VER=$(shell grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+" src/github.com/oniony/TMSU/version/version.go)
SHELL=/bin/sh
ARCH=$(shell uname -m)
DIST_NAME=tmsu-$(ARCH)-$(VER)
DIST_DIR=$(DIST_NAME)
DIST_FILE=$(DIST_NAME).tgz
GODEPS=\
  golang.org/x/crypto/blake2b \
  github.com/mattn/go-sqlite3 \
  github.com/hanwen/go-fuse

export GOPATH ?= $(PREFIX)/lib/go:$(PREFIX)/share/gocode
export GOPATH := $(CURDIR):$(GOPATH)

all: setup clean compile dist test

.PHONY: setup
setup: setup-begin $(GODEPS)

.PHONY: setup-begin
setup-begin:
	@echo
	@echo "INSTALLING GOLANG PKG DEPENDENCIES (as needed)"
	@echo

.PHONY: $(GODEPS)
$(GODEPS): 
	go list "$@" 1>/dev/null 2>&1 || go get -v "$@"

clean:
	@echo
	@echo "CLEANING"
	@echo
	go clean github.com/oniony/TMSU
	rm -Rf bin
	rm -Rf "$(DIST_DIR)"
	rm -f  "$(DIST_FILE)"

compile:
	@echo
	@echo "COMPILING"
	@echo
	@mkdir -p bin
	go build -o bin/tmsu github.com/oniony/TMSU

test: unit-test integration-test

unit-test: compile
	@echo
	@echo "RUNNING UNIT TESTS"
	@echo
	go test github.com/oniony/TMSU/...

integration-test: compile
	@echo
	@echo "RUNNING INTEGRATION TESTS"
	@echo
	@cd tests && ./runall

dist: compile
	@echo
	@echo "PACKAGING DISTRIBUTABLE"
	@echo
	@mkdir -p "$(DIST_DIR)"
	@mkdir -p "$(DIST_DIR)/bin"
	@mkdir -p "$(DIST_DIR)/man"
	@mkdir -p "$(DIST_DIR)/misc/zsh"
	cp -R bin     "$(DIST_DIR)/"
	cp README.md  "$(DIST_DIR)/"
	cp COPYING.md "$(DIST_DIR)/"
	cp misc/bin/* "$(DIST_DIR)/bin/"
	gzip -fc misc/man/tmsu.1 >"$(DIST_DIR)/man/tmsu.1.gz"
	cp misc/zsh/_tmsu "$(DIST_DIR)/misc/zsh/"
	tar czf "$(DIST_FILE)" "$(DIST_DIR)"

install: 
	@echo
	@echo "INSTALLING"
	@echo
	mkdir -p "$(INSTALL_DIR)"
	mkdir -p "$(MOUNT_INSTALL_DIR)"
	mkdir -p "$(MAN_INSTALL_DIR)"
	mkdir -p "$(ZSH_COMP_INSTALL_DIR)"
	cp bin/tmsu "$(INSTALL_DIR)/"
	cp misc/bin/mount.tmsu "$(MOUNT_INSTALL_DIR)/"
	cp misc/bin/tmsu-* "$(INSTALL_DIR)/"
	gzip -fc misc/man/tmsu.1 >"$(MAN_INSTALL_DIR)/tmsu.1.gz"
	cp misc/zsh/_tmsu "$(ZSH_COMP_INSTALL_DIR)/"

uninstall:
	@echo "UNINSTALLING"
	rm "$(INSTALL_DIR)/tmsu"
	rm "$(MOUNT_INSTALL_DIR)/mount.tmsu"
	rm "$(INSTALL_DIR)/tmsu-*"
	rm "$(MAN_INSTALL_DIR)/tmsu.1.gz"
	rm "$(ZSH_COMP_INSTALL_DIR)/_tmsu"

.PHONY: all clean compile test unit-test integration-test dist install uninstall

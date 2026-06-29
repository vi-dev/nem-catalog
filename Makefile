PKG  ?=
NEM  ?= unstable
OS   ?= linux,macos
ARCH ?=

ARCH_FLAG := $(if $(ARCH),--arch $(ARCH),)

.PHONY: test-pkg test-changed

## Test one or more packages: make test-pkg PKG="kubectl helm" [NEM=v0.7.0] [OS=linux] [ARCH=amd64]
test-pkg:
	@test -n "$(PKG)" || { echo 'usage: make test-pkg PKG=<name>... [NEM=unstable|vX] [OS=linux,macos] [ARCH=arm64|amd64]'; exit 2; }
	@scripts/test-pkg.sh $(PKG) --nem "$(NEM)" --os "$(OS)" $(ARCH_FLAG)

## Test packages changed vs origin/main: make test-changed [NEM=v0.7.0]
test-changed:
	@scripts/test-pkg.sh --changed --nem "$(NEM)" --os "$(OS)" $(ARCH_FLAG)

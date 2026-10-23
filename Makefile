# NetPoll Makefile — standalone build and tarball creation

VERSION  := 4.0
BINARY   := netpoll
TARBALL  := netpoll-$(VERSION)-standalone.tar.gz
STAGEDIR := netpoll-$(VERSION)

.PHONY: all build tarball clean help

all: build tarball

help:
	@echo "NetPoll standalone build targets:"
	@echo "  make build     Compile netpoll into a standalone executable (./netpoll)"
	@echo "  make tarball   Create deployment tarball ($(TARBALL))"
	@echo "  make all       Build binary and tarball (default)"
	@echo "  make clean     Remove build artifacts"

build:
	./scripts/build-standalone.sh --compile

tarball: build
	./scripts/build-standalone.sh --package

clean:
	rm -f $(BINARY) $(TARBALL)
	rm -rf $(STAGEDIR)

# Build settings and tests for nmap. The build rules are in ../common.mk.

include versions.mk

TOOL := nmap
DEPS_LIBS := libssl.a libpcap.a
BUILD_ARGS := \
	--build-arg NMAP_VERSION=$(NMAP_VERSION) \
	--build-arg NMAP_SOURCE_URL=$(NMAP_SOURCE_URL) \
	--build-arg NMAP_SOURCE_SHA256=$(NMAP_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing nmap binary for $(ARCH)"
	@# Check if binary exists and is executable
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/nmap || \
		(echo "ERROR: nmap binary not found or not executable" && exit 1)
	@echo "✓ nmap binary exists"
	@test -f $(TOOL_OUT_DIR)/$(ARCH)/nmap-services || \
		(echo "ERROR: nmap-services not found" && exit 1)
	@echo "✓ nmap-services exists"
	@# Check static linking
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/nmap
	@# Run nmap --version in a container (zero libraries present, proves static linking)
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/nmap:/nmap:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /nmap --version 2>&1) && \
		echo "$$OUTPUT" | grep -qi "Nmap version" || \
		(echo "ERROR: nmap --version failed: $$OUTPUT" && exit 1)
	@echo "✓ nmap --version works"
	@# Run nmap -h in a container
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/nmap:/nmap:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /nmap -h 2>&1) && \
		echo "$$OUTPUT" | grep -qi "usage" || \
		(echo "ERROR: nmap -h failed" && exit 1)
	@echo "✓ nmap -h works"
	@# Run a real TCP-connect scan against loopback with a listener on the
	@# scanned port, so the result is a deterministic "open" rather than
	@# depending on nothing else listening in the container. -sT needs no
	@# raw sockets/root, unlike -sS. nmap-services ships next to the binary;
	@# nmap auto-discovers data files next to its own executable, so the
	@# service name (http) should resolve without --datadir/NMAPDIR. All
	@# three checks share one shell invocation so $$OUTPUT stays in scope.
	@OUTPUT=$$($(DOCKER) run --rm --network none --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/nmap:/nmap:ro \
		-v $(TOOL_OUT_DIR)/$(ARCH)/nmap-services:/nmap-services:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
		/bin/sh -c 'nc -l -p 80 >/dev/null 2>&1 & sleep 1; /nmap -sT -p 80 127.0.0.1' 2>&1) && \
		(echo "$$OUTPUT" | grep -qi "Nmap done" || \
			(echo "ERROR: nmap -sT scan failed: $$OUTPUT" && exit 1)) && \
		(echo "$$OUTPUT" | grep -qi "80/tcp *open" || \
			(echo "ERROR: nmap did not report the listening port as open: $$OUTPUT" && exit 1)) && \
		(echo "$$OUTPUT" | grep -qi "80/tcp *open *http" || \
			(echo "ERROR: nmap-services service-name lookup failed: $$OUTPUT" && exit 1))
	@echo "✓ nmap -sT TCP connect scan works and reports open ports"
	@echo "✓ nmap-services next to the binary is used automatically"
	@echo "==> All nmap tests passed"

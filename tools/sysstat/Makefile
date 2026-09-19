# Build settings and tests for sysstat. The build rules are in ../common.mk.

include versions.mk

TOOL := sysstat
INPUTS := inject-sadc-sibling.sh sadc-sibling.inc
BUILD_ARGS := \
	--build-arg SYSSTAT_VERSION=$(SYSSTAT_VERSION) \
	--build-arg SYSSTAT_SOURCE_URL=$(SYSSTAT_SOURCE_URL) \
	--build-arg SYSSTAT_SOURCE_SHA256=$(SYSSTAT_SOURCE_SHA256)

include ../common.mk

test: build
	@echo "==> Testing mpstat binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/mpstat || \
		(echo "ERROR: mpstat binary not found or not executable" && exit 1)
	@echo "✓ mpstat binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/mpstat
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/mpstat:/mpstat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /mpstat -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "sysstat" || \
		(echo "ERROR: mpstat -V failed: $$OUTPUT" && exit 1)
	@echo "✓ mpstat -V works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/mpstat:/mpstat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /mpstat 1 1 2>&1) && \
		echo "$$OUTPUT" | grep -qi "CPU" || \
		(echo "ERROR: mpstat 1 1 failed: $$OUTPUT" && exit 1)
	@echo "✓ mpstat 1 1 works (live /proc read)"
	@echo "==> Testing iostat binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/iostat || \
		(echo "ERROR: iostat binary not found or not executable" && exit 1)
	@echo "✓ iostat binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/iostat
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/iostat:/iostat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /iostat -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "sysstat" || \
		(echo "ERROR: iostat -V failed: $$OUTPUT" && exit 1)
	@echo "✓ iostat -V works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/iostat:/iostat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /iostat 2>&1) && \
		echo "$$OUTPUT" | grep -qi "Device" || \
		(echo "ERROR: iostat failed: $$OUTPUT" && exit 1)
	@echo "✓ iostat works (live /proc read)"
	@echo "==> Testing pidstat binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/pidstat || \
		(echo "ERROR: pidstat binary not found or not executable" && exit 1)
	@echo "✓ pidstat binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/pidstat
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/pidstat:/pidstat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /pidstat -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "sysstat" || \
		(echo "ERROR: pidstat -V failed: $$OUTPUT" && exit 1)
	@echo "✓ pidstat -V works"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/pidstat:/pidstat:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /pidstat 1 1 2>&1) && \
		echo "$$OUTPUT" | grep -qi "Command" || \
		(echo "ERROR: pidstat 1 1 failed: $$OUTPUT" && exit 1)
	@echo "✓ pidstat 1 1 works (live /proc read)"
	@echo "==> Testing sadc binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/sadc || \
		(echo "ERROR: sadc binary not found or not executable" && exit 1)
	@echo "✓ sadc binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/sadc
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/sadc:/sadc:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /sadc -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "sysstat" || \
		(echo "ERROR: sadc -V failed: $$OUTPUT" && exit 1)
	@echo "✓ sadc -V works"
	@echo "==> Testing sar binary for $(ARCH)"
	@test -x $(TOOL_OUT_DIR)/$(ARCH)/sar || \
		(echo "ERROR: sar binary not found or not executable" && exit 1)
	@echo "✓ sar binary exists"
	@$(CURDIR)/../../scripts/assert-static-elf.sh $(TOOL_OUT_DIR)/$(ARCH)/sar
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/sar:/sar:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /sar -V 2>&1) && \
		echo "$$OUTPUT" | grep -qi "sysstat" || \
		(echo "ERROR: sar -V failed: $$OUTPUT" && exit 1)
	@echo "✓ sar -V works"
	@echo "==> Testing sar live sampling finds sibling sadc (zero-library alpine)"
	@if OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/sar:/sar:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /sar 1 1 2>&1); then \
		echo "ERROR: sar 1 1 succeeded without sadc: $$OUTPUT" && exit 1; \
	else \
		echo "$$OUTPUT" | grep -qi "data collector\|sadc" || \
			(echo "ERROR: sar without sadc failed for an unexpected reason: $$OUTPUT" && exit 1); \
	fi
	@echo "✓ sar 1 1 without sadc fails (does not pick up a host collector)"
	@OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
		-v $(TOOL_OUT_DIR)/$(ARCH)/sar:/sar:ro \
		-v $(TOOL_OUT_DIR)/$(ARCH)/sadc:/sadc:ro \
		alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) /sar 1 1 2>&1) && \
		echo "$$OUTPUT" | grep -qi "CPU\|%idle\|%user" || \
		(echo "ERROR: sar 1 1 with sibling sadc failed: $$OUTPUT" && exit 1)
	@echo "✓ sar 1 1 works (live sampling via sibling sadc)"
	@for setup in \
		"refuses|chown 1234 /t/sadc|owned by another user" \
		"refuses|chmod o+w /t/sadc|world-writable" \
		"refuses|chmod g+w /t/sadc|group-writable while sar is not" \
		"refuses|chmod g+w /t/sar /t/sadc && chgrp 1234 /t/sadc|writable by a group that cannot write sar" \
		"runs|chmod g+w /t/sar /t/sadc|group-writable like sar (umask 002)"; do \
		expect=$${setup%%|*}; rest=$${setup#*|}; prep=$${rest%%|*}; label=$${rest#*|}; \
		rc=0; OUTPUT=$$($(DOCKER) run --rm --platform $(PLATFORM_$(ARCH)) \
			-v $(TOOL_OUT_DIR)/$(ARCH)/sar:/in/sar:ro \
			-v $(TOOL_OUT_DIR)/$(ARCH)/sadc:/in/sadc:ro \
			alpine:$(ALPINE_VERSION)@$(ALPINE_DIGEST) \
			sh -c "mkdir /t && cp /in/sar /in/sadc /t/ && chmod 755 /t/sar /t/sadc && $$prep && /t/sar 1 1" 2>&1) || rc=$$?; \
		if [ "$$expect" = runs ]; then \
			[ "$$rc" = 0 ] && echo "$$OUTPUT" | grep -qi "CPU\|%idle\|%user" || \
				{ echo "ERROR: sar did not run a sibling sadc that is $$label: $$OUTPUT"; exit 1; }; \
		else \
			[ "$$rc" != 0 ] || { echo "ERROR: sar ran a sibling sadc that is $$label: $$OUTPUT"; exit 1; }; \
			echo "$$OUTPUT" | grep -qi "data collector\|sadc" || \
				{ echo "ERROR: sar with a sibling sadc that is $$label failed for an unexpected reason: $$OUTPUT"; exit 1; }; \
		fi; \
		echo "✓ sar $$expect a sibling sadc that is $$label"; \
	done
	@echo "==> All sysstat tests passed"

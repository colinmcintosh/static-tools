DNS_TEST_SCRIPTS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
DNS_TEST_SERVER_OUT_DIR := $(OUT_DIR)/test-fixtures/dns/$(ARCH)
DNS_TEST_SERVER := $(DNS_TEST_SERVER_OUT_DIR)/dns-test-server

$(DNS_TEST_SERVER): \
		$(DNS_TEST_SCRIPTS_DIR)/Dockerfile.dns-test-server \
		$(DNS_TEST_SCRIPTS_DIR)/dns-test-server.c
	@mkdir -p $(DNS_TEST_SERVER_OUT_DIR)
	$(BUILDX) build \
		--platform $(PLATFORM_$(ARCH)) \
		--build-arg BUILDER_IMAGE=$(BUILDER_IMAGE) \
		--build-arg BUILDER_DIGEST=$(BUILDER_DIGEST) \
		--output type=local,dest=$(DNS_TEST_SERVER_OUT_DIR) \
		--target export \
		-f $(DNS_TEST_SCRIPTS_DIR)/Dockerfile.dns-test-server \
		$(DNS_TEST_SCRIPTS_DIR)
	@$(DNS_TEST_SCRIPTS_DIR)/assert-static-elf.sh $(DNS_TEST_SERVER)

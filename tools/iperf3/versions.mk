# iperf3 version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# iperf3 source
IPERF3_VERSION := 3.18
IPERF3_SOURCE_URL := https://github.com/esnet/iperf/releases/download/$(IPERF3_VERSION)/iperf-$(IPERF3_VERSION).tar.gz
IPERF3_SOURCE_SHA256 := c0618175514331e766522500e20c94bfb293b4424eb27d7207fb427b88d20bab

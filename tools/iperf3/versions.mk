# iperf3 version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# iperf3 source
IPERF3_VERSION := 3.21
IPERF3_SOURCE_URL := https://github.com/esnet/iperf/releases/download/$(IPERF3_VERSION)/iperf-$(IPERF3_VERSION).tar.gz
IPERF3_SOURCE_SHA256 := 656e4405ebd620121de7ceca3eaf43a88f79ea1b857d041a6a0b1314801acdd8

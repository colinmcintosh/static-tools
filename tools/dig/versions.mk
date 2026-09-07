# dig (BIND) version and checksums
# All versions and checksums should be pinned for reproducibility
# Note: Using BIND 9.16.x (last autoconf-based version) which allows static compilation

include ../../deps/versions.mk

# BIND source (provides dig)
# 9.16.x is the last version using autoconf - newer versions use Meson and don't support static linking
BIND9_VERSION := 9.16.50
BIND9_SOURCE_URL := https://downloads.isc.org/isc/bind9/$(BIND9_VERSION)/bind-$(BIND9_VERSION).tar.xz
BIND9_SOURCE_SHA256 := 816dbaa3c115019f30fcebd9e8ef8f7637f4adde91c79daa099b035255a15795

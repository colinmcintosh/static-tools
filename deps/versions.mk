# Shared static library prefix (built from upstream tarballs).
# Official gcc images are Debian/glibc-only, so the compiler is Alpine's
# musl gcc from a digest-pinned base image plus apk-pinned build-base
# and linux-headers (those two have been stable on 3.21). C libraries
# are NOT installed via apk; they are fetched by URL and verified with SHA256.

ALPINE_VERSION := 3.21
# Multi-arch index digest of alpine:3.21 (currently 3.21.7). Docker
# selects the platform from --platform / TARGETARCH, so one pin covers
# amd64 and arm64 and cannot be paired with the wrong architecture.
# The per-arch names stay so existing Makefiles keep working.
# 3.21 EOL is 2026-11-01; migration to 3.24 is tracked in
# https://github.com/colinmcintosh/static-tools/issues/44
ALPINE_DIGEST := sha256:48b0309ca019d89d40f670aa1bc06e426dc0931948452e8491e3d65087abc07d
ALPINE_DIGEST_AMD64 := $(ALPINE_DIGEST)
ALPINE_DIGEST_ARM64 := $(ALPINE_DIGEST)

# Host tools built into the prefix (perl is required by OpenSSL Configure)
PERL_VERSION := 5.40.2
PERL_URL := https://www.cpan.org/src/5.0/perl-$(PERL_VERSION).tar.gz
PERL_SHA256 := 10d4647cfbb543a7f9ae3e5f6851ec49305232ea7621aed24c7cfbb0bef4b70d

PKG_CONFIG_VERSION := 0.29.2
PKG_CONFIG_URL := https://pkg-config.freedesktop.org/releases/pkg-config-$(PKG_CONFIG_VERSION).tar.gz
PKG_CONFIG_SHA256 := 6fc69c01688c9458a57eb9a1664c9aba372ccda420a02bf4429fe610e7e7d591

# Libraries
ZLIB_VERSION := 1.3.2
ZLIB_URL := https://github.com/madler/zlib/releases/download/v$(ZLIB_VERSION)/zlib-$(ZLIB_VERSION).tar.gz
ZLIB_SHA256 := bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16

# 3.5 is the current LTS branch, supported until 2030-04-08. Do not move to a
# non-LTS branch: 3.4 and 3.6 both go EOL within months.
OPENSSL_VERSION := 3.5.8
OPENSSL_URL := https://github.com/openssl/openssl/releases/download/openssl-$(OPENSSL_VERSION)/openssl-$(OPENSSL_VERSION).tar.gz
OPENSSL_SHA256 := a8f84a39918ec6415ce765d9b429d313ba97b8143169c172e734b9514464f5b2

NGHTTP2_VERSION := 1.69.0
NGHTTP2_URL := https://github.com/nghttp2/nghttp2/releases/download/v$(NGHTTP2_VERSION)/nghttp2-$(NGHTTP2_VERSION).tar.gz
NGHTTP2_SHA256 := c866b7477cbb7512ab6863a685027adbb1bb8da8fc3bab7429ed43d3281d5aa9

NCURSES_VERSION := 6.5
NCURSES_URL := https://ftp.gnu.org/gnu/ncurses/ncurses-$(NCURSES_VERSION).tar.gz
NCURSES_SHA256 := 136d91bc269a9a5785e5f9e980bc76ab57428f604ce3e5a5a90cebc767971cc6

LIBCAP_VERSION := 2.78
LIBCAP_URL := https://git.kernel.org/pub/scm/libs/libcap/libcap.git/snapshot/libcap-$(LIBCAP_VERSION).tar.gz
LIBCAP_SHA256 := 856e742e331bb53176231e1eae3588ab044e5564c811df3138bd2f1c7b953682

LIBUV_VERSION := 1.49.2
LIBUV_URL := https://dist.libuv.org/dist/v$(LIBUV_VERSION)/libuv-v$(LIBUV_VERSION).tar.gz
LIBUV_SHA256 := 8c10706bd2cf129045c42b94799a92df9aaa75d05f07e99cf083507239bae5a8

URCU_VERSION := 0.14.1
URCU_URL := https://lttng.org/files/urcu/userspace-rcu-$(URCU_VERSION).tar.bz2
URCU_SHA256 := 231acb13dc6ec023e836a0f0666f6aab47dc621ecb1d2cd9d9c22f922678abc0

JEMALLOC_VERSION := 5.3.0
JEMALLOC_URL := https://github.com/jemalloc/jemalloc/releases/download/$(JEMALLOC_VERSION)/jemalloc-$(JEMALLOC_VERSION).tar.bz2
JEMALLOC_SHA256 := 2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa

LIBPCAP_VERSION := 1.10.7
LIBPCAP_URL := https://www.tcpdump.org/release/libpcap-$(LIBPCAP_VERSION).tar.gz
LIBPCAP_SHA256 := 0b394ac90dbc0a9838ff97468e05c9c9a3e873dec2514cd58db65d859d296e31

XXHASH_VERSION := 0.8.3
XXHASH_URL := https://github.com/Cyan4973/xxHash/archive/refs/tags/v$(XXHASH_VERSION).tar.gz
XXHASH_SHA256 := aae608dfe8213dfd05d909a57718ef82f30722c392344583d3f39050c7f29a80

# 1.5.7 is the latest GitHub release; 1.6.0 is not published as a tarball.
ZSTD_VERSION := 1.5.7
ZSTD_URL := https://github.com/facebook/zstd/releases/download/v$(ZSTD_VERSION)/zstd-$(ZSTD_VERSION).tar.gz
ZSTD_SHA256 := eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3

LZ4_VERSION := 1.10.0
LZ4_URL := https://github.com/lz4/lz4/releases/download/v$(LZ4_VERSION)/lz4-$(LZ4_VERSION).tar.gz
LZ4_SHA256 := 537512904744b35e232912055ccf8ec66d768639ff3abe5788d90d792ec5f48b

PREFIX := /opt/st

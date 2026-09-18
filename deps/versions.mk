# Shared static library prefix (built from upstream tarballs).
# The compiler, static libc, autotools, and headers come from the
# digest-pinned builder image (builder/Dockerfile). C libraries are
# NOT installed via apk; they are fetched by URL and verified with SHA256.
#
# Rebuild the builder with .github/workflows/builder.yml, then copy the
# printed BUILDER_DIGEST here and refresh builder/apk-lock.txt.

BUILDER_IMAGE := ghcr.io/colinmcintosh/static-tools/builder
BUILDER_DIGEST := sha256:cb116aa9e4e5ff06ee5fb358054d1c14d58856bde99612d297ac05971a802740

ALPINE_VERSION := 3.24
# Multi-arch index digest of alpine:3.24 (currently 3.24.1). Docker
# selects the platform from --platform / TARGETARCH, so one pin covers
# amd64 and arm64 and cannot be paired with the wrong architecture.
# The per-arch names stay so existing Makefiles keep working.
ALPINE_DIGEST := sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b
ALPINE_DIGEST_AMD64 := $(ALPINE_DIGEST)
ALPINE_DIGEST_ARM64 := $(ALPINE_DIGEST)

# Host tools built into the prefix (perl is required by OpenSSL Configure)
PERL_VERSION := 5.40.5
PERL_URL := https://www.cpan.org/src/5.0/perl-$(PERL_VERSION).tar.gz
PERL_SHA256 := 09d926ae2d1b277c3bce62054c41da47c981380d719c41cf980b67945cc581ed

# 0.29.2 (2017) is the final freedesktop pkg-config release; upstream is
# dead and pkgconf is the successor. It is build-time only and has no known
# CVEs, so it stays pinned deliberately. Not an oversight.
PKG_CONFIG_VERSION := 0.29.2
PKG_CONFIG_URL := https://pkg-config.freedesktop.org/releases/pkg-config-$(PKG_CONFIG_VERSION).tar.gz
PKG_CONFIG_SHA256 := 6fc69c01688c9458a57eb9a1664c9aba372ccda420a02bf4429fe610e7e7d591

# Libraries
ZLIB_VERSION := 1.3.2
ZLIB_URL := https://github.com/madler/zlib/releases/download/v$(ZLIB_VERSION)/zlib-$(ZLIB_VERSION).tar.gz
ZLIB_SHA256 := bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16
# Detached signature uploaded to the same GitHub release. zlib.net only
# keeps the latest release at the top level, so its .asc 404s once a newer
# zlib ships.
ZLIB_SIG_URL := https://github.com/madler/zlib/releases/download/v$(ZLIB_VERSION)/zlib-$(ZLIB_VERSION).tar.gz.asc
ZLIB_KEY := zlib

# 3.5 is the current LTS branch, supported until 2030-04-08. Do not move to a
# non-LTS branch: 3.4 and 3.6 both go EOL within months.
OPENSSL_VERSION := 3.5.8
OPENSSL_URL := https://github.com/openssl/openssl/releases/download/openssl-$(OPENSSL_VERSION)/openssl-$(OPENSSL_VERSION).tar.gz
OPENSSL_SHA256 := a8f84a39918ec6415ce765d9b429d313ba97b8143169c172e734b9514464f5b2

NGHTTP2_VERSION := 1.69.0
NGHTTP2_URL := https://github.com/nghttp2/nghttp2/releases/download/v$(NGHTTP2_VERSION)/nghttp2-$(NGHTTP2_VERSION).tar.gz
NGHTTP2_SHA256 := c866b7477cbb7512ab6863a685027adbb1bb8da8fc3bab7429ed43d3281d5aa9

NCURSES_VERSION := 6.6
NCURSES_URL := https://ftp.gnu.org/gnu/ncurses/ncurses-$(NCURSES_VERSION).tar.gz
NCURSES_SHA256 := 355b4cbbed880b0381a04c46617b7656e362585d52e9cf84a67e2009b749ff11

LIBCAP_VERSION := 2.78
# Stored kernel.org release tarball, not the git.kernel.org snapshot.
LIBCAP_URL := https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-$(LIBCAP_VERSION).tar.gz
LIBCAP_SHA256 := 2a2c705e382c413643a458b837575c0eb0989477ab6fb99c87adbe9a259612ad

LIBUV_VERSION := 1.52.1
LIBUV_URL := https://dist.libuv.org/dist/v$(LIBUV_VERSION)/libuv-v$(LIBUV_VERSION).tar.gz
LIBUV_SHA256 := 66d511b9e6e334c0e62279eb234fbfb2b3110b1479c09b95b44c7afca8cff9e7
LIBUV_SIG_URL := https://dist.libuv.org/dist/v$(LIBUV_VERSION)/libuv-v$(LIBUV_VERSION).tar.gz.sign
LIBUV_KEY := libuv

URCU_VERSION := 0.15.6
URCU_URL := https://lttng.org/files/urcu/userspace-rcu-$(URCU_VERSION).tar.bz2
URCU_SHA256 := 850b192096eb11ebf2c70e8f97bc7da7479ee41da1bebeb44e3986908bac414f

JEMALLOC_VERSION := 5.3.1
JEMALLOC_URL := https://github.com/jemalloc/jemalloc/releases/download/$(JEMALLOC_VERSION)/jemalloc-$(JEMALLOC_VERSION).tar.bz2
JEMALLOC_SHA256 := 3826bc80232f22ed5c4662f3034f799ca316e819103bdc7bb99018a421706f92

LIBPCAP_VERSION := 1.10.7
LIBPCAP_URL := https://www.tcpdump.org/release/libpcap-$(LIBPCAP_VERSION).tar.gz
LIBPCAP_SHA256 := 0b394ac90dbc0a9838ff97468e05c9c9a3e873dec2514cd58db65d859d296e31
LIBPCAP_SIG_URL := https://www.tcpdump.org/release/libpcap-$(LIBPCAP_VERSION).tar.gz.sig
LIBPCAP_KEY := tcpdump

XXHASH_VERSION := 0.8.3
# GitHub tag archive. The v0.8.3 release only uploads xxhsum_win64_*.zip;
# there is no stored source tarball asset.
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

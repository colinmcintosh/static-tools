# Shared static library prefix (built from upstream tarballs).
# Official gcc images are Debian/glibc-only, so the compiler is Alpine's
# musl gcc from a digest-pinned base image plus apk-pinned build-base
# and linux-headers (those two have been stable on 3.21). C libraries
# are NOT installed via apk; they are fetched by URL and verified with SHA256.

ALPINE_VERSION := 3.21
ALPINE_DIGEST_AMD64 := sha256:41c81533144786e0beb2b148667355a6c7659aa99a14ed837ff15a98ca9d71f3
ALPINE_DIGEST_ARM64 := sha256:fac2338de28c1143c0e69b48ba2d9b50481d5f1542b46c4656e5d6912d2d963a

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

OPENSSL_VERSION := 3.3.7
OPENSSL_URL := https://github.com/openssl/openssl/releases/download/openssl-$(OPENSSL_VERSION)/openssl-$(OPENSSL_VERSION).tar.gz
OPENSSL_SHA256 := 4900be54e81c4dfe00bb1a10dad33fd8414833573c40d0e9e3274d4ed32e53a2

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

PREFIX := /opt/st

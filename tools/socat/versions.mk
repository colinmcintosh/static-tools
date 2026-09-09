include ../../deps/versions.mk

SOCAT_VERSION := 1.8.1.3
# dest-unreach.org HTTPS presents a self-signed cert, so fetch Debian's
# orig tarball of the same upstream release over a public CA.
SOCAT_SOURCE_URL := https://deb.debian.org/debian/pool/main/s/socat/socat_$(SOCAT_VERSION).orig.tar.bz2
SOCAT_SOURCE_SHA256 := 25bc6476292b2e614220989c77b0b6fca87bb2525d9747b31a6639b1fb602418

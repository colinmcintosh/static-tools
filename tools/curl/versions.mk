# curl version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# curl source (tar.gz so the tool build does not need xz)
CURL_VERSION := 8.22.0
CURL_SOURCE_URL := https://curl.se/download/curl-$(CURL_VERSION).tar.gz
CURL_SOURCE_SHA256 := d54dd598bf05927a726deb38df31c6a255ba83ff1de57c5d1464dac3ed8f44a1

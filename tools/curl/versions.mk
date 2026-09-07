# curl version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# curl source (tar.gz so the tool build does not need xz)
CURL_VERSION := 8.11.1
CURL_SOURCE_URL := https://curl.se/download/curl-$(CURL_VERSION).tar.gz
CURL_SOURCE_SHA256 := a889ac9dbba3644271bd9d1302b5c22a088893719b72be3487bc3d401e5c4e80

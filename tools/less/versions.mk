# less version and checksums
# All versions and checksums should be pinned for reproducibility

include ../../deps/versions.mk

# less source. greenwoodsoftware.com is the canonical release site: the
# project's own download page explicitly tells users to fetch from there
# and NOT from GitHub, and the GitHub mirror (github.com/gwsw/less)
# publishes git tags but no GitHub Releases. 704 is the version marked
# RECOMMENDED on https://www.greenwoodsoftware.com/less/download.html
# (710 is a BETA tag ahead of it; 704 is the current stable release).
LESS_VERSION := 704
LESS_SOURCE_URL := https://www.greenwoodsoftware.com/less/less-$(LESS_VERSION).tar.gz
LESS_SOURCE_SHA256 := 20a0b0a2bb2525fa53c7eee9beb854b4c9cf172eabb209af7020743547bfe9fb

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS := ncurses

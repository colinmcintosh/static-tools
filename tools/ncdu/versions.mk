include ../../deps/versions.mk

# Deliberately stays on 1.x. 1.22 is the final release of the C line;
# upstream's active 2.x line is a Zig rewrite, and the builder image has no
# Zig toolchain. 1.22 has no known CVEs. Revisit if a 1.x CVE appears.
NCDU_VERSION := 1.22
NCDU_SOURCE_URL := https://dev.yorhel.nl/download/ncdu-$(NCDU_VERSION).tar.gz
NCDU_SOURCE_SHA256 := 0ad6c096dc04d5120581104760c01b8f4e97d4191d6c9ef79654fa3c691a176b
NCDU_SOURCE_SIG_URL := https://dev.yorhel.nl/download/ncdu-$(NCDU_VERSION).tar.gz.asc
NCDU_SOURCE_KEY := ncdu

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS := ncurses

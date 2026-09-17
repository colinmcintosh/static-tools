# tree version and checksums
# All versions and checksums should be pinned for reproducibility
#
# Upstream: the original author's mama.indstate.edu page is stale; Steve
# Baker now publishes from oldmanprogrammer.net with this GitLab repo (and
# a GitHub mirror at github.com/Old-Man-Programmer/tree) as the current
# canonical source. See README/LICENSE in the tarball: same author,
# copyright 1996 - 2026.

include ../../deps/versions.mk

TREE_VERSION := 2.3.2
TREE_SOURCE_URL := https://gitlab.com/OldManProgrammer/unix-tree/-/archive/$(TREE_VERSION)/unix-tree-$(TREE_VERSION).tar.gz
TREE_SOURCE_SHA256 := 513a53cbc42ca1f4ea06af2bab1f5283524a3848266b1d162416f8033afc4985

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS :=

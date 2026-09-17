# openssl CLI is produced by the shared prefix (same pinned OpenSSL tarball).

include ../../deps/versions.mk

# Prefix libraries statically linked into this artifact (SBOM).
SBOM_LIBS := openssl

ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG ZSTD_VERSION
ARG ZSTD_URL
ARG ZSTD_SHA256
ARG TARGETARCH

ENV CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LDFLAGS="-static-pie"

WORKDIR /src
RUN wget -q "${ZSTD_URL}" -O zstd.tar.gz && \
    echo "${ZSTD_SHA256}  zstd.tar.gz" | sha256sum -c -

# zstd's build is plain Make, not autotools. `programs/Makefile` pulls in
# `lib/libzstd.mk`, which does `CFLAGS ?= -O3` and then appends to it
# (`CFLAGS += $(DEBUGFLAGS) $(MOREFLAGS)`), and appends to LDFLAGS too
# (globally, and again per-target for e.g. `-pthread` once threading is
# detected). GNU Make variables set on the `make` command line cannot be
# changed by any later `+=`/`?=` in the Makefile, which would silently drop
# those appends; a plain environment variable does not have that
# restriction and still composes correctly. So CFLAGS/LDFLAGS are set here
# as Dockerfile ENV (process environment for the RUN below), not as `make
# VAR=...` arguments. `zstd-release` is upstream's own default build target
# (plain `make` runs `lib-release zstd-release`); it compiles the library
# sources directly alongside the CLI sources into a single binary, so there
# is no separate libzstd.a step needed.
RUN tar xzf zstd.tar.gz && \
    cd zstd-${ZSTD_VERSION}/programs && \
    make -j"$(nproc)" zstd-release && \
    mkdir -p /out && \
    cp zstd /out/zstd && \
    strip /out/zstd && \
    /out/zstd --version && \
    ! readelf -l /out/zstd | grep -q INTERP && \
    readelf -h /out/zstd | grep -q 'Type:[[:space:]]*DYN' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

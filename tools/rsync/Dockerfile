# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG RSYNC_VERSION
ARG RSYNC_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Compiler only. zlib, OpenSSL, xxhash, zstd, and lz4 come from the prefix.
RUN apk add --no-cache \
    build-base=0.5-r3

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static" \
    CFLAGS="-Os -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "https://github.com/RsyncProject/rsync/releases/download/v${RSYNC_VERSION}/rsync-${RSYNC_VERSION}.tar.gz" -O rsync.tar.gz && \
    echo "${RSYNC_SOURCE_SHA256}  rsync.tar.gz" | sha256sum -c -

RUN tar xzf rsync.tar.gz && \
    cd rsync-${RSYNC_VERSION} && \
    ./configure \
        --prefix=/usr \
        --with-included-popt \
        --without-included-zlib \
        --disable-acl-support \
        --disable-xattr-support \
        --disable-md2man && \
    make -j"$(nproc)" LDFLAGS="-L${PREFIX}/lib -static" && \
    mkdir -p /out && \
    cp rsync /out/rsync && \
    strip /out/rsync && \
    file /out/rsync | grep -q "statically linked" && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

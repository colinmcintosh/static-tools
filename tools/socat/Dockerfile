# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG SOCAT_VERSION
ARG SOCAT_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Compiler + bzip2 for Debian's orig tarball. OpenSSL comes from the SHA256-pinned prefix.
# The decompressor is unpinned: it only unpacks a SHA256-verified tarball.
# hadolint ignore=DL3018
RUN apk add --no-cache \
    build-base=0.5-r3 \
    bzip2 \
    linux-headers=6.6-r1

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static-pie" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LIBS="-lssl -lcrypto -lz -ldl -lpthread"

WORKDIR /src
RUN wget -q "https://deb.debian.org/debian/pool/main/s/socat/socat_${SOCAT_VERSION}.orig.tar.bz2" -O socat.tar.bz2 && \
    echo "${SOCAT_SOURCE_SHA256}  socat.tar.bz2" | sha256sum -c -

RUN tar xjf socat.tar.bz2 && \
    cd socat-${SOCAT_VERSION} && \
    ./configure \
        --prefix=/usr \
        --disable-readline \
        --disable-libwrap \
        --enable-openssl && \
    make -j"$(nproc)" LDFLAGS="-L${PREFIX}/lib -static-pie" && \
    mkdir -p /out && \
    cp socat /out/socat && \
    strip /out/socat && \
    ! readelf -l /out/socat | grep -q INTERP && \
    readelf -h /out/socat | grep -q 'Type:[[:space:]]*DYN' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

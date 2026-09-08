# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG NMAP_VERSION
ARG NMAP_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Compiler + bzip2 for the nmap tarball. OpenSSL/zlib/libpcap come from the prefix.
RUN apk add --no-cache \
    build-base=0.5-r3 \
    bzip2=1.0.8-r6 \
    linux-headers=6.6-r1

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static" \
    CFLAGS="-static -Os -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LIBS="-lssl -lcrypto -lz -ldl -lpthread"

WORKDIR /src
RUN wget -q "https://nmap.org/dist/nmap-${NMAP_VERSION}.tar.bz2" -O nmap.tar.bz2 && \
    echo "${NMAP_SOURCE_SHA256}  nmap.tar.bz2" | sha256sum -c -

RUN tar xjf nmap.tar.bz2 && \
    cd nmap-${NMAP_VERSION} && \
    ./configure \
        --prefix=/usr \
        --without-zenmap \
        --without-ndiff \
        --without-nmap-update \
        --without-liblua \
        --without-nping \
        --without-libssh2 \
        --with-openssl="${PREFIX}" \
        --with-libpcap="${PREFIX}" && \
    make -C nbase -j"$(nproc)" && \
    make -C nsock/src -j"$(nproc)" && \
    make -C ncat -j"$(nproc)" && \
    mkdir -p /out && \
    cp ncat/ncat /out/ncat && \
    strip /out/ncat && \
    file /out/ncat | grep -q "statically linked" && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

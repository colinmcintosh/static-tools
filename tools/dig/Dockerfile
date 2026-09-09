# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG BIND9_VERSION
ARG BIND9_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Compiler + xz for the BIND tarball. C libraries come from the SHA256-pinned prefix.
RUN apk add --no-cache \
    build-base=0.5-r3 \
    linux-headers=6.6-r1 \
    xz=5.8.4-r0

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static" \
    CFLAGS="-static -Os -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "https://downloads.isc.org/isc/bind9/${BIND9_VERSION}/bind-${BIND9_VERSION}.tar.xz" -O bind.tar.xz && \
    echo "${BIND9_SOURCE_SHA256}  bind.tar.xz" | sha256sum -c -

# BIND 9.16.x is the last autoconf version that allows static compilation.
RUN tar xf bind.tar.xz && \
    cd bind-${BIND9_VERSION} && \
    ./configure \
        --without-python \
        --disable-symtable \
        --disable-backtrace \
        --disable-linux-caps \
        --with-openssl="${PREFIX}" \
        --with-libxml2=no \
        --with-libuv="${PREFIX}" \
        --with-nghttp2="${PREFIX}" && \
    cd lib/dns/ && make -j"$(nproc)" && \
    cd ../bind9/ && make -j"$(nproc)" && \
    cd ../isc && make -j"$(nproc)" && \
    cd ../isccfg/ && make -j"$(nproc)" && \
    cd ../irs/ && make -j"$(nproc)" && \
    cd ../../bin/dig && make -j"$(nproc)" && \
    mkdir -p /out && \
    cp dig /out/dig && \
    strip /out/dig && \
    file /out/dig | grep -q "statically linked" && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

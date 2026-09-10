# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG BIND9_VERSION
ARG BIND9_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Compiler + xz for the BIND tarball. C libraries come from the SHA256-pinned prefix.
# The decompressor is unpinned: it only unpacks a SHA256-verified tarball.
# hadolint ignore=DL3018
RUN apk add --no-cache \
    build-base=0.5-r3 \
    linux-headers=6.6-r1 \
    xz

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static-pie" \
    CFLAGS="-Os -fPIE -ftls-model=local-exec -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "https://downloads.isc.org/isc/bind9/${BIND9_VERSION}/bind-${BIND9_VERSION}.tar.xz" -O bind.tar.xz && \
    echo "${BIND9_SOURCE_SHA256}  bind.tar.xz" | sha256sum -c -

# BIND 9.16.x is the last autoconf version that allows static compilation.
# --export-dynamic leaves a TPOFF reloc for isc_tid_v; musl static-pie
# does not apply it, and amd64 dig then segfaults during OpenSSL init.
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
    find . -name Makefile -exec sed -i 's/ -Wl,--export-dynamic//g; s/-Wl,--export-dynamic//g' {} + && \
    cd lib/dns/ && make -j"$(nproc)" && \
    cd ../bind9/ && make -j"$(nproc)" && \
    cd ../isc && make -j"$(nproc)" && \
    cd ../isccfg/ && make -j"$(nproc)" && \
    cd ../irs/ && make -j"$(nproc)" && \
    cd ../../bin/dig && make -j"$(nproc)" && \
    mkdir -p /out && \
    cp dig /out/dig && \
    strip /out/dig && \
    ! readelf -l /out/dig | grep -q INTERP && \
    readelf -h /out/dig | grep -q 'Type:[[:space:]]*DYN' && \
    ! readelf -Wr /out/dig | awk '$3 ~ /^R_/ && $3 !~ /RELATIVE$/ { found=1 } END { exit found ? 0 : 1 }' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

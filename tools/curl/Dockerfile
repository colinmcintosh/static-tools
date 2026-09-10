# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG CURL_VERSION
ARG CURL_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Compiler only. OpenSSL, zlib, and nghttp2 come from the SHA256-pinned prefix.
RUN apk add --no-cache \
    build-base=0.5-r3

# Additional context `deps` is the exported static prefix (see deps/Dockerfile).
COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static-pie" \
    CFLAGS="-Os -fPIE -ftls-model=local-exec -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "https://curl.se/download/curl-${CURL_VERSION}.tar.gz" -O curl.tar.gz && \
    echo "${CURL_SOURCE_SHA256}  curl.tar.gz" | sha256sum -c -

RUN tar xzf curl.tar.gz && \
    cd curl-${CURL_VERSION} && \
    ./configure \
        --prefix=/usr \
        --disable-shared \
        --enable-static \
        --with-openssl="${PREFIX}" \
        --with-nghttp2="${PREFIX}" \
        --with-zlib="${PREFIX}" \
        --with-ca-path=/etc/ssl/certs \
        --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt \
        --without-brotli \
        --without-libidn2 \
        --without-libpsl \
        --disable-ares \
        --disable-ldap \
        --disable-ldaps \
        --disable-rtsp \
        --disable-dict \
        --disable-telnet \
        --disable-tftp \
        --disable-pop3 \
        --disable-imap \
        --disable-smb \
        --disable-smtp \
        --disable-gopher \
        --disable-mqtt \
        --disable-manual \
        --disable-docs && \
    make -j"$(nproc)" LDFLAGS="-L${PREFIX}/lib -static-pie" && \
    mkdir -p /out && \
    cp src/curl /out/curl && \
    strip /out/curl && \
    /out/curl --version && \
    ! readelf -l /out/curl | grep -q INTERP && \
    readelf -h /out/curl | grep -q 'Type:[[:space:]]*DYN' && \
    ! readelf -Wr /out/curl | awk '$3 ~ /^R_/ && $3 !~ /RELATIVE$/ { found=1 } END { exit found ? 0 : 1 }' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

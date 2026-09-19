ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG CURL_VERSION
ARG CURL_SOURCE_URL
ARG CURL_SOURCE_SHA256
ARG PREFIX=/opt/st

# Additional context `deps` is the exported static prefix (see deps/Dockerfile).
COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static-pie" \
    CFLAGS="-Os -fPIE -ftls-model=local-exec -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "${CURL_SOURCE_URL}" -O curl.tar.gz && \
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
        --without-ca-bundle \
        --without-ca-path \
        --with-ca-fallback \
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
    /out/curl --version

FROM scratch AS export
COPY --from=builder /out/ /

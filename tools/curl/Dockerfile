# syntax=docker/dockerfile:1.7

# Build arguments
ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

# Use Alpine with musl libc for fully static binaries
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

# Build arguments available in build stage
ARG CURL_VERSION
ARG CURL_SOURCE_SHA256
ARG TARGETARCH

# Install build dependencies
# Using static versions of required libraries for static linking
RUN apk add --no-cache \
    build-base=0.5-r3 \
    linux-headers=6.6-r1 \
    perl=5.40.3-r0 \
    openssl-dev=3.3.6-r0 \
    openssl-libs-static=3.3.6-r0 \
    nghttp2-dev=1.64.0-r0 \
    nghttp2-static=1.64.0-r0 \
    zlib-dev=1.3.1-r2 \
    zlib-static=1.3.1-r2 \
    xz=5.6.3-r1

# Download and verify source
WORKDIR /src
RUN wget -q "https://curl.se/download/curl-${CURL_VERSION}.tar.xz" -O curl.tar.xz && \
    echo "${CURL_SOURCE_SHA256}  curl.tar.xz" | sha256sum -c -

# Extract and build curl
RUN tar xf curl.tar.xz && \
    cd curl-${CURL_VERSION} && \
    # Configure for static build with common protocols
    CFLAGS="-Os -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LDFLAGS="-static" \
    ./configure \
        --prefix=/usr \
        --disable-shared \
        --enable-static \
        --with-openssl \
        --with-nghttp2 \
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
    make -j"$(nproc)" LDFLAGS="-static -all-static" && \
    # Copy binary to output
    mkdir -p /out && \
    cp src/curl /out/curl && \
    strip /out/curl && \
    # Verify it's statically linked
    file /out/curl | grep -q "statically linked" && \
    # Generate checksums
    cd /out && sha256sum * > SHA256SUMS

# Export stage - minimal image with just the binaries
FROM scratch AS export
COPY --from=builder /out/ /

# syntax=docker/dockerfile:1.7

# Build arguments
ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

# Use Alpine with musl libc for fully static binaries
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

# Build arguments available in build stage
ARG WGET_VERSION
ARG WGET_SOURCE_SHA256
ARG TARGETARCH

# Install build dependencies
# Using static versions of required libraries for static linking
RUN apk add --no-cache \
    build-base=0.5-r3 \
    linux-headers=6.6-r1 \
    perl=5.40.3-r0 \
    openssl-dev=3.3.6-r0 \
    openssl-libs-static=3.3.6-r0 \
    zlib-dev=1.3.1-r2 \
    zlib-static=1.3.1-r2

# Download and verify source
WORKDIR /src
RUN wget -q "https://ftp.gnu.org/gnu/wget/wget-${WGET_VERSION}.tar.gz" -O wget.tar.gz && \
    echo "${WGET_SOURCE_SHA256}  wget.tar.gz" | sha256sum -c -

# Extract and build wget
RUN tar xzf wget.tar.gz && \
    cd wget-${WGET_VERSION} && \
    # Configure for static build
    CFLAGS="-Os -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LDFLAGS="-static" \
    ./configure \
        --prefix=/usr \
        --with-ssl=openssl \
        --without-libidn \
        --disable-nls \
        --disable-pcre \
        --disable-iri && \
    make -j"$(nproc)" && \
    # Copy binary to output
    mkdir -p /out && \
    cp src/wget /out/wget && \
    strip /out/wget && \
    # Verify it's statically linked
    file /out/wget | grep -q "statically linked" && \
    # Generate checksums
    cd /out && sha256sum * > SHA256SUMS

# Export stage - minimal image with just the binaries
FROM scratch AS export
COPY --from=builder /out/ /

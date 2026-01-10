# syntax=docker/dockerfile:1.7

# Build arguments
ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

# Use Alpine with musl libc for fully static binaries
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

# Build arguments available in build stage
ARG LDNS_VERSION
ARG LDNS_SOURCE_SHA256
ARG TARGETARCH

# Install build dependencies
# ldns provides drill which is a dig-like tool that can be statically compiled
RUN apk add --no-cache \
    build-base=0.5-r3 \
    linux-headers=6.6-r1 \
    openssl-dev=3.3.5-r0 \
    openssl-libs-static=3.3.5-r0

# Download and verify source
WORKDIR /src
RUN wget -q "https://nlnetlabs.nl/downloads/ldns/ldns-${LDNS_VERSION}.tar.gz" -O ldns.tar.gz && \
    echo "${LDNS_SOURCE_SHA256}  ldns.tar.gz" | sha256sum -c -

# Extract and build drill (dig alternative)
RUN tar xzf ldns.tar.gz && \
    cd ldns-${LDNS_VERSION} && \
    # Configure for static build
    ./configure \
        --prefix=/usr \
        --disable-shared \
        --enable-static \
        --with-drill \
        --disable-dane \
        --disable-dane-ta-usage \
        CFLAGS="-Os -fstack-protector-strong -D_FORTIFY_SOURCE=2" && \
    # Build library only first
    make -j"$(nproc)" && \
    # Now re-link drill with -all-static flag
    cd drill && \
    ../libtool --tag=CC --mode=link gcc -all-static -s -Os \
        -o drill \
        chasetrace.lo dnssec.lo drill.lo drill_util.lo \
        error.lo root.lo securetrace.lo work.lo \
        ../compat/b64_pton.lo ../compat/b64_ntop.lo \
        ../libldns.la -lcrypto && \
    # Copy binary to output
    mkdir -p /out && \
    cp .libs/drill /out/drill 2>/dev/null || cp drill /out/drill && \
    # Verify it's statically linked (file output shows "statically linked")
    file /out/drill | grep -q "statically linked" && \
    # Generate checksums
    cd /out && sha256sum * > SHA256SUMS

# Export stage - minimal image with just the binaries
FROM scratch AS export
COPY --from=builder /out/ /

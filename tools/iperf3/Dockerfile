# syntax=docker/dockerfile:1.7

# Build arguments
ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

# Use Alpine with musl libc for fully static binaries
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

# Build arguments available in build stage
ARG IPERF3_VERSION
ARG IPERF3_SOURCE_SHA256
ARG TARGETARCH

# Install build dependencies
# Using static versions of required libraries for static linking
RUN apk add --no-cache \
    build-base=0.5-r3 \
    linux-headers=6.6-r1 \
    openssl-dev=3.3.6-r0 \
    openssl-libs-static=3.3.6-r0

# Download and verify source
WORKDIR /src
RUN wget -q "https://github.com/esnet/iperf/releases/download/${IPERF3_VERSION}/iperf-${IPERF3_VERSION}.tar.gz" -O iperf3.tar.gz && \
    echo "${IPERF3_SOURCE_SHA256}  iperf3.tar.gz" | sha256sum -c -

# Extract and build iperf3
RUN tar xzf iperf3.tar.gz && \
    cd iperf-${IPERF3_VERSION} && \
    # Configure for static build
    CFLAGS="-Os -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LDFLAGS="-static" \
    ./configure \
        --prefix=/usr \
        --disable-shared \
        --enable-static \
        --enable-static-bin \
        --with-openssl=/usr && \
    make -j"$(nproc)" && \
    # Copy binary to output
    mkdir -p /out && \
    cp src/iperf3 /out/iperf3 && \
    strip /out/iperf3 && \
    # Verify it's statically linked
    file /out/iperf3 | grep -q "statically linked" && \
    # Generate checksums
    cd /out && sha256sum * > SHA256SUMS

# Export stage - minimal image with just the binaries
FROM scratch AS export
COPY --from=builder /out/ /

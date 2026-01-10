# syntax=docker/dockerfile:1.7

# Build arguments
ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

# Use Alpine with musl libc for fully static binaries
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

# Build arguments available in build stage
ARG MTR_VERSION
ARG MTR_SOURCE_SHA256
ARG TARGETARCH

# Install build dependencies
RUN apk add --no-cache \
    autoconf=2.72-r0 \
    automake=1.17-r0 \
    build-base=0.5-r3 \
    libcap-dev=2.71-r0 \
    libcap-static=2.71-r0 \
    linux-headers=6.6-r1 \
    ncurses-dev=6.5_p20241006-r3 \
    ncurses-static=6.5_p20241006-r3

# Download and verify source (wget is included in Alpine base image)
WORKDIR /src
RUN wget -q "https://github.com/traviscross/mtr/archive/refs/tags/v${MTR_VERSION}.tar.gz" -O mtr.tar.gz && \
    echo "${MTR_SOURCE_SHA256}  mtr.tar.gz" | sha256sum -c -

# Extract and build
RUN tar xzf mtr.tar.gz && \
    cd mtr-${MTR_VERSION} && \
    ./bootstrap.sh && \
    ./configure \
        --without-gtk \
        --without-jansson \
        CFLAGS="-static -Os -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
        LDFLAGS="-static -s" && \
    make -j"$(nproc)" && \
    # Verify binaries are statically linked
    file mtr | grep -q "statically linked" && \
    file mtr-packet | grep -q "statically linked" && \
    # Copy to output directory
    mkdir -p /out && \
    cp mtr mtr-packet /out/ && \
    # Generate checksums
    cd /out && sha256sum * > SHA256SUMS

# Export stage - minimal image with just the binaries
FROM scratch AS export
COPY --from=builder /out/ /

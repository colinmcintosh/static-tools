# syntax=docker/dockerfile:1.7

# Build arguments
ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

# Use Alpine with musl libc for fully static binaries
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

# Build arguments available in build stage
ARG BIND9_VERSION
ARG BIND9_SOURCE_SHA256
ARG TARGETARCH

# Install build dependencies
# Using static versions of required libraries for static linking
RUN apk add --no-cache \
    build-base=0.5-r3 \
    linux-headers=6.6-r1 \
    perl=5.40.3-r0 \
    libuv-dev=1.49.2-r0 \
    libuv-static=1.49.2-r0 \
    userspace-rcu-dev=0.14.1-r1 \
    userspace-rcu-static=0.14.1-r1 \
    nghttp2-dev=1.64.0-r0 \
    nghttp2-static=1.64.0-r0 \
    openssl-dev=3.3.5-r0 \
    openssl-libs-static=3.3.5-r0 \
    libcap-dev=2.71-r0 \
    libcap-static=2.71-r0 \
    jemalloc-dev=5.3.0-r6 \
    jemalloc-static=5.3.0-r6 \
    xz=5.6.3-r1

# Download and verify source
WORKDIR /src
RUN wget -q "https://downloads.isc.org/isc/bind9/${BIND9_VERSION}/bind-${BIND9_VERSION}.tar.xz" -O bind.tar.xz && \
    echo "${BIND9_SOURCE_SHA256}  bind.tar.xz" | sha256sum -c -

# Extract and build dig
# BIND 9.16.x is the last version using autoconf that allows static compilation
# Newer versions use Meson and explicitly disable static linking
RUN tar xf bind.tar.xz && \
    cd bind-${BIND9_VERSION} && \
    # Configure for static build
    # --disable-linux-caps: Avoids libcap dynamic linking issues
    # --disable-symtable: Removes symbol table which may use dlopen
    # --disable-backtrace: Removes backtrace which may use dynamic features
    # --without-python: Avoids python bindings that prevent static linking
    CFLAGS="-static -Os -fstack-protector-strong" \
    LDFLAGS="-static" \
    ./configure \
        --without-python \
        --disable-symtable \
        --disable-backtrace \
        --disable-linux-caps && \
    # Build only the libraries needed for dig
    cd lib/dns/ && make -j"$(nproc)" && \
    cd ../bind9/ && make -j"$(nproc)" && \
    cd ../isc && make -j"$(nproc)" && \
    cd ../isccfg/ && make -j"$(nproc)" && \
    cd ../irs/ && make -j"$(nproc)" && \
    # Build dig
    cd ../../bin/dig && make -j"$(nproc)" && \
    # Copy binary to output
    mkdir -p /out && \
    cp dig /out/dig && \
    strip /out/dig && \
    # Verify it's statically linked
    file /out/dig | grep -q "statically linked" && \
    # Generate checksums
    cd /out && sha256sum * > SHA256SUMS

# Export stage - minimal image with just the binaries
FROM scratch AS export
COPY --from=builder /out/ /

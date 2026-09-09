# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG STRACE_VERSION
ARG STRACE_SOURCE_SHA256
ARG TARGETARCH

# xz for the official release tarball. --enable-mpers=no is required for musl static.
RUN apk add --no-cache \
    build-base=0.5-r3 \
    linux-headers=6.6-r1 \
    xz=5.8.3-r0

ENV CFLAGS="-Os -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LDFLAGS="-static"

WORKDIR /src
RUN wget -q "https://github.com/strace/strace/releases/download/v${STRACE_VERSION}/strace-${STRACE_VERSION}.tar.xz" -O strace.tar.xz && \
    echo "${STRACE_SOURCE_SHA256}  strace.tar.xz" | sha256sum -c -

RUN tar xf strace.tar.xz && \
    cd strace-${STRACE_VERSION} && \
    ./configure \
        --prefix=/usr \
        --enable-mpers=no && \
    make -j"$(nproc)" LDFLAGS="-static" && \
    mkdir -p /out && \
    cp src/strace /out/strace && \
    strip /out/strace && \
    file /out/strace | grep -q "statically linked" && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG TCPDUMP_VERSION
ARG TCPDUMP_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Compiler only. libpcap and OpenSSL come from the SHA256-pinned prefix.
RUN apk add --no-cache \
    build-base=0.5-r3 \
    linux-headers=6.6-r1

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static" \
    CFLAGS="-Os -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "https://www.tcpdump.org/release/tcpdump-${TCPDUMP_VERSION}.tar.gz" -O tcpdump.tar.gz && \
    echo "${TCPDUMP_SOURCE_SHA256}  tcpdump.tar.gz" | sha256sum -c -

RUN tar xzf tcpdump.tar.gz && \
    cd tcpdump-${TCPDUMP_VERSION} && \
    ./configure \
        --prefix=/usr \
        --disable-shared \
        --with-crypto="${PREFIX}" && \
    make -j"$(nproc)" LDFLAGS="-L${PREFIX}/lib -static" && \
    mkdir -p /out && \
    cp tcpdump /out/tcpdump && \
    strip /out/tcpdump && \
    file /out/tcpdump | grep -q "statically linked" && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

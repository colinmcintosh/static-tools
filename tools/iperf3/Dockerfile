# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG IPERF3_VERSION
ARG IPERF3_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Compiler only. OpenSSL comes from the SHA256-pinned prefix.
RUN apk add --no-cache \
    build-base=0.5-r3 \
    linux-headers=6.6-r1

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "https://github.com/esnet/iperf/releases/download/${IPERF3_VERSION}/iperf-${IPERF3_VERSION}.tar.gz" -O iperf3.tar.gz && \
    echo "${IPERF3_SOURCE_SHA256}  iperf3.tar.gz" | sha256sum -c -

RUN tar xzf iperf3.tar.gz && \
    cd iperf-${IPERF3_VERSION} && \
    LIBS="-lssl -lcrypto -lz -ldl -pthread" \
    ./configure \
        --prefix=/usr \
        --disable-shared \
        --enable-static \
        --enable-static-bin \
        --with-openssl="${PREFIX}" && \
    make -j"$(nproc)" LDFLAGS="-L${PREFIX}/lib -static-pie" && \
    mkdir -p /out && \
    cp src/iperf3 /out/iperf3 && \
    strip /out/iperf3 && \
    ! readelf -l /out/iperf3 | grep -q INTERP && \
    readelf -h /out/iperf3 | grep -q 'Type:[[:space:]]*DYN' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

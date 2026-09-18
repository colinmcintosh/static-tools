# syntax=docker/dockerfile:1.7

ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG TCPDUMP_VERSION
ARG TCPDUMP_SOURCE_URL
ARG TCPDUMP_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static-pie" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "${TCPDUMP_SOURCE_URL}" -O tcpdump.tar.gz && \
    echo "${TCPDUMP_SOURCE_SHA256}  tcpdump.tar.gz" | sha256sum -c -

RUN tar xzf tcpdump.tar.gz && \
    cd tcpdump-${TCPDUMP_VERSION} && \
    ./configure \
        --prefix=/usr \
        --disable-shared \
        --with-crypto="${PREFIX}" && \
    make -j"$(nproc)" LDFLAGS="-L${PREFIX}/lib -static-pie" && \
    mkdir -p /out && \
    cp tcpdump /out/tcpdump && \
    strip /out/tcpdump && \
    ! readelf -l /out/tcpdump | grep -q INTERP && \
    readelf -h /out/tcpdump | grep -q 'Type:[[:space:]]*DYN' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

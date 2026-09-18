ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG NMAP_VERSION
ARG NMAP_SOURCE_URL
ARG NMAP_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static-pie" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LIBS="-lssl -lcrypto -lz -ldl -lpthread"

WORKDIR /src
RUN wget -q "${NMAP_SOURCE_URL}" -O nmap.tar.bz2 && \
    echo "${NMAP_SOURCE_SHA256}  nmap.tar.bz2" | sha256sum -c -

RUN tar xjf nmap.tar.bz2 && \
    cd nmap-${NMAP_VERSION} && \
    ./configure \
        --prefix=/usr \
        --without-zenmap \
        --without-ndiff \
        --without-nmap-update \
        --without-liblua \
        --without-nping \
        --without-libssh2 \
        --with-openssl="${PREFIX}" \
        --with-libpcap="${PREFIX}" && \
    make -C nbase -j"$(nproc)" && \
    make -C nsock/src -j"$(nproc)" && \
    make -C ncat -j"$(nproc)" && \
    mkdir -p /out && \
    cp ncat/ncat /out/ncat && \
    strip /out/ncat && \
    ! readelf -l /out/ncat | grep -q INTERP && \
    readelf -h /out/ncat | grep -q 'Type:[[:space:]]*DYN' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

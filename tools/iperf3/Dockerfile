ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG IPERF3_VERSION
ARG IPERF3_SOURCE_URL
ARG IPERF3_SOURCE_SHA256
ARG PREFIX=/opt/st

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "${IPERF3_SOURCE_URL}" -O iperf3.tar.gz && \
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
    strip /out/iperf3

FROM scratch AS export
COPY --from=builder /out/ /

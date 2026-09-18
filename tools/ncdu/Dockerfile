# syntax=docker/dockerfile:1.7

ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG NCDU_VERSION
ARG NCDU_SOURCE_URL
ARG NCDU_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include -I${PREFIX}/include/ncursesw" \
    LDFLAGS="-L${PREFIX}/lib -static-pie" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "${NCDU_SOURCE_URL}" -O ncdu.tar.gz && \
    echo "${NCDU_SOURCE_SHA256}  ncdu.tar.gz" | sha256sum -c -

RUN tar xzf ncdu.tar.gz && \
    cd ncdu-${NCDU_VERSION} && \
    ./configure --prefix=/usr && \
    make -j"$(nproc)" LDFLAGS="-L${PREFIX}/lib -static-pie" && \
    mkdir -p /out && \
    cp ncdu /out/ncdu && \
    strip /out/ncdu && \
    ! readelf -l /out/ncdu | grep -q INTERP && \
    readelf -h /out/ncdu | grep -q 'Type:[[:space:]]*DYN' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

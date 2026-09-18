# syntax=docker/dockerfile:1.7

ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG HTOP_VERSION
ARG HTOP_SOURCE_URL
ARG HTOP_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include -I${PREFIX}/include/ncursesw" \
    LDFLAGS="-L${PREFIX}/lib" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "${HTOP_SOURCE_URL}" -O htop.tar.xz && \
    echo "${HTOP_SOURCE_SHA256}  htop.tar.xz" | sha256sum -c -

RUN tar xf htop.tar.xz && \
    cd htop-${HTOP_VERSION} && \
    ./configure \
        --prefix=/usr \
        --enable-unicode \
        --enable-capabilities \
        --disable-unwind && \
    make -j"$(nproc)" LDFLAGS="-L${PREFIX}/lib -static-pie" && \
    mkdir -p /out && \
    cp htop /out/htop && \
    strip /out/htop && \
    ! readelf -l /out/htop | grep -q INTERP && \
    readelf -h /out/htop | grep -q 'Type:[[:space:]]*DYN' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

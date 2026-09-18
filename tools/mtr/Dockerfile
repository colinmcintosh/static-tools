# syntax=docker/dockerfile:1.7

ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG MTR_VERSION
ARG MTR_SOURCE_URL
ARG MTR_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include -I${PREFIX}/include/ncursesw" \
    LDFLAGS="-L${PREFIX}/lib -static-pie" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "${MTR_SOURCE_URL}" -O mtr.tar.gz && \
    echo "${MTR_SOURCE_SHA256}  mtr.tar.gz" | sha256sum -c -

# Upstream 48e1794 (after 0.96): clip the res_query() length in the ASN
# lookup to the answer buffer. Drop this when a release includes it.
COPY asn-clip-len.patch /src/

RUN tar xzf mtr.tar.gz && \
    cd mtr-${MTR_VERSION} && \
    patch -p1 < /src/asn-clip-len.patch && \
    ./configure \
        --without-gtk \
        --without-jansson \
        CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
        LDFLAGS="-L${PREFIX}/lib -static-pie -s" && \
    make -j"$(nproc)" && \
    ! readelf -l mtr | grep -q INTERP && \
    readelf -h mtr | grep -q 'Type:[[:space:]]*DYN' && \
    ! readelf -l mtr-packet | grep -q INTERP && \
    readelf -h mtr-packet | grep -q 'Type:[[:space:]]*DYN' && \
    mkdir -p /out && \
    cp mtr mtr-packet /out/ && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

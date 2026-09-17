# syntax=docker/dockerfile:1.7

ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG WGET_VERSION
ARG WGET_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static-pie" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "https://ftp.gnu.org/gnu/wget/wget-${WGET_VERSION}.tar.gz" -O wget.tar.gz && \
    echo "${WGET_SOURCE_SHA256}  wget.tar.gz" | sha256sum -c -

RUN tar xzf wget.tar.gz && \
    cd wget-${WGET_VERSION} && \
    ./configure \
        --prefix=/usr \
        --with-ssl=openssl \
        --with-libssl-prefix="${PREFIX}" \
        --with-zlib="${PREFIX}" \
        --without-libidn \
        --disable-nls \
        --disable-pcre \
        --disable-iri && \
    make -j"$(nproc)" SUBDIRS="lib src" LDFLAGS="-L${PREFIX}/lib -static-pie" && \
    mkdir -p /out && \
    cp src/wget /out/wget && \
    strip /out/wget && \
    ! readelf -l /out/wget | grep -q INTERP && \
    readelf -h /out/wget | grep -q 'Type:[[:space:]]*DYN' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

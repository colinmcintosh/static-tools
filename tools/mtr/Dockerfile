# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG MTR_VERSION
ARG MTR_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Compiler + autotools. ncurses and libcap come from the SHA256-pinned prefix.
RUN apk add --no-cache \
    autoconf=2.72-r0 \
    automake=1.17-r0 \
    build-base=0.5-r3 \
    linux-headers=6.6-r1

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include -I${PREFIX}/include/ncursesw" \
    LDFLAGS="-L${PREFIX}/lib -static-pie" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "https://github.com/traviscross/mtr/archive/refs/tags/v${MTR_VERSION}.tar.gz" -O mtr.tar.gz && \
    echo "${MTR_SOURCE_SHA256}  mtr.tar.gz" | sha256sum -c -

RUN tar xzf mtr.tar.gz && \
    cd mtr-${MTR_VERSION} && \
    ./bootstrap.sh && \
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

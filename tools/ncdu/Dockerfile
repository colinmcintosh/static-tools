# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG NCDU_VERSION
ARG NCDU_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Compiler only. ncurses comes from the SHA256-pinned prefix.
RUN apk add --no-cache \
    build-base=0.5-r3

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include -I${PREFIX}/include/ncursesw" \
    LDFLAGS="-L${PREFIX}/lib -static" \
    CFLAGS="-static -Os -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "https://dev.yorhel.nl/download/ncdu-${NCDU_VERSION}.tar.gz" -O ncdu.tar.gz && \
    echo "${NCDU_SOURCE_SHA256}  ncdu.tar.gz" | sha256sum -c -

RUN tar xzf ncdu.tar.gz && \
    cd ncdu-${NCDU_VERSION} && \
    ./configure --prefix=/usr && \
    make -j"$(nproc)" LDFLAGS="-L${PREFIX}/lib -static" && \
    mkdir -p /out && \
    cp ncdu /out/ncdu && \
    strip /out/ncdu && \
    file /out/ncdu | grep -q "statically linked" && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG WGET_VERSION
ARG WGET_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Compiler only. OpenSSL and zlib come from the SHA256-pinned prefix.
RUN apk add --no-cache \
    build-base=0.5-r3

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static" \
    CFLAGS="-Os -fstack-protector-strong -D_FORTIFY_SOURCE=2"

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
    make -j"$(nproc)" SUBDIRS="lib src" LDFLAGS="-L${PREFIX}/lib -static" && \
    mkdir -p /out && \
    cp src/wget /out/wget && \
    strip /out/wget && \
    file /out/wget | grep -q "statically linked" && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

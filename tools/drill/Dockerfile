# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG LDNS_VERSION
ARG LDNS_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Compiler only. OpenSSL comes from the SHA256-pinned prefix.
RUN apk add --no-cache \
    build-base=0.5-r3 \
    linux-headers=6.6-r1

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib" \
    CFLAGS="-Os -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "https://nlnetlabs.nl/downloads/ldns/ldns-${LDNS_VERSION}.tar.gz" -O ldns.tar.gz && \
    echo "${LDNS_SOURCE_SHA256}  ldns.tar.gz" | sha256sum -c -

RUN tar xzf ldns.tar.gz && \
    cd ldns-${LDNS_VERSION} && \
    LIBS="-lcrypto -ldl -pthread" \
    ./configure \
        --prefix=/usr \
        --disable-shared \
        --enable-static \
        --with-drill \
        --with-ssl="${PREFIX}" \
        --disable-dane \
        --disable-dane-ta-usage \
        CFLAGS="-Os -fstack-protector-strong -D_FORTIFY_SOURCE=2" && \
    make -j"$(nproc)" && \
    cd drill && \
    ../libtool --tag=CC --mode=link gcc -all-static -s -Os \
        -o drill \
        chasetrace.lo dnssec.lo drill.lo drill_util.lo \
        error.lo root.lo securetrace.lo work.lo \
        ../compat/b64_pton.lo ../compat/b64_ntop.lo \
        ../libldns.la -L${PREFIX}/lib -lcrypto -ldl -pthread && \
    mkdir -p /out && \
    cp .libs/drill /out/drill 2>/dev/null || cp drill /out/drill && \
    file /out/drill | grep -q "statically linked" && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

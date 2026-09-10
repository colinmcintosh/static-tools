# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG JQ_VERSION
ARG JQ_SOURCE_SHA256
ARG TARGETARCH

RUN apk add --no-cache \
    build-base=0.5-r3

ENV CFLAGS="-Os -fPIE -ftls-model=local-exec -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LDFLAGS="-static-pie"

WORKDIR /src
RUN wget -q "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-${JQ_VERSION}.tar.gz" -O jq.tar.gz && \
    echo "${JQ_SOURCE_SHA256}  jq.tar.gz" | sha256sum -c -

RUN tar xzf jq.tar.gz && \
    cd jq-${JQ_VERSION} && \
    ./configure \
        --prefix=/usr \
        --disable-shared \
        --enable-static \
        --disable-docs \
        --disable-maintainer-mode \
        --with-oniguruma=builtin && \
    make -j"$(nproc)" && \
    ./libtool --tag=CC --mode=link gcc -static-pie -s -o jq \
        src/main.o libjq.la vendor/oniguruma/src/libonig.la -lm && \
    mkdir -p /out && \
    cp jq /out/jq 2>/dev/null || cp .libs/jq /out/jq && \
    strip /out/jq && \
    /out/jq --version && \
    ! readelf -l /out/jq | grep -q INTERP && \
    readelf -h /out/jq | grep -q 'Type:[[:space:]]*DYN' && \
    ! readelf -Wr /out/jq | awk '$3 ~ /^R_/ && $3 !~ /RELATIVE$/ { found=1 } END { exit found ? 0 : 1 }' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

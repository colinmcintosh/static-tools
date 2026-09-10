# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG JQ_VERSION
ARG JQ_SOURCE_SHA256
ARG TARGETARCH

RUN apk add --no-cache \
    build-base=0.5-r3

ENV CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
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
    make -j"$(nproc)" \
        LDFLAGS="-static-pie -all-static" \
        jq_LDFLAGS="-static-pie -all-static" && \
    mkdir -p /out && \
    cp jq /out/jq && \
    strip /out/jq && \
    ! readelf -l /out/jq | grep -q INTERP && \
    readelf -h /out/jq | grep -q 'Type:[[:space:]]*DYN' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

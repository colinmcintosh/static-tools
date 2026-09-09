# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG XXD_VERSION
ARG XXD_SOURCE_SHA256
ARG TARGETARCH

RUN apk add --no-cache \
    build-base=0.5-r3

ENV CFLAGS="-static -Os -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LDFLAGS="-static"

WORKDIR /src
RUN wget -q "https://github.com/xyproto/tinyxxd/archive/refs/tags/v${XXD_VERSION}.tar.gz" -O tinyxxd.tar.gz && \
    echo "${XXD_SOURCE_SHA256}  tinyxxd.tar.gz" | sha256sum -c -

RUN tar xzf tinyxxd.tar.gz && \
    cd tinyxxd-${XXD_VERSION} && \
    make -j"$(nproc)" && \
    mkdir -p /out && \
    cp tinyxxd /out/xxd && \
    strip /out/xxd && \
    file /out/xxd | grep -q "statically linked" && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

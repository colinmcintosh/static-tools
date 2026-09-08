# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG JQ_VERSION
ARG JQ_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

RUN apk add --no-cache \
    build-base=0.5-r3

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static" \
    CFLAGS="-Os -fstack-protector-strong -D_FORTIFY_SOURCE=2"

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
        LDFLAGS="-L${PREFIX}/lib -static -all-static" \
        jq_LDFLAGS="-static -all-static" && \
    mkdir -p /out && \
    cp jq /out/jq && \
    strip /out/jq && \
    file /out/jq | grep -q "statically linked" && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

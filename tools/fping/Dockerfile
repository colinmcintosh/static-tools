# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG FPING_VERSION
ARG FPING_SOURCE_SHA256
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
RUN wget -q "https://github.com/schweikert/fping/releases/download/v${FPING_VERSION}/fping-${FPING_VERSION}.tar.gz" -O fping.tar.gz && \
    echo "${FPING_SOURCE_SHA256}  fping.tar.gz" | sha256sum -c -

RUN tar xzf fping.tar.gz && \
    cd fping-${FPING_VERSION} && \
    ./configure --prefix=/usr && \
    make -j"$(nproc)" LDFLAGS="-L${PREFIX}/lib -static" && \
    mkdir -p /out && \
    cp src/fping /out/fping && \
    strip /out/fping && \
    file /out/fping | grep -q "statically linked" && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

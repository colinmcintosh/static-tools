# syntax=docker/dockerfile:1.7

ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG XXD_VERSION
ARG XXD_SOURCE_SHA256
ARG TARGETARCH

ENV CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LDFLAGS="-static-pie"

WORKDIR /src
RUN wget -q "https://github.com/xyproto/tinyxxd/archive/refs/tags/v${XXD_VERSION}.tar.gz" -O tinyxxd.tar.gz && \
    echo "${XXD_SOURCE_SHA256}  tinyxxd.tar.gz" | sha256sum -c -

RUN tar xzf tinyxxd.tar.gz && \
    cd tinyxxd-${XXD_VERSION} && \
    make -j"$(nproc)" CFLAGS="${CFLAGS} ${LDFLAGS}" && \
    mkdir -p /out && \
    cp tinyxxd /out/xxd && \
    strip /out/xxd && \
    ! readelf -l /out/xxd | grep -q INTERP && \
    readelf -h /out/xxd | grep -q 'Type:[[:space:]]*DYN' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

# syntax=docker/dockerfile:1.7

ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG TREE_VERSION
ARG TREE_SOURCE_URL
ARG TREE_SOURCE_SHA256
ARG TARGETARCH

ENV CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LDFLAGS="-static-pie"

WORKDIR /src
RUN wget -q "${TREE_SOURCE_URL}" -O unix-tree.tar.gz && \
    echo "${TREE_SOURCE_SHA256}  unix-tree.tar.gz" | sha256sum -c -

RUN tar xzf unix-tree.tar.gz && \
    cd unix-tree-${TREE_VERSION} && \
    make -j"$(nproc)" CC=gcc CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}" && \
    mkdir -p /out && \
    cp tree /out/tree && \
    strip /out/tree && \
    ! readelf -l /out/tree | grep -q INTERP && \
    readelf -h /out/tree | grep -q 'Type:[[:space:]]*DYN' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

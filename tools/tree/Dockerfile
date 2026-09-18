ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG TREE_VERSION
ARG TREE_SOURCE_URL
ARG TREE_SOURCE_SHA256

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
    strip /out/tree

FROM scratch AS export
COPY --from=builder /out/ /

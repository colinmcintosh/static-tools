ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG STRACE_VERSION
ARG STRACE_SOURCE_URL
ARG STRACE_SOURCE_SHA256
ARG TARGETARCH

ENV CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LDFLAGS="-static-pie"

WORKDIR /src
RUN wget -q "${STRACE_SOURCE_URL}" -O strace.tar.xz && \
    echo "${STRACE_SOURCE_SHA256}  strace.tar.xz" | sha256sum -c -

RUN tar xf strace.tar.xz && \
    cd strace-${STRACE_VERSION} && \
    ./configure \
        --prefix=/usr \
        --enable-mpers=no && \
    make -j"$(nproc)" LDFLAGS="-static-pie" && \
    mkdir -p /out && \
    cp src/strace /out/strace && \
    strip /out/strace && \
    ! readelf -l /out/strace | grep -q INTERP && \
    readelf -h /out/strace | grep -q 'Type:[[:space:]]*DYN' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

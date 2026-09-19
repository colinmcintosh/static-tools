ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG JQ_VERSION
ARG JQ_SOURCE_URL
ARG JQ_SOURCE_SHA256

ENV CFLAGS="-Os -fPIE -ftls-model=local-exec -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LDFLAGS="-static-pie"

WORKDIR /src
RUN wget -q "${JQ_SOURCE_URL}" -O jq.tar.gz && \
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
    { cp jq /out/jq 2>/dev/null || cp .libs/jq /out/jq; } && \
    strip /out/jq && \
    /out/jq --version

FROM scratch AS export
COPY --from=builder /out/ /

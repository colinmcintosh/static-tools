# syntax=docker/dockerfile:1.7

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS builder

ARG TARGETARCH
ARG PREFIX=/opt/st

# Compiler only (strip/file). OpenSSL comes from the SHA256-pinned prefix.
RUN apk add --no-cache \
    build-base=0.5-r3

COPY --from=deps / ${PREFIX}

WORKDIR /out
RUN cp "${PREFIX}/bin/openssl" /out/openssl && \
    strip /out/openssl && \
    file /out/openssl | grep -q "statically linked" && \
    sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

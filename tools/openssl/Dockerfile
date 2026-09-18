ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG TARGETARCH
ARG PREFIX=/opt/st

COPY --from=deps / ${PREFIX}

WORKDIR /out
RUN cp "${PREFIX}/bin/openssl" /out/openssl && \
    strip /out/openssl && \
    ! readelf -l /out/openssl | grep -q INTERP && \
    readelf -h /out/openssl | grep -q 'Type:[[:space:]]*DYN' && \
    sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

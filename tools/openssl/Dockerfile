ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG PREFIX=/opt/st

COPY --from=deps / ${PREFIX}

WORKDIR /out
RUN cp "${PREFIX}/bin/openssl" /out/openssl && \
    strip /out/openssl

FROM scratch AS export
COPY --from=builder /out/ /

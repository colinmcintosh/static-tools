ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG WHOIS_VERSION
ARG WHOIS_SOURCE_URL
ARG WHOIS_SOURCE_SHA256
ARG TARGETARCH

# musl never defines __GLIBC__, so upstream's config.h never sets
# HAVE_GETOPT_LONG and whois.c falls back to plain getopt(), which cannot
# parse "--version"/"--help"/long RIPE flags at all (musl still implements
# getopt_long(3) as a GNU extension; upstream just never detects it here).
# Force it on so long options work.
ENV CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2 -DHAVE_GETOPT_LONG" \
    LDFLAGS="-static-pie"

WORKDIR /src
RUN wget -q "${WHOIS_SOURCE_URL}" -O whois.tar.gz && \
    echo "${WHOIS_SOURCE_SHA256}  whois.tar.gz" | sha256sum -c -

# No pkg-config in the builder image and no shared deps prefix linked, so
# upstream's Makefile can't find libidn2/libidn and IDN support is simply
# left out: this is a plain WHOIS/RDAP client without internationalized
# domain name support. `make whois` builds only the whois client, not
# mkpasswd (needs libcrypt) or po (needs gettext tooling).
RUN tar xzf whois.tar.gz && \
    cd whois-${WHOIS_VERSION} && \
    make -j"$(nproc)" whois && \
    mkdir -p /out && \
    cp whois /out/whois && \
    strip /out/whois && \
    /out/whois --version && \
    ! readelf -l /out/whois | grep -q INTERP && \
    readelf -h /out/whois | grep -q 'Type:[[:space:]]*DYN' && \
    ! readelf -Wr /out/whois | awk '$3 ~ /^R_/ && $3 !~ /RELATIVE$/ { found=1 } END { exit found ? 0 : 1 }' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

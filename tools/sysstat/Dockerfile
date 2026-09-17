# syntax=docker/dockerfile:1.7

ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG SYSSTAT_VERSION
ARG SYSSTAT_SOURCE_SHA256
ARG TARGETARCH

# Pure libc + /proc parsing: nothing from the shared deps prefix is needed.
ENV CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fno-tree-slp-vectorize" \
    LDFLAGS="-static-pie"

# sar live-samples by exec'ing a separate sadc. Upstream only looks at the
# compile-time SADC_PATH and then PATH, so a same-directory `./sar` would
# miss a sibling sadc and could pick up a host collector. This insert tries
# dirname(/proc/self/exe)/sadc first (see sadc-sibling.inc).
COPY inject-sadc-sibling.sh sadc-sibling.inc /tmp/

WORKDIR /src
RUN wget -q "https://github.com/sysstat/sysstat/archive/refs/tags/v${SYSSTAT_VERSION}.tar.gz" -O sysstat.tar.gz && \
    echo "${SYSSTAT_SOURCE_SHA256}  sysstat.tar.gz" | sha256sum -c -

# sysstat ships a pre-generated ./configure (no autoreconf/bootstrap step).
# --disable-sensors/--disable-pcp drop lm-sensors/PCP support. sadc is the
# only sysstat binary that *can* link libsensors; we still disable that so
# the shipped collector stays libc-only. sadf is the only one that links
# PCP and is not built. --disable-nls drops gettext. The rest skip
# cron/systemd/man/doc install machinery that `make mpstat iostat pidstat
# sar sadc` never touches anyway, since it builds only those 5 targets
# (and their shared objects/archives), not `make install` or the default
# `all` target (which also builds sadf, tapestat, cifsiostat and locales).
#
# CFLAGS is re-passed on the `make` command line, not just to configure:
# Makefile.in unconditionally appends "-Wall -pipe -O2 -fno-tree-slp-vectorize"
# to CFLAGS, but only when CFLAGS was *not* set on the make command line
# (verified locally: a plain environment/configure-substituted CFLAGS still
# gets that suffix appended, silently upgrading -Os to -O2; a make-command-
# line CFLAGS fully overrides it with no append, per GNU Make's variable
# precedence rules). -fno-tree-slp-vectorize is kept regardless because
# upstream added it as a real bug workaround, not a style choice (CHANGES:
# "Turn off gcc's tree-slp-vectorize option which was making sadf crash");
# the vulnerable code (rd_stats.c, common.c, ...) is shared with the 5
# binaries built here.
RUN set -eu && \
    tar xzf sysstat.tar.gz && \
    cd sysstat-${SYSSTAT_VERSION} && \
    sh /tmp/inject-sadc-sibling.sh sar.c /tmp/sadc-sibling.inc && \
    ./configure \
        --disable-nls \
        --disable-sensors \
        --disable-pcp \
        --disable-automated-sar-reporting \
        --disable-documentation \
        --disable-compress-manpg \
        CFLAGS="${CFLAGS}" \
        LDFLAGS="${LDFLAGS}" && \
    make -j"$(nproc)" CFLAGS="${CFLAGS}" mpstat iostat pidstat sar sadc && \
    for bin in mpstat iostat pidstat sar sadc; do \
        ! readelf -l "${bin}" | grep -q INTERP; \
        readelf -h "${bin}" | grep -q 'Type:[[:space:]]*DYN'; \
    done && \
    mkdir -p /out && \
    cp mpstat iostat pidstat sar sadc /out/ && \
    strip /out/mpstat /out/iostat /out/pidstat /out/sar /out/sadc && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

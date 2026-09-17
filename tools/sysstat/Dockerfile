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

WORKDIR /src
RUN wget -q "https://github.com/sysstat/sysstat/archive/refs/tags/v${SYSSTAT_VERSION}.tar.gz" -O sysstat.tar.gz && \
    echo "${SYSSTAT_SOURCE_SHA256}  sysstat.tar.gz" | sha256sum -c -

# sysstat ships a pre-generated ./configure (no autoreconf/bootstrap step).
# --disable-sensors/--disable-pcp drop lm-sensors/PCP support (unused by the
# 4 binaries built here regardless: sadc is the only sysstat binary that
# links libsensors, and sadf is the only one that links PCP). --disable-nls
# drops gettext. The rest skip cron/systemd/man/doc install machinery that
# `make mpstat iostat pidstat sar` never touches anyway, since it builds
# only those 4 targets (and their shared objects/archives), not `make
# install` or the default `all` target (which also builds sadc, sadf,
# tapestat, cifsiostat and locales).
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
# the vulnerable code (rd_stats.c, common.c, ...) is shared with the 4
# binaries built here.
RUN tar xzf sysstat.tar.gz && \
    cd sysstat-${SYSSTAT_VERSION} && \
    ./configure \
        --disable-nls \
        --disable-sensors \
        --disable-pcp \
        --disable-automated-sar-reporting \
        --disable-documentation \
        --disable-compress-manpg \
        CFLAGS="${CFLAGS}" \
        LDFLAGS="${LDFLAGS}" && \
    make -j"$(nproc)" CFLAGS="${CFLAGS}" mpstat iostat pidstat sar && \
    ! readelf -l mpstat | grep -q INTERP && \
    readelf -h mpstat | grep -q 'Type:[[:space:]]*DYN' && \
    ! readelf -l iostat | grep -q INTERP && \
    readelf -h iostat | grep -q 'Type:[[:space:]]*DYN' && \
    ! readelf -l pidstat | grep -q INTERP && \
    readelf -h pidstat | grep -q 'Type:[[:space:]]*DYN' && \
    ! readelf -l sar | grep -q INTERP && \
    readelf -h sar | grep -q 'Type:[[:space:]]*DYN' && \
    mkdir -p /out && \
    cp mpstat iostat pidstat sar /out/ && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

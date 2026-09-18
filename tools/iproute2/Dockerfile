ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG IPROUTE2_VERSION
ARG IPROUTE2_SOURCE_URL
ARG IPROUTE2_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Additional context `deps` is the exported static prefix (see deps/Dockerfile).
COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static-pie" \
    CFLAGS="-Os -fPIE -ftls-model=local-exec -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "${IPROUTE2_SOURCE_URL}" -O iproute2.tar.gz && \
    echo "${IPROUTE2_SOURCE_SHA256}  iproute2.tar.gz" | sha256sum -c -

# iproute2 ships its own hand-rolled ./configure (not autoconf): it probes
# for optional libs via pkg-config and writes config.mk, then a plain make
# reads config.mk and builds. Our PKG_CONFIG_PATH only exposes the shared
# deps prefix, which has no libmnl/libelf/libbpf/libselinux/libtirpc/xtables
# .pc files, so configure auto-disables all of them and iproute2 falls back
# to its own internal netlink helpers -- ip and ss do not require any of
# those. libcap *is* in the shared deps prefix, so it gets picked up (ip
# uses it for capability handling in netns exec); that is an existing
# shared dep, not something new added here. "/usr/include" matches the
# KERNEL_INCLUDE default that the top-level Makefile's self-configuring
# config.mk rule would pass a plain `make` anyway.
#
# SHARED_LIBS=n switches the `ip` link from dlopen()-ing iplink_*.so
# extension modules to iproute2's built-in "static-syms" stub
# (include/dlfcn.h under NO_SHARED_LIBS) -- a static binary cannot dlopen()
# anything, so this is the standard, well-tested way upstream supports a
# monolithic static `ip`.
#
# Only the lib, ip, and misc subdirs are built (SUBDIRS=): ip and ss don't
# need tc/bridge/netem/genl, and man needs xmlto/docbook which the frozen
# builder image does not have.
RUN tar xzf iproute2.tar.gz && \
    cd iproute2-${IPROUTE2_VERSION} && \
    ./configure /usr/include && \
    make -j"$(nproc)" SUBDIRS="lib ip misc" SHARED_LIBS=n && \
    mkdir -p /out && \
    cp ip/ip misc/ss /out/ && \
    strip /out/ip /out/ss && \
    /out/ip -V && \
    /out/ss --version && \
    ! readelf -l /out/ip | grep -q INTERP && \
    readelf -h /out/ip | grep -q 'Type:[[:space:]]*DYN' && \
    ! readelf -l /out/ss | grep -q INTERP && \
    readelf -h /out/ss | grep -q 'Type:[[:space:]]*DYN' && \
    ! readelf -Wr /out/ip | awk '$3 ~ /^R_/ && $3 !~ /RELATIVE$/ { found=1 } END { exit found ? 0 : 1 }' && \
    ! readelf -Wr /out/ss | awk '$3 ~ /^R_/ && $3 !~ /RELATIVE$/ { found=1 } END { exit found ? 0 : 1 }' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

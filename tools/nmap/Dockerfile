# syntax=docker/dockerfile:1.7

ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG NMAP_VERSION
ARG NMAP_SOURCE_URL
ARG NMAP_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Additional context `deps` is the exported static prefix (see deps/Dockerfile).
COPY --from=deps / ${PREFIX}

# nmap's core sources are C++ (.cc); its `.cc.o` rule only honors CXXFLAGS,
# not CFLAGS, so both must carry the hardening/PIE flags or the C++ objects
# get built with autoconf's plain "-g -O2" default and won't link -static-pie.
ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static-pie" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    CXXFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "${NMAP_SOURCE_URL}" -O nmap.tar.bz2 && \
    echo "${NMAP_SOURCE_SHA256}  nmap.tar.bz2" | sha256sum -c -

# Nmap's OS-detection engine (FPEngine.cc/FPModel.cc) unconditionally calls
# into liblinear for its fingerprint classifier -- configure.ac has no real
# "disable" for it (--without-liblinear's "no" falls through to the generic
# `*)` case, which treats "no" as a literal directory name rather than a
# flag), so we point it at the copy already bundled in this verified tarball
# instead of vendoring a new dependency ourselves. libdnet-stripped is always
# the bundled copy too (nmap's documented default, no disable exists). The
# shared deps/ prefix has no libpcre2, so it also uses the bundled copy.
# zlib, libpcap, and OpenSSL reuse the shared static prefix. NSE (liblua),
# Nping, Ndiff, Zenmap, Ncat, and libssh2 (used only by NSE's ssh library)
# are all disabled: Ncat already has its own tool/ncat build in this repo,
# and the rest are GUI/scripting/companion tools this static build of the
# scanner itself doesn't need.
# Upstream oversight in 7.991: nmap_free_mem() in nmap.cc calls close_nse()
# with no `#ifndef NOLUA` guard, unlike every other NSE call site in the same
# file (and unlike the equivalent call in NmapOps.cc, which is guarded). With
# --without-liblua, nse_main.h/nse_main.cc are excluded, so this one call
# fails to compile. Guard it the same way the rest of the file already does;
# this only changes behavior for the --without-liblua path, which has nothing
# for close_nse() to clean up in the first place.
RUN tar xjf nmap.tar.bz2 && \
    cd nmap-${NMAP_VERSION} && \
    grep -q '^  close_nse();$' nmap.cc && \
    sed -i 's/^  close_nse();$/#ifndef NOLUA\n  close_nse();\n#endif/' nmap.cc

RUN cd nmap-${NMAP_VERSION} && \
    ./configure \
        --prefix=/usr \
        --disable-shared \
        --without-zenmap \
        --without-ndiff \
        --without-nping \
        --without-ncat \
        --without-liblua \
        --without-libssh2 \
        --with-liblinear=included \
        --with-libpcre=included \
        --with-libz="${PREFIX}" \
        --with-openssl="${PREFIX}" \
        --with-libpcap="${PREFIX}" && \
    make -j"$(nproc)" nmap && \
    mkdir -p /out && \
    cp nmap /out/nmap && \
    cp nmap-services /out/nmap-services && \
    strip /out/nmap && \
    ! readelf -l /out/nmap | grep -q INTERP && \
    readelf -h /out/nmap | grep -q 'Type:[[:space:]]*DYN' && \
    ! readelf -Wr /out/nmap | awk '$3 ~ /^R_/ && $3 !~ /RELATIVE$/ { found=1 } END { exit found ? 0 : 1 }' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

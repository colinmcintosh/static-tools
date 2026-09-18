# syntax=docker/dockerfile:1.7

# Build a shared static prefix from SHA256-pinned upstream tarballs.
# The compiler comes from the digest-pinned builder image; C libraries
# come from source. Do not apk add here.

ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG TARGETARCH
ARG PREFIX=/opt/st

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib" \
    CFLAGS="-Os -std=gnu17 -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src

# --- perl (OpenSSL Configure) ---
ARG PERL_VERSION
ARG PERL_URL
ARG PERL_SHA256
RUN wget -q "${PERL_URL}" -O perl.tar.gz && \
    echo "${PERL_SHA256}  perl.tar.gz" | sha256sum -c - && \
    tar xzf perl.tar.gz && \
    cd perl-${PERL_VERSION} && \
    ./Configure -des \
        -Dprefix="${PREFIX}" \
        -Dman1dir=none \
        -Dman3dir=none && \
    make -j"$(nproc)" && \
    make install && \
    cd /src && rm -rf perl.tar.gz perl-${PERL_VERSION}

# --- pkg-config ---
ARG PKG_CONFIG_VERSION
ARG PKG_CONFIG_URL
ARG PKG_CONFIG_SHA256
RUN wget -q "${PKG_CONFIG_URL}" -O pkg-config.tar.gz && \
    echo "${PKG_CONFIG_SHA256}  pkg-config.tar.gz" | sha256sum -c - && \
    tar xzf pkg-config.tar.gz && \
    cd pkg-config-${PKG_CONFIG_VERSION} && \
    ./configure \
        --prefix="${PREFIX}" \
        --with-internal-glib \
        --disable-host-tool \
        --disable-shared && \
    make -j"$(nproc)" && \
    make install && \
    cd /src && rm -rf pkg-config.tar.gz pkg-config-${PKG_CONFIG_VERSION}

# --- zlib ---
ARG ZLIB_VERSION
ARG ZLIB_URL
ARG ZLIB_SHA256
RUN wget -q "${ZLIB_URL}" -O zlib.tar.gz && \
    echo "${ZLIB_SHA256}  zlib.tar.gz" | sha256sum -c - && \
    tar xzf zlib.tar.gz && \
    cd zlib-${ZLIB_VERSION} && \
    ./configure --prefix="${PREFIX}" --static && \
    make -j"$(nproc)" && \
    make install && \
    cd /src && rm -rf zlib.tar.gz zlib-${ZLIB_VERSION}

# OpenSSL Configure -static emits a static ET_EXEC CLI; -static-pie on
# Configure produced a dynamic PIE instead. After install_sw we relink
# the CLI as a static PIE so the shipped openssl matches the other tools.
# --- openssl ---
ARG OPENSSL_VERSION
ARG OPENSSL_URL
ARG OPENSSL_SHA256
RUN wget -q "${OPENSSL_URL}" -O openssl.tar.gz && \
    echo "${OPENSSL_SHA256}  openssl.tar.gz" | sha256sum -c - && \
    tar xzf openssl.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    case "${TARGETARCH}" in \
        amd64) OPENSSL_TARGET=linux-x86_64 ;; \
        arm64) OPENSSL_TARGET=linux-aarch64 ;; \
        *) echo "unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
    esac && \
    ./Configure \
        --prefix="${PREFIX}" \
        --openssldir=/etc/ssl \
        --libdir=lib \
        no-shared \
        no-dso \
        no-tests \
        no-docs \
        no-zlib \
        enable-pie \
        -static \
        "${OPENSSL_TARGET}" && \
    make -j"$(nproc)" && \
    make install_sw && \
    cc -static-pie -s -o "${PREFIX}/bin/openssl" \
        apps/*.o apps/lib/*.o \
        -Wl,--start-group apps/libapps.a libssl.a libcrypto.a -Wl,--end-group \
        -ldl -pthread && \
    readelf -l "${PREFIX}/bin/openssl" | grep -q INTERP && { echo "openssl CLI is not static"; exit 1; } || true && \
    readelf -h "${PREFIX}/bin/openssl" | grep -q 'Type:[[:space:]]*DYN' && \
    cd /src && rm -rf openssl.tar.gz openssl-${OPENSSL_VERSION}

# --- nghttp2 (library only) ---
ARG NGHTTP2_VERSION
ARG NGHTTP2_URL
ARG NGHTTP2_SHA256
RUN wget -q "${NGHTTP2_URL}" -O nghttp2.tar.gz && \
    echo "${NGHTTP2_SHA256}  nghttp2.tar.gz" | sha256sum -c - && \
    tar xzf nghttp2.tar.gz && \
    cd nghttp2-${NGHTTP2_VERSION} && \
    ./configure \
        --prefix="${PREFIX}" \
        --enable-lib-only \
        --enable-static \
        --disable-shared \
        --disable-examples \
        --disable-failmalloc && \
    make -j"$(nproc)" && \
    make install && \
    cd /src && rm -rf nghttp2.tar.gz nghttp2-${NGHTTP2_VERSION}

# --- ncurses (wide-char static) ---
ARG NCURSES_VERSION
ARG NCURSES_URL
ARG NCURSES_SHA256
RUN wget -q "${NCURSES_URL}" -O ncurses.tar.gz && \
    echo "${NCURSES_SHA256}  ncurses.tar.gz" | sha256sum -c - && \
    tar xzf ncurses.tar.gz && \
    cd ncurses-${NCURSES_VERSION} && \
    ./configure \
        --prefix="${PREFIX}" \
        --without-shared \
        --with-normal \
        --without-debug \
        --without-ada \
        --without-cxx \
        --without-cxx-binding \
        --enable-widec \
        --with-pkg-config-libdir="${PREFIX}/lib/pkgconfig" \
        --enable-pc-files && \
    make -j"$(nproc)" && \
    make install && \
    cd /src && rm -rf ncurses.tar.gz ncurses-${NCURSES_VERSION}

# --- libcap ---
ARG LIBCAP_VERSION
ARG LIBCAP_URL
ARG LIBCAP_SHA256
RUN wget -q "${LIBCAP_URL}" -O libcap.tar.gz && \
    echo "${LIBCAP_SHA256}  libcap.tar.gz" | sha256sum -c - && \
    tar xzf libcap.tar.gz && \
    cd libcap-${LIBCAP_VERSION} && \
    make -C libcap prefix="${PREFIX}" lib=lib SHARED=no GOLANG=no && \
    make -C libcap prefix="${PREFIX}" lib=lib SHARED=no GOLANG=no install && \
    cd /src && rm -rf libcap.tar.gz libcap-${LIBCAP_VERSION}

# --- libuv ---
ARG LIBUV_VERSION
ARG LIBUV_URL
ARG LIBUV_SHA256
RUN wget -q "${LIBUV_URL}" -O libuv.tar.gz && \
    echo "${LIBUV_SHA256}  libuv.tar.gz" | sha256sum -c - && \
    tar xzf libuv.tar.gz && \
    cd libuv-v${LIBUV_VERSION} && \
    ./autogen.sh && \
    ./configure \
        --prefix="${PREFIX}" \
        --disable-shared \
        --enable-static && \
    make -j"$(nproc)" && \
    make install && \
    cd /src && rm -rf libuv.tar.gz libuv-v${LIBUV_VERSION}

# --- userspace-rcu ---
ARG URCU_VERSION
ARG URCU_URL
ARG URCU_SHA256
RUN wget -q "${URCU_URL}" -O urcu.tar.bz2 && \
    echo "${URCU_SHA256}  urcu.tar.bz2" | sha256sum -c - && \
    tar xjf urcu.tar.bz2 && \
    cd userspace-rcu-${URCU_VERSION} && \
    ./configure \
        --prefix="${PREFIX}" \
        --disable-shared \
        --enable-static && \
    make -j"$(nproc)" && \
    make install && \
    cd /src && rm -rf urcu.tar.bz2 userspace-rcu-${URCU_VERSION}

# --- jemalloc ---
ARG JEMALLOC_VERSION
ARG JEMALLOC_URL
ARG JEMALLOC_SHA256
RUN wget -q "${JEMALLOC_URL}" -O jemalloc.tar.bz2 && \
    echo "${JEMALLOC_SHA256}  jemalloc.tar.bz2" | sha256sum -c - && \
    tar xjf jemalloc.tar.bz2 && \
    cd jemalloc-${JEMALLOC_VERSION} && \
    ./configure \
        --prefix="${PREFIX}" \
        --disable-shared \
        --enable-static && \
    make -j"$(nproc)" && \
    make install && \
    cd /src && rm -rf jemalloc.tar.bz2 jemalloc-${JEMALLOC_VERSION}

# --- libpcap ---
ARG LIBPCAP_VERSION
ARG LIBPCAP_URL
ARG LIBPCAP_SHA256
RUN wget -q "${LIBPCAP_URL}" -O libpcap.tar.gz && \
    echo "${LIBPCAP_SHA256}  libpcap.tar.gz" | sha256sum -c - && \
    tar xzf libpcap.tar.gz && \
    cd libpcap-${LIBPCAP_VERSION} && \
    ./configure \
        --prefix="${PREFIX}" \
        --disable-shared \
        --enable-static \
        --disable-usb \
        --disable-bluetooth \
        --disable-dbus \
        --disable-rdma \
        --without-libnl && \
    make -j"$(nproc)" && \
    make install && \
    cd /src && rm -rf libpcap.tar.gz libpcap-${LIBPCAP_VERSION}

# --- xxhash ---
ARG XXHASH_VERSION
ARG XXHASH_URL
ARG XXHASH_SHA256
RUN wget -q "${XXHASH_URL}" -O xxhash.tar.gz && \
    echo "${XXHASH_SHA256}  xxhash.tar.gz" | sha256sum -c - && \
    tar xzf xxhash.tar.gz && \
    cd xxHash-${XXHASH_VERSION} && \
    make PREFIX="${PREFIX}" DISPATCH=0 libxxhash.a && \
    make PREFIX="${PREFIX}" DISPATCH=0 install && \
    rm -f "${PREFIX}/lib/libxxhash.so" "${PREFIX}/lib/libxxhash.so."* && \
    cd /src && rm -rf xxhash.tar.gz xxHash-${XXHASH_VERSION}

# --- zstd (library only) ---
ARG ZSTD_VERSION
ARG ZSTD_URL
ARG ZSTD_SHA256
RUN wget -q "${ZSTD_URL}" -O zstd.tar.gz && \
    echo "${ZSTD_SHA256}  zstd.tar.gz" | sha256sum -c - && \
    tar xzf zstd.tar.gz && \
    cd zstd-${ZSTD_VERSION} && \
    make -C lib PREFIX="${PREFIX}" BUILD_SHARED=0 install-static install-includes install-pc && \
    cd /src && rm -rf zstd.tar.gz zstd-${ZSTD_VERSION}

# --- lz4 (library only) ---
ARG LZ4_VERSION
ARG LZ4_URL
ARG LZ4_SHA256
RUN wget -q "${LZ4_URL}" -O lz4.tar.gz && \
    echo "${LZ4_SHA256}  lz4.tar.gz" | sha256sum -c - && \
    tar xzf lz4.tar.gz && \
    cd lz4-${LZ4_VERSION} && \
    make -C lib PREFIX="${PREFIX}" BUILD_SHARED=no install && \
    rm -f "${PREFIX}/lib/liblz4.so" "${PREFIX}/lib/liblz4.so."* && \
    cd /src && rm -rf lz4.tar.gz lz4-${LZ4_VERSION}

# Export only what tool builds need: static libs, headers, pkg-config
# files, and the two binaries tools actually invoke (openssl CLI and
# pkg-config). Drop perl, terminfo, man pages, and the rest of bin/.
RUN export_root=/export && \
    mkdir -p \
        "${export_root}/bin" \
        "${export_root}/lib/pkgconfig" \
        "${export_root}/include" && \
    cp "${PREFIX}/bin/openssl" "${PREFIX}/bin/pkg-config" "${export_root}/bin/" && \
    cp "${PREFIX}/lib/"*.a "${export_root}/lib/" && \
    cp "${PREFIX}/lib/pkgconfig/"*.pc "${export_root}/lib/pkgconfig/" && \
    rm -f "${export_root}/lib/pkgconfig/perl.pc" && \
    cp -a "${PREFIX}/include/." "${export_root}/include/" && \
    test -f "${export_root}/lib/libssl.a" && \
    test -f "${export_root}/lib/libcrypto.a" && \
    test -f "${export_root}/lib/libz.a" && \
    test -f "${export_root}/lib/libnghttp2.a" && \
    test -f "${export_root}/lib/libncursesw.a" && \
    test -f "${export_root}/lib/libcap.a" && \
    test -f "${export_root}/lib/libuv.a" && \
    test -f "${export_root}/lib/liburcu.a" && \
    test -f "${export_root}/lib/libjemalloc.a" && \
    test -f "${export_root}/lib/libpcap.a" && \
    test -f "${export_root}/lib/libxxhash.a" && \
    test -f "${export_root}/lib/libzstd.a" && \
    test -f "${export_root}/lib/liblz4.a" && \
    test -x "${export_root}/bin/openssl" && \
    test -x "${export_root}/bin/pkg-config" && \
    test ! -d "${export_root}/share/terminfo" && \
    ! grep -l '^#!.*perl' "${export_root}/bin"/*

FROM scratch AS export
COPY --from=builder /export /

ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG IPMITOOL_VERSION
ARG IPMITOOL_SOURCE_URL
ARG IPMITOOL_SOURCE_SHA256
ARG PREFIX=/opt/st

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LIBS="-lcrypto -ldl -lpthread"

WORKDIR /src
RUN wget -q "${IPMITOOL_SOURCE_URL}" -O ipmitool.tar.gz && \
    echo "${IPMITOOL_SOURCE_SHA256}  ipmitool.tar.gz" | sha256sum -c -

# The GitHub tag archive has no generated configure script.
# ipmishell needs readline, which the shared prefix does not build (socat
# disables readline for the same reason), so the shell is off.
# Linux interfaces stay on. Solaris, FreeIPMI, and D-Bus stay off so the
# link does not look for libraries this prefix does not ship.
# LDFLAGS stays plain for configure's probes, then -static-pie is applied
# to the real link, matching less.
RUN tar xzf ipmitool.tar.gz && \
    cd "ipmitool-IPMITOOL_$(echo "${IPMITOOL_VERSION}" | tr '.' '_')" && \
    ./bootstrap && \
    ./configure \
        --prefix=/usr \
        --disable-shared \
        --enable-static \
        --enable-intf-lan \
        --enable-intf-lanplus \
        --enable-intf-open \
        --enable-intf-serial \
        --enable-intf-usb \
        --disable-ipmishell \
        --disable-intf-free \
        --disable-intf-imb \
        --disable-intf-lipmi \
        --disable-intf-bmc \
        --disable-intf-dbus \
        --disable-intf-dummy \
        --disable-internal-md5 \
        --with-kerneldir=/usr \
        CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
        LDFLAGS="-L${PREFIX}/lib" && \
    make -j"$(nproc)" LDFLAGS="-L${PREFIX}/lib -static-pie" && \
    mkdir -p /out && \
    if [ -f src/.libs/ipmitool ]; then \
        cp src/.libs/ipmitool /out/ipmitool; \
    else \
        cp src/ipmitool /out/ipmitool; \
    fi && \
    strip /out/ipmitool

FROM scratch AS export
COPY --from=builder /out/ /

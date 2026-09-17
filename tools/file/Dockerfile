# syntax=docker/dockerfile:1.7

ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG FILE_VERSION
ARG FILE_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib -static-pie" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "https://astron.com/pub/file/file-${FILE_VERSION}.tar.gz" -O file.tar.gz && \
    echo "${FILE_SOURCE_SHA256}  file.tar.gz" | sha256sum -c -

# magic.mgc is required at runtime. libmagic does not search next to the binary;
# consumers must pass -m magic.mgc-<arch> or set MAGIC=. Keep shipping magic.mgc.
RUN tar xzf file.tar.gz && \
    cd file-${FILE_VERSION} && \
    ./configure \
        --prefix=/usr \
        --disable-shared \
        --enable-static \
        --enable-zlib \
        --disable-bzlib \
        --disable-xzlib \
        --disable-zstdlib \
        --disable-lzlib \
        --disable-libseccomp && \
    make -j"$(nproc)" && \
    mkdir -p /out && \
    gcc -static-pie -o /out/file src/file.o src/seccomp.o src/landlock.o src/.libs/libmagic.a -L${PREFIX}/lib -lz -lm && \
    cp magic/magic.mgc /out/magic.mgc && \
    strip /out/file && \
    ! readelf -l /out/file | grep -q INTERP && \
    readelf -h /out/file | grep -q 'Type:[[:space:]]*DYN' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

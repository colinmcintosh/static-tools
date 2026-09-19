ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG LSOF_VERSION
ARG LSOF_SOURCE_URL
ARG LSOF_SOURCE_SHA256

# No shared deps prefix: lsof only needs libc and Linux /proc parsing.
ENV CFLAGS="-Os -fPIE -ftls-model=local-exec -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    LDFLAGS="-static-pie"

WORKDIR /src
RUN wget -q "${LSOF_SOURCE_URL}" -O lsof.tar.gz && \
    echo "${LSOF_SOURCE_SHA256}  lsof.tar.gz" | sha256sum -c -

# lsof-org/lsof ships a pre-generated Autotools `configure`, not the old
# Purdue `Configure` (capital C) script. `configure` auto-detects the
# "linux" dialect from uname/config.guess, so no dialect argument is
# needed. `--disable-liblsof` skips the optional liblsof.so (the `lsof`
# binary compiles its sources in directly, see Makefile.am, so it does
# not need liblsof); `--without-libtirpc`/`--without-selinux` turn off
# the only two optional external-library features rather than pulling
# them in. Build only the `lsof` binary target: the default `all` target
# also wants `lsof.man` via `soelim`, a groff tool this frozen toolchain
# does not have (and must not gain via apk).
RUN tar xzf lsof.tar.gz && \
    cd lsof-${LSOF_VERSION} && \
    ./configure \
        --prefix=/usr \
        --disable-shared \
        --enable-static \
        --disable-liblsof \
        --without-libtirpc \
        --without-selinux && \
    make -j"$(nproc)" lsof && \
    mkdir -p /out && \
    cp lsof /out/lsof && \
    strip /out/lsof && \
    /out/lsof -v

FROM scratch AS export
COPY --from=builder /out/ /

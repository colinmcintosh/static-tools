ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG LIBCAP_VERSION
ARG LIBCAP_URL
ARG LIBCAP_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

# Additional context `deps` is the exported static prefix (see deps/Dockerfile).
# It already builds libcap.a (and libpsx.a) from this exact same pinned,
# SHA256-verified tarball, so getcap/setcap link against that instead of
# rebuilding the library a second time.
COPY --from=deps / ${PREFIX}

ENV CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "${LIBCAP_URL}" -O libcap.tar.gz && \
    echo "${LIBCAP_SHA256}  libcap.tar.gz" | sha256sum -c -

# Build only progs/getcap.c and progs/setcap.c via libcap's own
# progs/Makefile, not the top-level `make all` (which would also pull in
# capsh, pam_cap, the Go bindings, and tests -- none of which we want or
# have build-time dependencies for; PAM headers and gperf are not in the
# builder toolchain).
#
# DEPS and LIBCAPLIB are pointed at the prefix's already-built static
# libcap.a so progs/Makefile's `../libcap/libcap.a` prerequisite resolves
# to that existing file instead of triggering an in-tree rebuild of
# libcap/ from source. getcap and setcap only need libcap: psx_load_syscalls()
# is weakly defined inside libcap itself (libcap/cap_syscalls.c), so
# libpsx.a is only pulled in by programs that explicitly link -lpsx for
# multi-threaded POSIX semantics -- upstream's own progs/Makefile does not
# do that for getcap/setcap/getpcaps either (only $(LIBCAPLIB), i.e. -lcap,
# is used to link them).
RUN tar xzf libcap.tar.gz && \
    cd libcap-${LIBCAP_VERSION}/progs && \
    make -j"$(nproc)" \
        CC=cc \
        CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
        LDFLAGS="-static-pie -s" \
        DEPS="${PREFIX}/lib/libcap.a" \
        LIBCAPLIB="-L${PREFIX}/lib -lcap" \
        getcap setcap && \
    ! readelf -l getcap | grep -q INTERP && \
    readelf -h getcap | grep -q 'Type:[[:space:]]*DYN' && \
    ! readelf -l setcap | grep -q INTERP && \
    readelf -h setcap | grep -q 'Type:[[:space:]]*DYN' && \
    mkdir -p /out && \
    cp getcap setcap /out/ && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

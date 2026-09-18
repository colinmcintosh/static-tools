# syntax=docker/dockerfile:1.7

ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG LESS_VERSION
ARG LESS_SOURCE_URL
ARG LESS_SOURCE_SHA256
ARG TARGETARCH
ARG PREFIX=/opt/st

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include -I${PREFIX}/include/ncursesw" \
    LDFLAGS="-L${PREFIX}/lib" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2"

WORKDIR /src
RUN wget -q "${LESS_SOURCE_URL}" -O less.tar.gz && \
    echo "${LESS_SOURCE_SHA256}  less.tar.gz" | sha256sum -c -

# less's own configure (not autoconf-generated boilerplate, but the same
# AC_CHECK_LIB/AC_LINK_IFELSE machinery) probes for a terminal library by
# trying, in order: tinfo, tinfow, xcurses, ncursesw, ncurses, curses,
# curses+termcap, termcap, termlib. The shared prefix only ships
# libncursesw.a (built with terminfo compiled in, no separate libtinfo),
# so it lands on "ncursesw" and links -lncursesw. --with-regex=posix pins
# regex to libc's regcomp/regexec so we don't need to vendor PCRE2.
# LDFLAGS is deliberately plain (no -static-pie) for configure's own probe
# links, then re-supplied at `make` time for the real static-pie link of
# the `less` binary only (lesskey/lessecho are out of scope here).
RUN tar xzf less.tar.gz && \
    cd less-${LESS_VERSION} && \
    ./configure \
        --with-regex=posix \
        CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
        LDFLAGS="-L${PREFIX}/lib" && \
    make -j"$(nproc)" LDFLAGS="-L${PREFIX}/lib -static-pie" less && \
    mkdir -p /out && \
    cp less /out/less && \
    strip /out/less && \
    /out/less --version && \
    ! readelf -l /out/less | grep -q INTERP && \
    readelf -h /out/less | grep -q 'Type:[[:space:]]*DYN' && \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS export
COPY --from=builder /out/ /

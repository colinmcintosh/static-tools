ARG BUILDER_IMAGE
ARG BUILDER_DIGEST

FROM ${BUILDER_IMAGE}@${BUILDER_DIGEST} AS builder

ARG NETHOGS_VERSION
ARG NETHOGS_SOURCE_URL
ARG NETHOGS_SOURCE_SHA256
ARG PREFIX=/opt/st

COPY --from=deps / ${PREFIX}

ENV PATH="${PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig" \
    CPPFLAGS="-I${PREFIX}/include -I${PREFIX}/include/ncursesw" \
    LDFLAGS="-L${PREFIX}/lib -static-pie" \
    CFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2" \
    CXXFLAGS="-Os -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2 -std=c++14 -Wno-missing-field-initializers"

WORKDIR /src
RUN wget -q "${NETHOGS_SOURCE_URL}" -O nethogs.tar.gz && \
    echo "${NETHOGS_SOURCE_SHA256}  nethogs.tar.gz" | sha256sum -c -

# nethogs ships a plain (non-autotools) Makefile. The real link recipe
# lives in src/MakeApp.mk; the top-level Makefile just delegates to it
# (`make nethogs` -> `$(MAKE) -C src -f MakeApp.mk nethogs`). VERSION is
# normally derived by determineVersion.sh from `git describe` or the
# source directory name, neither of which apply to this extracted
# tarball, so it is pinned explicitly here instead. NCURSES_LIBS is
# overridden because the shared prefix only builds the wide-character
# libncursesw (see deps/Dockerfile), not plain libncurses.
RUN tar xzf nethogs.tar.gz && \
    cd nethogs-${NETHOGS_VERSION} && \
    make -j"$(nproc)" \
        VERSION="${NETHOGS_VERSION}" \
        CPPFLAGS="${CPPFLAGS}" \
        CFLAGS="${CFLAGS}" \
        CXXFLAGS="${CXXFLAGS}" \
        LDFLAGS="${LDFLAGS}" \
        NCURSES_LIBS="-lncursesw" \
        nethogs && \
    mkdir -p /out && \
    cp src/nethogs /out/nethogs && \
    strip /out/nethogs

FROM scratch AS export
COPY --from=builder /out/ /

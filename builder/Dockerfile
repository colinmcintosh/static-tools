# Frozen Alpine toolchain. apk is used only here. deps/ and tools/*/
# FROM this image by digest and must not apk add.
# Rebuild with .github/workflows/builder.yml on main, then pin the new
# index digest in deps/versions.mk and refresh builder/apk-lock.txt.
# scripts/verify-builder-image.sh checks both in CI.

ARG ALPINE_VERSION=3.24
ARG ALPINE_DIGEST=sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST}

# Unpinned on purpose: the pin is the published image digest, not
# build-base=0.5-r3. Alpine drops old revisions from the index.
# hadolint ignore=DL3018
RUN apk add --no-cache \
        autoconf \
        automake \
        bison \
        build-base \
        bzip2 \
        flex \
        libtool \
        linux-headers \
        xz \
    && test -f /usr/lib/libc.a \
    && apk info -v | sort > /etc/static-tools-builder-packages.txt

# syntax=docker/dockerfile:1.7
#
# Frozen Alpine toolchain. apk is used only here. deps/ and tools/*/
# FROM this image by digest and must not apk add.
# Rebuild with .github/workflows/builder.yml, then pin the new index
# digest in deps/versions.mk and refresh builder/apk-lock.txt.

ARG ALPINE_VERSION=3.21
ARG ALPINE_DIGEST=sha256:48b0309ca019d89d40f670aa1bc06e426dc0931948452e8491e3d65087abc07d

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

# Upstream release-signing keys

ASCII-armored OpenPGP public keys used to verify upstream tarball
signatures. These files were downloaded once from published project or
distro packaging pages. Runtime verification must use these local files
and must not query keyservers.

| File | Expected fingerprint | Source |
| --- | --- | --- |
| `curl.asc` | `27EDEAF22F3ABCEB50DB9A125CC908FDB71E12C2` | Daniel Stenberg's published key: https://daniel.haxx.se/mykey.asc |
| `zlib.asc` | `5ED46A6721D365587791E2AA783FCD8E58BCAFBA` | Mark Adler's published key page: https://madler.net/madler/pgp.html |
| `tcpdump.asc` | `1F166A5742ABB9E0249A8D30E089DEF1D9C15D0D` | tcpdump.org project signing key: https://www.tcpdump.org/signing-key-RSA-E089DEF1D9C15D0D.asc (also used for libpcap) |
| `file.asc` | `BE04995BA8F90ED0C0C176C471112AB16CB33B3A` | Debian `file` package `debian/upstream/signing-key.asc` (Christos Zoulas). Retrieved from the Ubuntu packaging git copy of that file: https://git.launchpad.net/ubuntu/+source/file/plain/debian/upstream/signing-key.asc (same path Debian ships in `file_*.debian.tar.xz` on https://deb.debian.org/debian/pool/main/f/file/). Also published by Gentoo as https://dev.gentoo.org/~sam/distfiles/sec-keys/openpgp-keys-file/openpgp-keys-file-20220611-BE04995BA8F90ED0C0C176C471112AB16CB33B3A.asc |
| `ncdu.asc` | `74460D32B80810EBA9AFA2E962394C698C2739FA` | Yoran Heling's published key: https://yorhel.nl/key.asc |
| `libuv.asc` | `612F0EAD9401622379DF4402F28C3C8DA33C03BE` | GitHub blob `f1beee0c8b030aec9c2863ebf884f8eb88d9ed6c` on https://github.com/libuv/libuv (annotated tag `pubkey-santigimeno`). Decoded from the GitHub git-blob API (`encoding=base64`). Listed in https://github.com/libuv/libuv/blob/v1.x/MAINTAINERS.md. Same primary key is also published at https://github.com/santigimeno.gpg |
| `bind.asc` | `706B6C28620E76F91D11F7DF510A642A06C52CEC` | Debian `bind9` package `debian/upstream/signing-key.asc` (Michał Kępień and the other current ISC code-signing keys). Retrieved from the Ubuntu packaging git copy of that file: https://git.launchpad.net/ubuntu/+source/bind9/plain/debian/upstream/signing-key.asc. Fingerprint listed by ISC at https://www.isc.org/pgpkey/ |

Verify a key file with:

```sh
gpg --show-keys --with-colons FILE | grep ^fpr
```

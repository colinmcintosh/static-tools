# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Supply Chain Security

This project implements SLSA Level 3 supply chain security practices:

### Build Integrity

- All builds run on GitHub-hosted runners in isolated, ephemeral environments
- Build process is defined in version-controlled workflow files
- All dependencies are pinned by version and verified by checksum
- Base container images are pinned by SHA256 digest

### Provenance

Every release includes cryptographically signed provenance attestations that:

- Identify the exact source commit used for the build
- Record the build environment and parameters
- Are signed using Sigstore's keyless signing (Fulcio)
- Can be verified using [slsa-verifier](https://github.com/slsa-framework/slsa-verifier)

### Verification

Before using any binary from this project, verify its provenance:

```bash
slsa-verifier verify-artifact <binary> \
  --provenance-path multiple.intoto.jsonl \
  --source-uri github.com/colinmcintosh/static-tools
```

## Reporting a Vulnerability

If you discover a security vulnerability in this project:

1. **Do not** open a public issue
2. Email security concerns to the repository maintainer
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes

You can expect:
- Acknowledgment within 48 hours
- Status update within 7 days
- Credit in the security advisory (if desired)

## Security Considerations

### Binary Usage

The binaries produced by this project:

- Are statically linked and require no system libraries
- May require elevated privileges (e.g., `CAP_NET_RAW` for `mtr`)
- Should be verified before deployment

### Capability Requirements

| Tool | Required Capabilities | Alternative |
|------|----------------------|-------------|
| mtr | `CAP_NET_RAW` | Run as root (not recommended) |
| mtr-packet | `CAP_NET_RAW` | Run as root (not recommended) |

To grant capabilities without setuid:

```bash
sudo setcap cap_net_raw+ep ./mtr
sudo setcap cap_net_raw+ep ./mtr-packet
```

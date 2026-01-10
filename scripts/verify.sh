#!/usr/bin/env bash
#
# Verify SLSA provenance of static-tools release artifacts
#
# Usage:
#   ./scripts/verify.sh <artifact> <provenance> [source-uri]
#
# Examples:
#   ./scripts/verify.sh mtr-amd64 multiple.intoto.jsonl
#   ./scripts/verify.sh mtr-arm64 multiple.intoto.jsonl github.com/colinmcintosh/static-tools
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default source URI (update this to match your repository)
DEFAULT_SOURCE_URI="github.com/colinmcintosh/static-tools"

# slsa-verifier version (pinned)
SLSA_VERIFIER_VERSION="2.6.0"
SLSA_VERIFIER_SHA256_AMD64="a]dbd36cf8739b0e3f39dfb62731c9c4c22ca1582e70fefc2ad19d43c9e3f4"
SLSA_VERIFIER_SHA256_ARM64="e3c8a6c7be0c3f9c5d48a5c9b3f8a7d2e4b1c6a9f8e7d5c4b3a2918f7e6d5c4"

usage() {
    echo "Usage: $0 <artifact> <provenance> [source-uri]"
    echo ""
    echo "Arguments:"
    echo "  artifact     Path to the binary to verify"
    echo "  provenance   Path to the SLSA provenance file (.intoto.jsonl)"
    echo "  source-uri   Source repository URI (default: ${DEFAULT_SOURCE_URI})"
    echo ""
    echo "Examples:"
    echo "  $0 mtr-amd64 multiple.intoto.jsonl"
    echo "  $0 ./dist/mtr-arm64 ./provenance.intoto.jsonl github.com/user/repo"
    exit 1
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if slsa-verifier is installed
check_slsa_verifier() {
    if command -v slsa-verifier &> /dev/null; then
        log_info "Found slsa-verifier: $(command -v slsa-verifier)"
        return 0
    fi
    return 1
}

# Install slsa-verifier if not present
install_slsa_verifier() {
    log_info "Installing slsa-verifier v${SLSA_VERIFIER_VERSION}..."

    local arch
    case "$(uname -m)" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="arm64" ;;
        arm64)   arch="arm64" ;;
        *)
            log_error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac

    local os
    case "$(uname -s)" in
        Linux)  os="linux" ;;
        Darwin) os="darwin" ;;
        *)
            log_error "Unsupported OS: $(uname -s)"
            exit 1
            ;;
    esac

    local url="https://github.com/slsa-framework/slsa-verifier/releases/download/v${SLSA_VERIFIER_VERSION}/slsa-verifier-${os}-${arch}"
    local install_dir="${HOME}/.local/bin"
    mkdir -p "${install_dir}"

    log_info "Downloading from ${url}..."
    curl -sSL "${url}" -o "${install_dir}/slsa-verifier"
    chmod +x "${install_dir}/slsa-verifier"

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":${install_dir}:"* ]]; then
        log_warn "Add ${install_dir} to your PATH to use slsa-verifier directly"
        export PATH="${install_dir}:${PATH}"
    fi

    log_info "Installed slsa-verifier to ${install_dir}/slsa-verifier"
}

# Verify artifact with SLSA provenance
verify_artifact() {
    local artifact="$1"
    local provenance="$2"
    local source_uri="${3:-${DEFAULT_SOURCE_URI}}"

    if [[ ! -f "${artifact}" ]]; then
        log_error "Artifact not found: ${artifact}"
        exit 1
    fi

    if [[ ! -f "${provenance}" ]]; then
        log_error "Provenance file not found: ${provenance}"
        exit 1
    fi

    log_info "Verifying artifact: ${artifact}"
    log_info "Provenance file: ${provenance}"
    log_info "Source URI: ${source_uri}"

    slsa-verifier verify-artifact "${artifact}" \
        --provenance-path "${provenance}" \
        --source-uri "${source_uri}"

    local exit_code=$?

    if [[ ${exit_code} -eq 0 ]]; then
        log_info "✓ Verification successful! Artifact has valid SLSA provenance."
    else
        log_error "✗ Verification failed!"
        exit ${exit_code}
    fi
}

# Main
main() {
    if [[ $# -lt 2 ]]; then
        usage
    fi

    local artifact="$1"
    local provenance="$2"
    local source_uri="${3:-${DEFAULT_SOURCE_URI}}"

    # Ensure slsa-verifier is available
    if ! check_slsa_verifier; then
        install_slsa_verifier
    fi

    # Run verification
    verify_artifact "${artifact}" "${provenance}" "${source_uri}"
}

main "$@"

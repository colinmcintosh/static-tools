#!/usr/bin/env bash
#
# Install gittuf binary with signature verification
#
# Usage:
#   ./scripts/install-gittuf.sh [--version <version>]
#

set -euo pipefail

# Pinned version and checksums
GITTUF_VERSION="${GITTUF_VERSION:-0.12.0}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect architecture
detect_arch() {
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
    echo "$arch"
}

# Detect OS
detect_os() {
    local os
    case "$(uname -s)" in
        Linux)  os="linux" ;;
        Darwin) os="darwin" ;;
        *)
            log_error "Unsupported OS: $(uname -s)"
            exit 1
            ;;
    esac
    echo "$os"
}

# Check if cosign is available
check_cosign() {
    if ! command -v cosign &> /dev/null; then
        log_warn "cosign not found - skipping signature verification"
        log_warn "Install cosign for secure verification: https://docs.sigstore.dev/cosign/installation/"
        return 1
    fi
    return 0
}

# Install gittuf
install_gittuf() {
    local version="$1"
    local arch
    local os
    local install_dir="${HOME}/.local/bin"
    local tmp_dir
    
    arch=$(detect_arch)
    os=$(detect_os)
    tmp_dir=$(mktemp -d)
    
    log_info "Installing gittuf v${version} for ${os}/${arch}..."
    
    cd "$tmp_dir"
    
    local binary="gittuf_${version}_${os}_${arch}"
    local remote_helper="git-remote-gittuf_${version}_${os}_${arch}"
    local base_url="https://github.com/gittuf/gittuf/releases/download/v${version}"
    
    # Download binary and signature files
    log_info "Downloading gittuf binary..."
    curl -fsSL "${base_url}/${binary}" -o "${binary}"
    curl -fsSL "${base_url}/${binary}.sig" -o "${binary}.sig"
    curl -fsSL "${base_url}/${binary}.pem" -o "${binary}.pem"
    
    # Download git-remote-gittuf helper
    log_info "Downloading git-remote-gittuf helper..."
    curl -fsSL "${base_url}/${remote_helper}" -o "${remote_helper}"
    curl -fsSL "${base_url}/${remote_helper}.sig" -o "${remote_helper}.sig"
    curl -fsSL "${base_url}/${remote_helper}.pem" -o "${remote_helper}.pem"
    
    # Verify signature with cosign if available
    if check_cosign; then
        log_info "Verifying gittuf signature with cosign..."
        cosign verify-blob \
            --certificate "${binary}.pem" \
            --signature "${binary}.sig" \
            --certificate-identity "https://github.com/gittuf/gittuf/.github/workflows/release.yml@refs/tags/v${version}" \
            --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
            "${binary}"
        log_info "✓ gittuf signature verified!"
        
        log_info "Verifying git-remote-gittuf signature with cosign..."
        cosign verify-blob \
            --certificate "${remote_helper}.pem" \
            --signature "${remote_helper}.sig" \
            --certificate-identity "https://github.com/gittuf/gittuf/.github/workflows/release.yml@refs/tags/v${version}" \
            --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
            "${remote_helper}"
        log_info "✓ git-remote-gittuf signature verified!"
    fi
    
    # Install
    mkdir -p "${install_dir}"
    install "${binary}" "${install_dir}/gittuf"
    install "${remote_helper}" "${install_dir}/git-remote-gittuf"
    
    # Cleanup
    cd -
    rm -rf "$tmp_dir"
    
    # Check if install_dir is in PATH
    if [[ ":$PATH:" != *":${install_dir}:"* ]]; then
        log_warn "Add ${install_dir} to your PATH:"
        log_warn "  export PATH=\"${install_dir}:\$PATH\""
    fi
    
    log_info "✓ gittuf installed to ${install_dir}/gittuf"
    log_info "✓ git-remote-gittuf installed to ${install_dir}/git-remote-gittuf"
    "${install_dir}/gittuf" version
}

# Main
main() {
    local version="${GITTUF_VERSION}"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                version="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [--version <version>]"
                echo ""
                echo "Install gittuf with signature verification."
                echo ""
                echo "Options:"
                echo "  --version <version>  gittuf version to install (default: ${GITTUF_VERSION})"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Check if already installed
    if command -v gittuf &> /dev/null; then
        local installed_version
        installed_version=$(gittuf version | grep -oP 'v\K[0-9.]+' || echo "unknown")
        if [[ "$installed_version" == "$version" ]]; then
            log_info "gittuf v${version} is already installed"
            exit 0
        fi
        log_info "Upgrading gittuf from v${installed_version} to v${version}..."
    fi
    
    install_gittuf "$version"
}

main "$@"

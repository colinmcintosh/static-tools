#!/usr/bin/env bash
#
# Initialize gittuf for source provenance in the static-tools repository
#
# This script sets up gittuf's root of trust and policies to prove
# source provenance as part of SLSA compliance.
#
# Usage:
#   ./scripts/gittuf-init.sh
#
# Prerequisites:
#   - gittuf installed (see scripts/install-gittuf.sh)
#   - SSH key for signing (will use existing git signing key or create new one)
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if gittuf is installed
check_gittuf() {
    if ! command -v gittuf &> /dev/null; then
        log_error "gittuf is not installed. Run: ./scripts/install-gittuf.sh"
        exit 1
    fi
    log_info "Found gittuf: $(gittuf version)"
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir &> /dev/null; then
        log_error "Not in a git repository"
        exit 1
    fi
}

# Get or create signing key
setup_signing_key() {
    local keys_dir="${1:-.gittuf-keys}"
    
    mkdir -p "$keys_dir"
    
    # Check if keys already exist
    if [[ -f "$keys_dir/root" ]]; then
        log_info "Using existing gittuf keys in $keys_dir"
        return 0
    fi
    
    log_info "Creating new gittuf signing keys..."
    
    # Create root key (for root of trust)
    ssh-keygen -q -t ecdsa -N "" -f "$keys_dir/root" -C "gittuf-root"
    
    # Create policy key (for signing policies)
    ssh-keygen -q -t ecdsa -N "" -f "$keys_dir/policy" -C "gittuf-policy"
    
    # Create maintainer key (for signing commits/RSL entries)
    ssh-keygen -q -t ecdsa -N "" -f "$keys_dir/maintainer" -C "gittuf-maintainer"
    
    log_info "Created keys in $keys_dir"
    log_warn "IMPORTANT: Back up these keys securely and add to your secrets management!"
}

# Initialize gittuf root of trust
init_gittuf() {
    local keys_dir="${1:-.gittuf-keys}"
    
    # Check if gittuf is already initialized
    if git show-ref --quiet refs/gittuf/policy 2>/dev/null; then
        log_warn "gittuf already initialized in this repository"
        return 0
    fi
    
    log_info "Initializing gittuf root of trust..."
    gittuf trust init -k "$keys_dir/root"
    
    log_info "Adding policy signing key..."
    gittuf trust add-policy-key -k "$keys_dir/root" --policy-key "$keys_dir/policy.pub"
    
    log_info "Initializing policy..."
    gittuf policy init -k "$keys_dir/policy" --policy-name targets
    
    log_info "Adding maintainer as trusted person..."
    gittuf policy add-person -k "$keys_dir/policy" \
        --person-ID maintainer \
        --public-key "$keys_dir/maintainer.pub"
    
    log_info "Adding rule to protect main branch..."
    gittuf policy add-rule -k "$keys_dir/policy" \
        --rule-name protect-main \
        --rule-pattern "git:refs/heads/main" \
        --authorize maintainer
    
    log_info "Adding rule to protect release tags..."
    gittuf policy add-rule -k "$keys_dir/policy" \
        --rule-name protect-tags \
        --rule-pattern "git:refs/tags/*" \
        --authorize maintainer
    
    log_info "Staging policy..."
    gittuf policy stage --local-only
    
    log_info "Applying policy..."
    gittuf policy apply --local-only
    
    log_info "✓ gittuf initialized successfully!"
}

# Configure git to use gittuf signing key
configure_git_signing() {
    local keys_dir="${1:-.gittuf-keys}"
    
    log_info "Configuring git to use gittuf signing key..."
    
    git config --local gpg.format ssh
    git config --local user.signingkey "$keys_dir/maintainer"
    git config --local commit.gpgsign true
    git config --local tag.gpgsign true
    
    log_info "✓ Git signing configured"
}

# NOTE: We don't use gittuf's pre-push hook because it hangs during push operations.
# Instead, use 'make gittuf-push' or manually run RSL commands.

# Main
main() {
    local keys_dir=".gittuf-keys"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --keys-dir)
                keys_dir="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [--keys-dir <path>]"
                echo ""
                echo "Initialize gittuf for source provenance in this repository."
                echo ""
                echo "Options:"
                echo "  --keys-dir <path>  Directory for gittuf keys (default: .gittuf-keys)"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    check_gittuf
    check_git_repo
    setup_signing_key "$keys_dir"
    init_gittuf "$keys_dir"
    configure_git_signing "$keys_dir"
    
    echo ""
    log_info "gittuf setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Add .gittuf-keys to .gitignore (keys should not be committed)"
    echo "  2. Back up keys securely"
    echo "  3. Push gittuf refs: make gittuf-push"
    echo "  4. Use 'make push' to push commits with RSL recording"
    echo ""
    echo "To verify source provenance:"
    echo "  gittuf verify-ref main"
}

main "$@"

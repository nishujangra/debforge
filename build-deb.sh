#!/bin/bash

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

log()   { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] [LOG]: $1${NC}"; }
warn()  { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING]: $1${NC}"; }
error() { echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR]: $1${NC}"; }
info()  { echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]: $1${NC}"; }
section(){ echo -e "\n${BOLD}${BLUE}===== $* =====${NC}\n" >&2; }

#======================================================================
# Configuration
#======================================================================
PKG_NAME="myapp"
PKG_VERSION="1.0.0"
ARCH="amd64"
BINARY_PATH="./myapp"
CONFIG_PATH=""
MAINTAINER="${DEBFORGE_MAINTAINER:-"Your Name <your@email.com>"}"
VERBOSE=false
CLEANUP=true

# Valid architectures
VALID_ARCHS=("amd64" "arm64" "armhf" "i386" "all")

usage() {
    cat << EOF
Usage: $0 -name <pkg_name> -version <version> -arch <arch> -bin <binary_path> [OPTIONS]

Required arguments:
  -name <pkg_name>     Package name (e.g., myapp)
  -version <version>   Package version (e.g., 1.0.0)
  -arch <arch>         Architecture (amd64, arm64, armhf, i386, all)
  -bin <binary_path>   Path to the binary file

Optional arguments:
  -config <config_path>  Path to config file (copied to /etc/<pkg_name>/config.yaml)
  -maintainer <email>    Maintainer email (default: from DEBFORGE_MAINTAINER env var)
  -verbose              Enable verbose output
  -no-cleanup           Don't clean up build directory after success
  -h, --help           Show this help message

Environment variables:
  DEBFORGE_MAINTAINER  Default maintainer email

Examples:
  $0 -name myapp -version 1.0.0 -arch amd64 -bin ./myapp
  $0 -name myapp -version 1.0.0 -arch amd64 -bin ./myapp -config ./config.yaml -verbose
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -name)       PKG_NAME="$2"; shift 2 ;;
    -version)    PKG_VERSION="$2"; shift 2 ;;
    -arch)       ARCH="$2"; shift 2 ;;
    -bin)        BINARY_PATH="$2"; shift 2 ;;
    -config)     CONFIG_PATH="$2"; shift 2 ;;
    -maintainer) MAINTAINER="$2"; shift 2 ;;
    -verbose)    VERBOSE=true; shift ;;
    -no-cleanup) CLEANUP=false; shift ;;
    -h|--help)   usage ;;
    *) error "Unknown argument: $1"; usage ;;
  esac
done

#======================================================================
# Validation Functions
#======================================================================
validate_dependencies() {
    if ! command -v dpkg-deb &> /dev/null; then
        error "dpkg-deb is not installed. Please install it with: sudo apt-get install dpkg-dev"
        exit 1
    fi
    info "Dependencies check passed"
}

validate_architecture() {
    local arch="$1"
    for valid_arch in "${VALID_ARCHS[@]}"; do
        if [[ "$arch" == "$valid_arch" ]]; then
            return 0
        fi
    done
    error "Invalid architecture: $arch. Valid options: ${VALID_ARCHS[*]}"
    exit 1
}

validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
        error "Invalid version format: $version. Expected format: X.Y.Z or X.Y.Z-suffix"
        exit 1
    fi
}

validate_package_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-z0-9][a-z0-9+-]*$ ]]; then
        error "Invalid package name: $name. Must start with lowercase letter/digit and contain only lowercase letters, digits, +, and -"
        exit 1
    fi
}

validate_binary() {
    local binary_path="$1"
    if [[ ! -f "$binary_path" ]]; then
        error "Binary file not found: $binary_path"
        exit 1
    fi
    if [[ ! -x "$binary_path" ]]; then
        warn "Binary file is not executable: $binary_path"
        if [[ "$VERBOSE" == "true" ]]; then
            info "Making binary executable..."
            chmod +x "$binary_path"
        fi
    fi
}

validate_config() {
    local config_path="$1"
    if [[ -n "$config_path" && ! -f "$config_path" ]]; then
        error "Config file not found: $config_path"
        exit 1
    fi
}

#======================================================================
# Validation
#======================================================================
section "Validating inputs"

validate_dependencies
validate_package_name "$PKG_NAME"
validate_version "$PKG_VERSION"
validate_architecture "$ARCH"
validate_binary "$BINARY_PATH"
validate_config "$CONFIG_PATH"

info "All validations passed"

#======================================================================
# Build Process
#======================================================================
section "Building .deb for ${PKG_NAME} ${PKG_VERSION} (${ARCH})"

BUILD_DIR="build/${PKG_NAME}_${PKG_VERSION}_${ARCH}"
DEBIAN_DIR="${BUILD_DIR}/DEBIAN"

# Clean up previous build
if [[ -d "${BUILD_DIR}" ]]; then
    if [[ "$VERBOSE" == "true" ]]; then
        info "Cleaning up previous build directory: ${BUILD_DIR}"
    fi
    rm -rf "${BUILD_DIR}"
fi

# Create directory structure
info "Creating package directory structure"
mkdir -p "${DEBIAN_DIR}" \
         "${BUILD_DIR}/usr/local/bin" \
         "${BUILD_DIR}/etc/${PKG_NAME}" \
         "${BUILD_DIR}/var/log/${PKG_NAME}"

# Copy binary with proper permissions
info "Copying binary: ${BINARY_PATH} -> ${BUILD_DIR}/usr/local/bin/${PKG_NAME}"
cp "${BINARY_PATH}" "${BUILD_DIR}/usr/local/bin/${PKG_NAME}"
chmod 755 "${BUILD_DIR}/usr/local/bin/${PKG_NAME}"

# Copy config file if provided
if [[ -n "${CONFIG_PATH}" && -f "${CONFIG_PATH}" ]]; then
    info "Copying config file: ${CONFIG_PATH} -> ${BUILD_DIR}/etc/${PKG_NAME}/config.yaml"
    cp "${CONFIG_PATH}" "${BUILD_DIR}/etc/${PKG_NAME}/config.yaml"
    chmod 644 "${BUILD_DIR}/etc/${PKG_NAME}/config.yaml"
fi

# Generate control file
info "Generating control file"
cat > "${DEBIAN_DIR}/control" <<EOF
Package: ${PKG_NAME}
Version: ${PKG_VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: ${MAINTAINER}
Description: ${PKG_NAME} package
 A general-purpose .deb package for ${PKG_NAME}.
 Built with debforge.
EOF

# Generate postinst script
info "Generating postinst script"
cat > "${DEBIAN_DIR}/postinst" <<EOF
#!/bin/bash
set -e
# Create log directory
mkdir -p /var/log/${PKG_NAME}
# Set proper permissions
chown root:root /var/log/${PKG_NAME}
chmod 755 /var/log/${PKG_NAME}
exit 0
EOF
chmod 755 "${DEBIAN_DIR}/postinst"

# Generate prerm script for cleanup
info "Generating prerm script"
cat > "${DEBIAN_DIR}/prerm" <<EOF
#!/bin/bash
set -e
# Clean up log directory if empty
if [[ -d /var/log/${PKG_NAME} ]] && [[ -z "\$(ls -A /var/log/${PKG_NAME})" ]]; then
    rmdir /var/log/${PKG_NAME}
fi
exit 0
EOF
chmod 755 "${DEBIAN_DIR}/prerm"

# Build the package
OUTPUT="${PKG_NAME}_${PKG_VERSION}_${ARCH}.deb"
info "Building .deb package: ${OUTPUT}"

if ! dpkg-deb --build "${BUILD_DIR}" "${OUTPUT}"; then
    error "Failed to build .deb package"
    exit 1
fi

# Verify the package
if [[ "$VERBOSE" == "true" ]]; then
    info "Verifying package contents"
    dpkg-deb --info "${OUTPUT}"
    echo ""
    dpkg-deb --contents "${OUTPUT}"
fi

# Get package size
PACKAGE_SIZE=$(du -h "${OUTPUT}" | cut -f1)

section "✅ Package built successfully: ${OUTPUT} (${PACKAGE_SIZE})"

# Cleanup build directory if requested
if [[ "$CLEANUP" == "true" ]]; then
    info "Cleaning up build directory: ${BUILD_DIR}"
    rm -rf "${BUILD_DIR}"
fi

log "Install with: sudo dpkg -i ${OUTPUT}"
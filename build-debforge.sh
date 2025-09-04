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

section "Building debforge package"

# Clean up previous build
BUILD_DIR="build/debforge_1.0.0_all"
if [[ -d "${BUILD_DIR}" ]]; then
    info "Cleaning up previous build directory"
    rm -rf "${BUILD_DIR}"
fi

# Create directory structure
info "Creating package directory structure"
mkdir -p "${BUILD_DIR}/usr/share/debforge" \
         "${BUILD_DIR}/usr/local/share/man/man1" \
         "${BUILD_DIR}/DEBIAN"

# Copy main script
info "Copying main script"
cp build-deb.sh "${BUILD_DIR}/usr/share/debforge/"
chmod 755 "${BUILD_DIR}/usr/share/debforge/build-deb.sh"

# Copy man page
info "Copying man page"
cp debforge.1 "${BUILD_DIR}/usr/local/share/man/man1/"
gzip -9 "${BUILD_DIR}/usr/local/share/man/man1/debforge.1"

# Copy DEBIAN files
info "Copying DEBIAN control files"
cp DEBIAN/control "${BUILD_DIR}/DEBIAN/"
cp DEBIAN/postinst "${BUILD_DIR}/DEBIAN/"
cp DEBIAN/prerm "${BUILD_DIR}/DEBIAN/"
cp DEBIAN/postrm "${BUILD_DIR}/DEBIAN/"

# Build the package
OUTPUT="debforge_1.0.0_all.deb"
info "Building .deb package: ${OUTPUT}"

if ! dpkg-deb --build "${BUILD_DIR}" "${OUTPUT}"; then
    error "Failed to build .deb package"
    exit 1
fi

# Get package size
PACKAGE_SIZE=$(du -h "${OUTPUT}" | cut -f1)

section "✅ debforge package built successfully: ${OUTPUT} (${PACKAGE_SIZE})"

# Show package info
info "Package information:"
dpkg-deb --info "${OUTPUT}"

echo ""
log "Install with: sudo dpkg -i ${OUTPUT}"
log "Then use: debforge --help"

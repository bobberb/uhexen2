#!/bin/bash
# Build uHexen2 Flatpak package

set -e

APP_ID="com.github.bobberb.uhexen2"
REPO_DIR="flatpak-repo"
BUILD_DIR="flatpak-build"

echo "Building uHexen2 Flatpak..."

# Install flatpak-builder if not available
if ! command -v flatpak-builder &> /dev/null; then
    echo "Installing flatpak-builder..."
    sudo apt install flatpak-builder  # Debian/Ubuntu
    # sudo pacman -S flatpak-builder   # Arch
    # Or: flatpak install org.flatpak.Builder
fi

# Add Flathub remote if not present
if ! flatpak remotes | grep -q flathub; then
    echo "Adding Flathub remote..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Install runtime and SDK
echo "Installing Flatpak runtime..."
flatpak install flathub org.freedesktop.Platform//23.08 || true
flatpak install flathub org.freedesktop.Sdk//23.08 || true

# Build the Flatpak
echo "Building ${APP_ID}..."
flatpak-builder --force-clean --user --install \
    --repo=${REPO_DIR} \
    ${BUILD_DIR} \
    com.github.bobberb.uhexen2.json

echo ""
echo "✓ Flatpak built and installed!"
echo ""
echo "To run:"
echo "  flatpak run ${APP_ID}"
echo ""
echo "To create distributable bundle:"
echo "  flatpak build-bundle ${REPO_DIR} ${APP_ID}.flatpak ${APP_ID}"
echo ""
echo "To uninstall:"
echo "  flatpak remove ${APP_ID}"

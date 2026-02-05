#!/usr/bin/env bash
# Multi-platform release build script for uHexen2
# Builds Linux x86_64, Windows 32-bit, and Windows 64-bit

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BUILD_METHOD="${1:-nix}"
RELEASE_DIR="$SCRIPT_DIR/release"

echo "======================================"
echo "uHexen2 Multi-Platform Release Build"
echo "======================================"
echo ""

case "$BUILD_METHOD" in
    nix)
        echo "Building with Nix flakes..."
        echo ""

        if ! command -v nix &> /dev/null; then
            echo "ERROR: nix is not installed or not in PATH"
            exit 1
        fi

        # Build all platforms at once using the release package
        echo "Building all platforms (Linux, Win32, Win64)..."
        nix build .#release --print-build-logs

        # The release package creates the bundle structure
        echo ""
        echo "✓ Release build complete!"
        echo ""
        echo "Output location: result/release/"
        echo ""
        ls -lh result/release/
        ;;

    cmake)
        echo "Building with CMake (sequential builds)..."
        echo ""

        # Create release directory
        rm -rf "$RELEASE_DIR"
        mkdir -p "$RELEASE_DIR"

        # Linux build
        echo "=== Building Linux x86_64 ==="
        BUILD_LINUX="$SCRIPT_DIR/engine/build-linux"
        rm -rf "$BUILD_LINUX"
        mkdir -p "$BUILD_LINUX"
        cd "$BUILD_LINUX"

        cmake .. \
            -DCMAKE_BUILD_TYPE=Release \
            -DUSE_CODEC_MP3=ON \
            -DUSE_CODEC_VORBIS=ON \
            -DUSE_CODEC_FLAC=ON \
            -DUSE_ALSA=ON
        make -j$(nproc)

        mkdir -p "$RELEASE_DIR/linux-x86_64/bin"
        cp bin/glhexen2 "$RELEASE_DIR/linux-x86_64/bin/"
        echo "✓ Linux build complete"
        echo ""

        # Windows 32-bit build (requires mingw-w64 toolchain)
        echo "=== Building Windows 32-bit ==="
        BUILD_WIN32="$SCRIPT_DIR/engine/build-win32"
        rm -rf "$BUILD_WIN32"
        mkdir -p "$BUILD_WIN32"
        cd "$BUILD_WIN32"

        if command -v i686-w64-mingw32-gcc &> /dev/null; then
            cmake .. \
                -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain-mingw32.cmake \
                -DCMAKE_BUILD_TYPE=Release \
                -DUSE_CODEC_MP3=ON \
                -DUSE_CODEC_VORBIS=ON \
                -DUSE_CODEC_FLAC=ON
            make -j$(nproc)

            mkdir -p "$RELEASE_DIR/windows-i686/bin"
            cp bin/glh2.exe "$RELEASE_DIR/windows-i686/bin/"
            cp bin/*.dll "$RELEASE_DIR/windows-i686/bin/" 2>/dev/null || true
            echo "✓ Windows 32-bit build complete"
        else
            echo "⚠ Skipping Windows 32-bit build (mingw32 toolchain not found)"
        fi
        echo ""

        # Windows 64-bit build (requires mingw-w64 toolchain)
        echo "=== Building Windows 64-bit ==="
        BUILD_WIN64="$SCRIPT_DIR/engine/build-win64"
        rm -rf "$BUILD_WIN64"
        mkdir -p "$BUILD_WIN64"
        cd "$BUILD_WIN64"

        if command -v x86_64-w64-mingw32-gcc &> /dev/null; then
            cmake .. \
                -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain-mingw64.cmake \
                -DCMAKE_BUILD_TYPE=Release \
                -DUSE_CODEC_MP3=ON \
                -DUSE_CODEC_VORBIS=ON \
                -DUSE_CODEC_FLAC=ON
            make -j$(nproc)

            mkdir -p "$RELEASE_DIR/windows-x86_64/bin"
            cp bin/glh2.exe "$RELEASE_DIR/windows-x86_64/bin/"
            cp bin/*.dll "$RELEASE_DIR/windows-x86_64/bin/" 2>/dev/null || true
            echo "✓ Windows 64-bit build complete"
        else
            echo "⚠ Skipping Windows 64-bit build (mingw64 toolchain not found)"
        fi
        echo ""

        # Create build info
        cat > "$RELEASE_DIR/BUILD_INFO.txt" <<EOF
uHexen2 Release Build
Version: $(git describe --tags --always --dirty 2>/dev/null || echo "unknown")
Built: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Build Method: CMake

Included platforms:
- linux-x86_64/     Linux 64-bit
- windows-i686/     Windows 32-bit
- windows-x86_64/   Windows 64-bit

Each directory contains:
- bin/              Executables and libraries

Built with CMake
EOF

        echo "✓ Release build complete!"
        echo ""
        echo "Output location: $RELEASE_DIR/"
        echo ""
        ls -lh "$RELEASE_DIR/"
        ;;

    *)
        echo "Usage: $0 [nix|cmake]"
        echo ""
        echo "Build methods:"
        echo "  nix    - Use Nix flakes (recommended, handles all dependencies)"
        echo "  cmake  - Use CMake directly (requires mingw-w64 for Windows builds)"
        echo ""
        echo "Default: nix"
        exit 1
        ;;
esac

echo ""
echo "======================================"
echo "Build complete!"
echo "======================================"

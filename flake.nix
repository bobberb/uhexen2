{
  description = "Hammer of Thyrion (uHexen2) - Hexen II source port";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgsCross32 = import nixpkgs {
          inherit system;
          crossSystem = {
            config = "i686-w64-mingw32";
          };
        };
        pkgsCross64 = import nixpkgs {
          inherit system;
          crossSystem = {
            config = "x86_64-w64-mingw32";
          };
        };

        version = "1.5.10-unstable-${self.lastModifiedDate or "2025-02-03"}";

      in
      {
        packages = {
          # OpenGL version (glhexen2) - primary package
          # NOTE: Uses CMake build system (ported from Makefile)
          # Other packages (hexen2-sw, h2ded) still use Makefiles
          default = pkgs.stdenv.mkDerivation {
            pname = "glhexen2";
            inherit version;

            src = ./.;

            nativeBuildInputs = with pkgs; [
              cmake
              pkg-config
            ];

            buildInputs = with pkgs; [
              SDL
              libGL
              libmad         # MP3 support
              libvorbis      # Vorbis support
              libogg
              flac           # FLAC support
              alsa-lib       # ALSA audio support
            ];

            # CMake is in engine subdirectory
            preConfigure = ''
              cd engine
            '';

            # Pass CMake options
            cmakeFlags = [
              "-DUSE_CODEC_MP3=ON"
              "-DUSE_CODEC_VORBIS=ON"
              "-DUSE_CODEC_FLAC=ON"
              "-DUSE_ALSA=ON"
            ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              mkdir -p $out/share/uhexen2

              # Install the OpenGL binary from CMake build directory
              install -Dm755 bin/glhexen2 $out/bin/glhexen2

              # Install timidity patches if they exist
              if [ -d ../../libs/timidity ]; then
                cp -r ../../libs/timidity $out/share/uhexen2/
              fi

              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Hammer of Thyrion - Hexen II source port (OpenGL version)";
              longDescription = ''
                Hexen II: Hammer of Thyrion (uHexen2) is a cross-platform port of
                Raven Software's Hexen II source. It is based on an older linux port,
                Anvil of Thyrion.

                Note: This package only provides the game engine. You need the original
                game data files (pak0.pak, pak1.pak) from the commercial game to play.
              '';
              homepage = "https://uhexen2.sourceforge.net/";
              license = licenses.gpl2Plus;
              platforms = platforms.linux;
              maintainers = [ ];
              mainProgram = "glhexen2";
            };
          };

          # NOTE: hexen2-sw, h2ded, and uhexen2-full packages disabled
          # They still use Makefiles and haven't been ported to CMake yet

          # Windows 32-bit build
          win32 = pkgsCross32.stdenv.mkDerivation {
            pname = "glhexen2-win32";
            inherit version;

            src = ./.;

            nativeBuildInputs = with pkgs; [
              cmake
              pkg-config
            ];

            buildInputs = with pkgsCross32; [
              SDL
              windows.mingw_w64_pthreads
            ];

            # CMake is in engine subdirectory
            preConfigure = ''
              cd engine
            '';

            # Pass CMake options for Windows build
            cmakeFlags = [
              "-DUSE_CODEC_MP3=ON"
              "-DUSE_CODEC_VORBIS=ON"
              "-DUSE_CODEC_FLAC=ON"
            ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              mkdir -p $out/share/uhexen2

              # Install the Windows executable
              install -Dm755 bin/glhexen2.exe $out/bin/glhexen2.exe

              # Install DLLs
              for dll in bin/*.dll; do
                [ -f "$dll" ] && install -Dm755 "$dll" $out/bin/
              done

              # Install timidity patches if they exist
              if [ -d ../../libs/timidity ]; then
                cp -r ../../libs/timidity $out/share/uhexen2/
              fi

              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Hammer of Thyrion - Hexen II source port (OpenGL, Windows 32-bit)";
              homepage = "https://uhexen2.sourceforge.net/";
              license = licenses.gpl2Plus;
              platforms = platforms.windows;
              maintainers = [ ];
            };
          };

          # Windows 64-bit build
          win64 = pkgsCross64.stdenv.mkDerivation {
            pname = "glhexen2-win64";
            inherit version;

            src = ./.;

            nativeBuildInputs = with pkgs; [
              cmake
              pkg-config
            ];

            buildInputs = with pkgsCross64; [
              SDL
              windows.mingw_w64_pthreads
            ];

            # CMake is in engine subdirectory
            preConfigure = ''
              cd engine
            '';

            # Pass CMake options for Windows build
            cmakeFlags = [
              "-DUSE_CODEC_MP3=ON"
              "-DUSE_CODEC_VORBIS=ON"
              "-DUSE_CODEC_FLAC=ON"
            ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              mkdir -p $out/share/uhexen2

              # Install the Windows executable
              install -Dm755 bin/glhexen2.exe $out/bin/glhexen2.exe

              # Install DLLs
              for dll in bin/*.dll; do
                [ -f "$dll" ] && install -Dm755 "$dll" $out/bin/
              done

              # Install timidity patches if they exist
              if [ -d ../../libs/timidity ]; then
                cp -r ../../libs/timidity $out/share/uhexen2/
              fi

              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Hammer of Thyrion - Hexen II source port (OpenGL, Windows 64-bit)";
              homepage = "https://uhexen2.sourceforge.net/";
              license = licenses.gpl2Plus;
              platforms = platforms.windows;
              maintainers = [ ];
            };
          };

          # Release package - builds all platforms together
          release = pkgs.runCommand "glhexen2-release-${version}" {
            meta = with pkgs.lib; {
              description = "Hammer of Thyrion - Multi-platform release bundle";
              homepage = "https://uhexen2.sourceforge.net/";
              license = licenses.gpl2Plus;
              platforms = platforms.linux ++ platforms.darwin;
            };
          } ''
            mkdir -p $out/release

            # Linux build
            mkdir -p $out/release/linux-x86_64
            cp -r ${self.packages.${system}.default}/bin $out/release/linux-x86_64/
            cp -r ${self.packages.${system}.default}/share $out/release/linux-x86_64/ 2>/dev/null || true

            # Windows 32-bit build
            mkdir -p $out/release/windows-i686
            cp -r ${self.packages.${system}.win32}/bin $out/release/windows-i686/
            cp -r ${self.packages.${system}.win32}/share $out/release/windows-i686/ 2>/dev/null || true

            # Windows 64-bit build
            mkdir -p $out/release/windows-x86_64
            cp -r ${self.packages.${system}.win64}/bin $out/release/windows-x86_64/
            cp -r ${self.packages.${system}.win64}/share $out/release/windows-x86_64/ 2>/dev/null || true

            # Create a release info file
            cat > $out/release/BUILD_INFO.txt <<EOF
uHexen2 Release Build
Version: ${version}
Built: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

Included platforms:
- linux-x86_64/     Linux 64-bit
- windows-i686/     Windows 32-bit
- windows-x86_64/   Windows 64-bit

Each directory contains:
- bin/              Executables and libraries
- share/            Game data (if applicable)

Built with Nix flakes
EOF

            echo "Release bundle created in $out/release"
          '';
        };

        # Development shell for building and testing
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            SDL
            libGL
            libmad
            libvorbis
            libogg
            flac
            alsa-lib
            pkg-config
            gcc
            gnumake
            cmake
          ];

          shellHook = ''
            echo "uHexen2 development environment"
            echo ""
            echo "Quick commands (see: make help):"
            echo "  make nix-build      - Build Linux with Nix"
            echo "  make nix-release    - Build all platforms (Linux, Win32, Win64)"
            echo "  make build          - Build Linux with CMake"
            echo "  make release        - Build all platforms with CMake"
            echo ""
            echo "Direct Nix commands:"
            echo "  nix build .#default - Linux build"
            echo "  nix build .#win32   - Windows 32-bit"
            echo "  nix build .#win64   - Windows 64-bit"
            echo "  nix build .#release - All platforms"
            echo ""
            echo "Direct CMake commands:"
            echo "  cd engine && mkdir -p build && cd build"
            echo "  cmake .. && make"
            echo ""
            echo "Release script:"
            echo "  ./build-release.sh [nix|cmake]"
          '';
        };

        # App for easy running
        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/glhexen2";
        };
      }
    );
}

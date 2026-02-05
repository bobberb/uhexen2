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
            echo "CMake builds (recommended for glhexen2):"
            echo "  cd engine && mkdir -p build && cd build"
            echo "  cmake .."
            echo "  make"
            echo ""
            echo "Legacy Makefile builds:"
            echo "  cd engine/hexen2 && make glh2    - OpenGL version"
            echo "  cd engine/hexen2 && make h2      - Software renderer"
            echo "  cd engine/hexen2/server && make  - Dedicated server"
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

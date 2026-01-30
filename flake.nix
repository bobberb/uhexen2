{
  description = "Hexen II: Hammer of Thyrion (uHexen2) - Open source Hexen II game engine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        uhexen2 = pkgs.stdenv.mkDerivation rec {
          pname = "uhexen2";
          version = "1.5.11-sot";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            gnumake
            pkg-config
            nasm
          ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            alsa-lib.dev
          ];

          buildInputs = with pkgs; [
            SDL
            libGL
            libGLU
            # Audio codec libraries
            flac
            libogg
            libvorbis
            libmad
            libmikmod
            # Optional codecs
            opusfile
            timidity
            wildmidi
          ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            alsa-lib
            xorg.libX11
            xorg.libXext
            xorg.libXxf86dga
            xorg.libXxf86vm
            # Additional libraries the linker might need
            xorg.libXxf86dga
            xorg.libXi
            xorg.libXrandr
            xorg.libXrender
            xorg.libXcursor
          ];

          # Set build configuration
          preBuild = ''
            # Configure build options
            export SDL_CONFIG=${pkgs.SDL}/bin/sdl-config
            export X11BASE=${pkgs.xorg.libX11.dev}

            # Enable all codecs
            export USE_CODEC_WAVE=yes
            export USE_CODEC_FLAC=yes
            export USE_CODEC_MP3=yes
            export USE_CODEC_VORBIS=yes
            export USE_CODEC_OPUS=yes
            export USE_CODEC_MIKMOD=yes
            export USE_CODEC_TIMIDITY=yes
            export MP3LIB=mad
            export VORBISLIB=vorbis

            # Fix C standard incompatibility (code uses 'false' as enum constant)
            # Also allow type conversion issues (old C code)
            # Use -fcommon to allow multiple definitions of globals (old C style)
            # Use gnu99 for for-loop declarations
            # Completely disable pointer type warnings (GCC 15 makes these hard errors)
            export CFLAGS="$CFLAGS -std=gnu99 -fcommon -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-function-declaration"

            # Add OpenGL libraries to linker flags
            export LDFLAGS="-L${pkgs.libGL}/lib -L${pkgs.libGLU}/lib -lGL -lGLU $LDFLAGS"
            export LD_LIBRARY_PATH="${pkgs.libGL}/lib:${pkgs.libGLU}/lib:$LD_LIBRARY_PATH"
          '';

          makeFlags = [
            "CC=${pkgs.stdenv.cc.targetPrefix}cc"
            "NASM=${pkgs.nasm}/bin/nasm"
          ];

          # Build hexen2 client (OpenGL version)
          buildPhase = ''
            runHook preBuild

            echo "Building Hexen2 client (OpenGL)..."
            cd engine/hexen2
            make glh2

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            mkdir -p $out/share/uhexen2

            # Install hexen2 OpenGL binary
            # After buildPhase, we should still be in engine/hexen2
            pwd
            ls -la

            if [ -f glhexen2 ]; then
              echo "Found glhexen2 in current directory, installing..."
              install -Dm755 glhexen2 $out/bin/glhexen2
            elif [ -f engine/hexen2/glhexen2 ]; then
              echo "Found glhexen2 in engine/hexen2, installing..."
              install -Dm755 engine/hexen2/glhexen2 $out/bin/glhexen2
            else
              echo "ERROR: glhexen2 binary not found!"
              echo "Current directory:"
              pwd
              ls -la
              echo "Checking engine/hexen2:"
              ls -la engine/hexen2/ 2>&1 || echo "engine/hexen2 doesn't exist"
              exit 1
            fi

            # Install documentation (from source root)
            cd ${src}
            mkdir -p $out/share/doc/uhexen2
            cp -r docs/* $out/share/doc/uhexen2/ 2>/dev/null || true
            cp README.txt $out/share/doc/uhexen2/ 2>/dev/null || true

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Hexen II: Hammer of Thyrion - Cross-platform Hexen II game engine";
            longDescription = ''
              uHexen2 (Hexen II: Hammer of Thyrion) is a cross-platform port of
              Raven Software's Hexen II game engine. It features:
              - Software and OpenGL rendering
              - Support for mission packs
              - HexenWorld multiplayer client and server
              - Enhanced audio codec support (Ogg Vorbis, MP3, FLAC, MIDI)
              - Cross-platform compatibility

              Note: This package only includes the game engine. You need the
              original game data files to play.
            '';
            homepage = "https://hexenworld.org";
            license = licenses.gpl2Plus;
            maintainers = [ ];
            platforms = platforms.unix;
            mainProgram = "glhexen2";
          };
        };

        # Wrapper script to help users run the game
        uhexen2-launcher = pkgs.writeShellScriptBin "uhexen2-launcher" ''
          #!/bin/sh
          echo "Hexen II: Hammer of Thyrion Launcher"
          echo "====================================="
          echo ""
          echo "Available executables:"
          echo "  glhexen2 - OpenGL renderer (recommended)"
          echo "  hexen2   - Software renderer"
          echo "  glhwcl   - HexenWorld client (OpenGL)"
          echo "  hwcl     - HexenWorld client (software)"
          echo "  hwsv     - HexenWorld server"
          echo ""
          echo "You need the game data files in your current directory or ~/.hexen2/"
          echo "See ${uhexen2}/share/doc/uhexen2/ for more information"
          echo ""

          # Check if game data exists
          if [ -d "./data1" ] || [ -d "$HOME/.hexen2/data1" ]; then
            echo "Game data found. Launching glhexen2..."
            exec ${uhexen2}/bin/glhexen2 "$@"
          else
            echo "ERROR: Game data not found!"
            echo "Please place Hexen II data files in ./data1/ or ~/.hexen2/data1/"
            exit 1
          fi
        '';

        # Windows x64 cross-compilation
        pkgsWindows = pkgs.pkgsCross.mingwW64;

        uhexen2-windows = pkgsWindows.stdenv.mkDerivation rec {
          pname = "uhexen2-windows";
          version = "1.5.11-sot-win";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            gnumake
            nasm
            pkgsWindows.buildPackages.gcc
            pkgsWindows.buildPackages.binutils
          ];

          buildInputs = with pkgsWindows; [
            windows.pthreads
          ];

          preBuild = ''
            export W64BUILD=1
            export CC=${pkgsWindows.stdenv.cc.targetPrefix}cc
            export AS=${pkgsWindows.stdenv.cc.bintools.targetPrefix}as
            export RANLIB=${pkgsWindows.stdenv.cc.bintools.targetPrefix}ranlib
            export AR=${pkgsWindows.stdenv.cc.bintools.targetPrefix}ar
            export WINDRES=${pkgsWindows.stdenv.cc.bintools.targetPrefix}windres
            export NASM=${pkgs.nasm}/bin/nasm

            # Disable codecs that require external libraries for now
            export USE_CODEC_WAVE=yes
            export USE_CODEC_FLAC=no
            export USE_CODEC_MP3=no
            export USE_CODEC_VORBIS=no
            export USE_CODEC_OPUS=no
            export USE_CODEC_MIKMOD=no
            export USE_CODEC_TIMIDITY=no

            # Compiler flags for old C code
            export CFLAGS="-std=gnu99 -fcommon -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-function-declaration"
          '';

          buildPhase = ''
            runHook preBuild

            cd engine/hexen2

            echo "Building OpenGL renderer (glh2.exe)..."
            make glh2

            echo "Building software renderer (h2.exe)..."
            make clean
            make h2

            echo "Building dedicated server (h2ded.exe)..."
            make -C server

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            mkdir -p $out/share/doc/uhexen2

            # Install binaries
            cp glh2.exe $out/bin/
            cp h2.exe $out/bin/
            cp server/h2ded.exe $out/bin/

            # Install required Windows DLLs from oslibs
            cd ${src}
            cp oslibs/windows/codecs/x64/*.dll $out/bin/ || echo "Warning: codec DLLs not found"
            cp oslibs/windows/SDL/lib64/SDL.dll $out/bin/ || echo "Warning: SDL.dll not found"

            # Install documentation
            cp -r docs/* $out/share/doc/uhexen2/ 2>/dev/null || true
            cp README.txt $out/share/doc/uhexen2/ 2>/dev/null || true

            # Create a README for Windows users
            cat > $out/bin/README-WINDOWS.txt <<EOF
Hexen II: Hammer of Thyrion - Windows x64 Build

Files included:
- glh2.exe: OpenGL renderer (recommended)
- h2.exe: Software renderer
- h2ded.exe: Dedicated server
- *.dll: Required runtime libraries

To play:
1. Copy your Hexen II game data files (pak0.pak, pak1.pak, etc.) to a 'data1' folder
2. Run glh2.exe from the same directory

For more information, see the documentation in the share/doc folder.
EOF

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Hexen II: Hammer of Thyrion - Windows x64 build";
            homepage = "https://hexenworld.org";
            license = licenses.gpl2Plus;
            platforms = platforms.windows;
          };
        };

      in
      {
        packages = {
          default = uhexen2;
          uhexen2 = uhexen2;
          launcher = uhexen2-launcher;
          windows = uhexen2-windows;
        };

        apps = {
          default = {
            type = "app";
            program = "${uhexen2-launcher}/bin/uhexen2-launcher";
          };
          glhexen2 = {
            type = "app";
            program = "${uhexen2}/bin/glhexen2";
          };
          hexen2 = {
            type = "app";
            program = "${uhexen2}/bin/hexen2";
          };
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ uhexen2 ];
          buildInputs = with pkgs; [
            # Development tools
            gdb
            valgrind
          ];

          shellHook = ''
            echo "uHexen2 development environment"
            echo "Source: ${uhexen2.src}"
          '';
        };
      }
    );
}

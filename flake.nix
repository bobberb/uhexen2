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

        # Common derivation attributes shared between Linux and Windows
        commonAttrs = {
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

          # Common codec flags
          codecFlags = {
            USE_CODEC_WAVE = "yes";
            USE_CODEC_FLAC = "yes";
            USE_CODEC_MP3 = "yes";
            USE_CODEC_VORBIS = "yes";
            USE_CODEC_OPUS = "yes";
            USE_CODEC_MIKMOD = "yes";
            USE_CODEC_TIMIDITY = "yes";
            MP3LIB = "mad";
            VORBISLIB = "vorbis";
          };

          # Common CFLAGS for old C code compatibility
          commonCFlags = "-std=gnu99 -fcommon -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-function-declaration";

          meta = with pkgs.lib; {
            description = "Hexen II: Hammer of Thyrion - Cross-platform Hexen II game engine";
            longDescription = ''
              uHexen2 (Hexen II: Hammer of Thyrion) is a cross-platform port of
              Raven Software's Hexen II game engine. It features:
              - OpenGL rendering
              - Support for mission packs and mods (SoT, Wheel of Karma)
              - Enhanced audio codec support (Ogg Vorbis, MP3, FLAC, Opus, MIDI)
              - Cross-platform compatibility

              Note: This package only includes the game engine. You need the
              original game data files to play.
            '';
            homepage = "https://hexenworld.org";
            license = licenses.gpl2Plus;
            maintainers = [ ];
            platforms = platforms.unix ++ platforms.windows;
            mainProgram = "glhexen2";
          };
        };

        # Linux build
        uhexen2 = pkgs.stdenv.mkDerivation (commonAttrs // {
          buildInputs = with pkgs; [
            SDL
            libGL
            libGLU
            flac
            libogg
            libvorbis
            libmad
            libmikmod
            opusfile
            timidity
            wildmidi
          ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            alsa-lib
            xorg.libX11
            xorg.libXext
            xorg.libXxf86dga
            xorg.libXxf86vm
            xorg.libXi
            xorg.libXrandr
            xorg.libXcursor
          ];

          makeFlags = [
            "CC=${pkgs.stdenv.cc.targetPrefix}cc"
            "NASM=${pkgs.nasm}/bin/nasm"
          ];

          buildPhase = ''
            runHook preBuild
            cd engine/hexen2

            # Set codec flags
            export USE_CODEC_WAVE=yes
            export USE_CODEC_FLAC=yes
            export USE_CODEC_MP3=yes
            export USE_CODEC_VORBIS=yes
            export USE_CODEC_OPUS=yes
            export USE_CODEC_MIKMOD=yes
            export USE_CODEC_TIMIDITY=yes
            export MP3LIB=mad
            export VORBISLIB=vorbis

            # Set CFLAGS
            export CFLAGS="$CFLAGS -std=gnu99 -fcommon -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-function-declaration"

            make glh2
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin $out/share/doc/uhexen2

            # Install binary from known build location
            install -Dm755 glhexen2 $out/bin/glhexen2

            # Install documentation
            cp -r docs/* $out/share/doc/uhexen2/ 2>/dev/null || true
            cp README.txt $out/share/doc/uhexen2/ 2>/dev/null || true

            runHook postInstall
          '';
        });

        # Windows x64 cross-compilation
        pkgsWindows = pkgs.pkgsCross.mingwW64;

        uhexen2-windows = pkgsWindows.stdenv.mkDerivation (commonAttrs // {
          pname = "uhexen2-windows";

          nativeBuildInputs = with pkgs; [
            gnumake
            nasm
            pkgsWindows.buildPackages.gcc
            pkgsWindows.buildPackages.binutils
          ];

          buildInputs = with pkgsWindows; [
            windows.pthreads
          ];

          buildPhase = ''
            runHook preBuild
            cd engine/hexen2

            # Windows cross-compilation setup
            export W64BUILD=1
            export CC=${pkgsWindows.stdenv.cc.targetPrefix}cc
            export AS=${pkgsWindows.stdenv.cc.bintools.targetPrefix}as
            export RANLIB=${pkgsWindows.stdenv.cc.bintools.targetPrefix}ranlib
            export AR=${pkgsWindows.stdenv.cc.bintools.targetPrefix}ar
            export WINDRES=${pkgsWindows.stdenv.cc.bintools.targetPrefix}windres
            export NASM=${pkgs.nasm}/bin/nasm

            # Disable external codecs for Windows (simpler build)
            export USE_CODEC_WAVE=yes
            export CFLAGS="-std=gnu99 -fcommon -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-function-declaration"

            # Build all targets without clean between
            echo "Building OpenGL renderer (glh2.exe)..."
            make glh2

            echo "Building software renderer (h2.exe)..."
            make h2

            echo "Building dedicated server (h2ded.exe)..."
            make -C server

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin $out/share/doc/uhexen2

            # Install binaries
            cp glh2.exe $out/bin/
            cp h2.exe $out/bin/
            cp server/h2ded.exe $out/bin/

            # Install Windows DLLs from oslibs
            find $src/oslibs/windows -name "*.dll" -exec cp {} $out/bin/ \; 2>/dev/null || true

            # Install documentation
            cp -r $src/docs/* $out/share/doc/uhexen2/ 2>/dev/null || true
            cp $src/README.txt $out/share/doc/uhexen2/ 2>/dev/null || true

            # Create README for Windows users
            cat > $out/bin/README.txt <<EOF
Hexen II: Hammer of Thyrion - Windows x64 Build

Files included:
- glh2.exe: OpenGL renderer (recommended)
- h2.exe: Software renderer
- h2ded.exe: Dedicated server
- *.dll: Required runtime libraries

To play:
1. Copy your Hexen II game data files (pak0.pak, pak1.pak, etc.) to a 'data1' folder
2. Copy Portal of Praevus files (pak3.pak) to a 'portals' folder (for mods)
3. Run glh2.exe from the same directory

For mods like SoT or Wheel of Karma, use: glh2.exe -mod <modname>
EOF

            runHook postInstall
          '';
        });

      in
      {
        packages = {
          default = uhexen2;
          inherit uhexen2 uhexen2-windows;
        };

        apps = {
          default = {
            type = "app";
            program = "${uhexen2}/bin/glhexen2";
          };
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ uhexen2 ];
          buildInputs = with pkgs; [ gdb valgrind ];
          shellHook = ''
            echo "uHexen2 development environment"
            echo "Build with: nix build .#uhexen2"
          '';
        };
      }
    );
}

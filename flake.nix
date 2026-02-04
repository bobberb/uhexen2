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
          default = pkgs.stdenv.mkDerivation {
            pname = "glhexen2";
            inherit version;

            src = ./.;

            nativeBuildInputs = with pkgs; [
              pkg-config
            ];

            buildInputs = with pkgs; [
              SDL
              libGL
              libmad         # MP3 support
              libvorbis      # Vorbis support
              libogg
              alsa-lib       # ALSA audio support
            ];

            preBuild = ''
              cd engine/hexen2
            '';

            makeFlags = [
              "TARGET_OS=unix"
            ];

            buildPhase = ''
              runHook preBuild
              make glh2
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              mkdir -p $out/share/uhexen2

              # Install the OpenGL binary
              install -Dm755 glhexen2 $out/bin/glhexen2

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

          # Software renderer version (hexen2)
          hexen2-sw = pkgs.stdenv.mkDerivation {
            pname = "hexen2";
            inherit version;

            src = ./.;

            nativeBuildInputs = with pkgs; [
              pkg-config
            ];

            buildInputs = with pkgs; [
              SDL
              libmad
              libvorbis
              libogg
              alsa-lib
            ];

            preBuild = ''
              cd engine/hexen2
            '';

            makeFlags = [
              "TARGET_OS=unix"
            ];

            buildPhase = ''
              runHook preBuild
              make h2
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              mkdir -p $out/share/uhexen2

              install -Dm755 hexen2 $out/bin/hexen2

              if [ -d ../../libs/timidity ]; then
                cp -r ../../libs/timidity $out/share/uhexen2/
              fi

              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Hammer of Thyrion - Hexen II source port (software renderer)";
              homepage = "https://uhexen2.sourceforge.net/";
              license = licenses.gpl2Plus;
              platforms = platforms.linux;
              maintainers = [ ];
              mainProgram = "hexen2";
            };
          };

          # Dedicated server
          h2ded = pkgs.stdenv.mkDerivation {
            pname = "h2ded";
            inherit version;

            src = ./.;

            nativeBuildInputs = with pkgs; [
              pkg-config
            ];

            buildInputs = with pkgs; [
              SDL
            ];

            preBuild = ''
              cd engine/hexen2/server
            '';

            makeFlags = [
              "TARGET_OS=unix"
            ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              install -Dm755 h2ded $out/bin/h2ded

              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Hammer of Thyrion - Hexen II dedicated server";
              homepage = "https://uhexen2.sourceforge.net/";
              license = licenses.gpl2Plus;
              platforms = platforms.linux;
              maintainers = [ ];
              mainProgram = "h2ded";
            };
          };

          # Full bundle with all binaries
          uhexen2-full = pkgs.symlinkJoin {
            name = "uhexen2-full-${version}";
            paths = [
              self.packages.${system}.default
              self.packages.${system}.hexen2-sw
              self.packages.${system}.h2ded
            ];

            meta = with pkgs.lib; {
              description = "Hammer of Thyrion - Complete Hexen II source port bundle";
              homepage = "https://uhexen2.sourceforge.net/";
              license = licenses.gpl2Plus;
              platforms = platforms.linux;
            };
          };
        };

        # Development shell for building and testing
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            SDL
            libGL
            libmad
            libvorbis
            libogg
            alsa-lib
            pkg-config
            gcc
            gnumake
          ];

          shellHook = ''
            echo "uHexen2 development environment"
            echo "Available build targets:"
            echo "  make glh2    - OpenGL version"
            echo "  make h2      - Software renderer"
            echo ""
            echo "Build directory: engine/hexen2"
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

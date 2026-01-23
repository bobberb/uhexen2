# uHexen2 Nix Flake

A Nix flake for building [Hexen II: Hammer of Thyrion (uHexen2)](https://hexenworld.org) - a cross-platform port of Raven Software's Hexen II game engine.

## Features

- Software and OpenGL rendering
- Enhanced audio codec support (Ogg Vorbis, MP3, FLAC, MIDI, MikMod)
- ALSA and OSS audio support (Linux)
- X11 and SDL integration

## Building

```bash
# Build the default package
nix build .#uhexen2

# Or from the flake directly
nix build github:USER/REPO#uhexen2
```

## Running

```bash
# Use the launcher (checks for game data)
nix run .#default

# Or run directly
nix run .#glhexen2  # OpenGL renderer
nix run .#hexen2    # Software renderer
```

## Development

```bash
# Enter development shell
nix develop

# Build manually
cd $src/engine/hexen2
make glh2
make h2
```

## Game Data

**Important:** This package only builds the game engine. You need the original Hexen II game data files to play.

Place your game data in one of these locations:
- `./data1/` (current directory)
- `~/.hexen2/data1/`

The game data should include files like:
- `pak0.pak`
- `pak1.pak`
- Various `.pak` files from the original game

## Package Contents

The built package includes:
- `/bin/glhexen2` - OpenGL renderer (recommended)
- `/bin/hexen2` - Software renderer
- `/share/doc/uhexen2/` - Documentation

## Outputs

- `packages.default` / `packages.uhexen2` - Main game engine
- `packages.launcher` - Wrapper script with game data detection
- `apps.default` - Runs the launcher
- `apps.glhexen2` - Runs OpenGL version directly
- `apps.hexen2` - Runs software version directly
- `devShells.default` - Development environment

## License

- uHexen2 engine: GPL-2.0-or-later
- Original Hexen II game data: Commercial (not included)

## Links

- Project homepage: https://hexenworld.org
- GitHub mirror: https://github.com/Shanjaq/uhexen2
- Original SourceForge: http://uhexen2.sourceforge.net/

## Notes

- The package uses SDL 1.2 compatibility layer
- ALSA is enabled by default on Linux
- All audio codecs are included for maximum compatibility
- The engine supports mission packs when the corresponding data files are present

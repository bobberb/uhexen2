# uHexen2 Nix Flake

A Nix flake for building [Hexen II: Hammer of Thyrion (uHexen2)](https://hexenworld.org) - a cross-platform port of Raven Software's Hexen II game engine.

## Features

- Software and OpenGL rendering
- Enhanced audio codec support (Ogg Vorbis, MP3, FLAC, Opus, MIDI, MikMod)
- ALSA and OSS audio support (Linux)
- X11 and SDL integration
- **SoT mod compatibility** - Storm Over Thyrion and related Portals-based mods
- Multi-platform builds (Linux, Windows, Flatpak/Steam Deck)

## Available Packages

| Package | Description |
|---------|-------------|
| `default` / `uhexen2` | Main OpenGL client for NixOS/Nix |
| `fhs` | FHS-compatible build for non-Nix Linux (Ubuntu, Debian, Arch) |
| `windows` | Windows x64 cross-compiled build |
| `flatpak` | Universal Linux package (Steam Deck compatible) |
| `release` | Multi-platform release bundle |
| `launcher` | Helper script with game data detection |

## Building

```bash
# Build for NixOS/Nix (default)
nix build .#uhexen2

# Build FHS version (for non-Nix Linux)
nix build .#fhs

# Build Windows version
nix build .#windows

# Build Flatpak (for Steam Deck / universal Linux)
cd flatpak && ./build.sh

# Build release bundle (all platforms)
nix build .#release
```

## Running

### NixOS/Nix

```bash
# Use the launcher (checks for game data)
nix run .

# Or run directly
nix run .#uhexen2               # OpenGL renderer
nix run .#uhexen2 -- -game sot  # Play SoT mod
nix run .#uhexen2 -- -mod wok   # Play Wheel of Karma mod
```

### Non-Nix Linux (Ubuntu/Debian/Arch)

```bash
# Build the FHS version
nix build .#fhs

# The binary will be in result-fhs/bin/glhexen2
# Install required libraries:
# Ubuntu/Debian: sudo apt install libsdl1.2 libvorbisfile3 libmad0
# Arch:          sudo pacman -S sdl1.2-compat libvorbis libmad

# Run from your game directory
./result-fhs/bin/glhexen2 -game sot
```

### Windows

```bash
# Build Windows version
nix build .#windows

# Copy contents of result-windows/bin/ to your game directory
# Includes: glh2.exe, h2.exe, h2ded.exe, and required DLLs
```

### Flatpak (Steam Deck / Universal Linux)

```bash
# Build Flatpak package
cd flatpak
./build.sh

# Run the Flatpak
flatpak run com.github.bobberb.uhexen2

# Run with SoT mod
flatpak run com.github.bobberb.uhexen2 -- -game sot

# Create distributable bundle
flatpak build-bundle flatpak-repo com.github.bobberb.uhexen2.flatpak com.github.bobberb.uhexen2
```

**For Steam Deck:**
1. Switch to Desktop mode
2. Open terminal and run build script
3. Add as Non-Steam Game in Steam:
   - Games → Add a Non-Steam Game → Browse → select Flatpak
4. Switch back to Gaming mode

## Mod Support

### Storm Over Thyrion (SoT)

The SoT mod requires launching with `-game sot` to load Portals assets:

```bash
nix run .#uhexen2 -- -game sot
```

### Wheel of Karma and other Portals-based Mods

Use the `-mod` flag for Portals-based mods like Wheel of Karma:

```bash
nix run .#uhexen2 -- -mod wok
```

This automatically loads Portals assets before the mod directory.

### Other Mods

For mods that don't require Portals assets, use `-game`:

```bash
nix run .#uhexen2 -- -game modname
```

## Development

```bash
# Enter development shell
nix develop

# Build manually
cd engine/hexen2
make glh2    # OpenGL renderer
make h2      # Software renderer

# Build Windows cross-compile
make -C ../..
nix build .#windows
```

## Game Data

**Important:** This package only builds the game engine. You need the original Hexen II game data files to play.

### Required Files

Place your game data in one of these locations:
- `./data1/` (current directory)
- `~/.hexen2/data1/`

The game data should include:
- `pak0.pak`, `pak1.pak` - Base game files
- `pak2.pak` - OEM version (if applicable)
- `pak3.pak` - Portal of Praevus expansion (optional)

### For SoT Mod

The SoT mod requires the Portal of Praevus expansion (pak3.pak) to be installed. The `-game sot` flag will automatically load Portals assets along with the SoT mod files.

## Package Contents

The `uhexen2` package includes:
- `/bin/glhexen2` - OpenGL renderer (recommended)
- `/share/doc/uhexen2/` - Documentation

The `windows` package includes:
- `glh2.exe` - OpenGL renderer (with full codec support)
- `h2.exe` - Software renderer
- `h2ded.exe` - Dedicated server
- `*.dll` - Required runtime libraries (SDL, FLAC, MP3, Vorbis, Opus, MikMod)

The `flatpak` package includes:
- `/app/bin/glhexen2` - OpenGL renderer (with full codec support)
- `/app/share/doc/uhexen2/` - Documentation
- Desktop integration (application entry, metainfo)

## Outputs

| Output | Description |
|--------|-------------|
| `packages.default` / `packages.uhexen2` | Main game engine |
| `packages.fhs` | FHS-compatible Linux build |
| `packages.windows` | Windows x64 build |
| `packages.release` | Multi-platform release bundle |
| `packages.launcher` | Wrapper script with game data detection |
| `flatpak/` | Flatpak manifest and build script |
| `apps.default` | Runs the launcher |
| `apps.glhexen2` | Runs OpenGL version directly |
| `devShells.default` | Development environment |

## License

- uHexen2 engine: GPL-2.0-or-later
- Original Hexen II game data: Commercial (not included)

## Links

- Project homepage: https://hexenworld.org
- GitHub: https://github.com/bobberb/uhexen2
- Original SourceForge: http://uhexen2.sourceforge.net/

## Version Information

This is version **1.5.11-sot** based on the sakabato branch with:
- SoT mod compatibility
- Arbitrary resolution support
- Enhanced protocol handling
- Multi-platform build support (Nix, FHS, Windows, Flatpak)

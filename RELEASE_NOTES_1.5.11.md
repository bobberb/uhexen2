## uHexen2 1.5.11 Release Notes

### Overview
This release adds compatibility for the **Storm Over Thyrion (SoT)** mod, along with various engine improvements and bug fixes.

### New Features
- **SoT Mod Support**: Added `PF_print_indexed` builtin (#111) and `PF_name_print` for non-HexenWorld builds
- **Enhanced Protocol Handling**: Gracefully handles unknown protocol messages (>80) instead of crashing

### Bug Fixes  
- **Model Loading**: Removed obsolete texture alignment check (`s&3`) that prevented loading models with non-multiple-of-4 dimensions
- **Charset Loading**: Fixed conchars.lmp to handle SoT mod format (32776 bytes with qpic header) in addition to original format (32768 bytes)
- **Menu System**: Fixed `FS_LoadTempFile` calls with incorrect argument counts
- **Variable Names**: Corrected `glmodes` → `gl_texmodes` and `glmode_idx` → `gl_filter_idx` in menu code
- **Print Indexed**: Added support for negative indices (0x80000000 sentinel for "clear message")
- **Texture Upload**: Changed from 4-byte chunk processing to byte-by-byte for non-aligned textures

### Build System
- Source now builds from local directory instead of fetching from remote
- Windows cross-compilation installPhase path fixed
- Updated to use modern dependencies and compilers (GCC 15 compatible)

### Compatibility Notes
- SoT mod requires launching with `-game sot` or `-game ros`
- Some SoT custom protocol messages (89, 114) are handled gracefully; full implementation pending
- Text display works best when using `-game ros` to load the correct conchars.lmp

### Technical Changes
- Engine: `MAX_SKIN_HEIGHT` is 2048 (preventing some mod crashes)
- Protocol messages 80+ are skipped with debug warning instead of crashing
- Builtins now available on both HexenWorld and non-HexenWorld builds

### Known Issues
- SoT mod's custom protocol messages (89, 114) payloads not fully implemented
- "fog" and "r_skyfog" cvars not recognized (mod-specific, not engine)
- Some sound files may not be found (mod content issue)

### Contributors
- sakabato (original SoT port compatibility work)
- Claude Opus 4.5 (engine fixes and build system updates)

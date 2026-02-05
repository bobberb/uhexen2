# CMake build for Hexen II OpenGL client (glhexen2)
# Builds for: Windows (32/64-bit) and Linux (x86_64)

cmake_minimum_required(VERSION 3.16)
project(glhexen2 VERSION 1.5.10 LANGUAGES C)

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Project paths
set(ENGINE_TOP ${CMAKE_CURRENT_SOURCE_DIR})
set(COMMONDIR ${ENGINE_TOP}/h2shared)
set(UHEXEN2_TOP ${CMAKE_CURRENT_SOURCE_DIR}/..)
set(UHEXEN2_SHARED ${UHEXEN2_TOP}/common)
set(LIBS_DIR ${UHEXEN2_TOP}/libs)
set(OSLIBS ${UHEXEN2_TOP}/oslibs)

#============================================================================
# Build Options
#============================================================================
option(USE_DEBUG "Debug build" OFF)
option(USE_SOUND "Enable sound support" ON)
option(USE_ALSA "Enable ALSA audio (Linux)" ON)
option(USE_CODEC_VORBIS "Enable Ogg Vorbis codec" ON)
option(USE_CODEC_MP3 "Enable MP3 codec (mad)" ON)
option(USE_CODEC_FLAC "Enable FLAC codec" ON)
option(USE_CODEC_OPUS "Enable Opus codec" OFF)
option(USE_CODEC_TIMIDITY "Enable Timidity MIDI" ON)
option(USE_CODEC_XMP "Enable XMP codec" OFF)

#============================================================================
# Platform Detection
#============================================================================
if(WIN32)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(TARGET_OS "win64")
        set(ARCH_DIR "x64")
    else()
        set(TARGET_OS "win32")
        set(ARCH_DIR "x86")
    endif()
elseif(UNIX AND NOT APPLE)
    set(TARGET_OS "unix")
elseif(APPLE)
    set(TARGET_OS "darwin")
    message(FATAL_ERROR "macOS is not supported in this CMake port")
else()
    message(FATAL_ERROR "Unsupported platform: ${CMAKE_SYSTEM_NAME}")
endif()

#============================================================================
# Compiler Flags
#============================================================================
if(MSVC)
    # Not supported - use GCC/MinGW for Windows
    message(FATAL_ERROR "MSVC is not supported. Use MinGW-w64 for Windows builds.")
endif()

# Common flags
add_compile_options(-Wall)

if(USE_DEBUG)
    add_compile_options(-g -DDEBUG=1 -DDEBUG_BUILD=1)
else()
    add_compile_options(-O2 -DNDEBUG=1 -ffast-math -fomit-frame-pointer)
endif()

# Platform-specific defines
if(WIN32)
    add_definitions(-DWIN32_LEAN_AND_MEAN -DGLQUAKE)
    # Windows uses native DirectSound/WaveOut, not SDL audio
    # Windows doesn't use ALSA
    set(USE_ALSA OFF)
    set(USE_CODEC_TIMIDITY OFF)  # Windows has native MIDI
elseif(UNIX AND NOT APPLE)
    add_definitions(-DGLQUAKE -DSDLQUAKE -D_GNU_SOURCE=1 -D_REENTRANT -DGL_DLSYM)
endif()

#============================================================================
# Include Directories
#============================================================================
include_directories(
    ${ENGINE_TOP}/hexen2
    ${COMMONDIR}
    ${UHEXEN2_SHARED}
)

# Windows-specific includes
if(WIN32)
    include_directories(${OSLIBS}/windows/misc/include)
endif()

#============================================================================
# Find Dependencies
#============================================================================
# SDL is required (currently using SDL 1.2, SDL2 port pending)
# TODO: Port to SDL2 (see uhexen2-imay)
if(WIN32)
    # Use prebuilt SDL from oslibs for Windows
    set(SDL_INCLUDE_DIR ${OSLIBS}/windows/SDL/include)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(SDL_LIBRARY
            ${OSLIBS}/windows/SDL/lib64/libSDLmain.a
            ${OSLIBS}/windows/SDL/lib64/libSDL.dll.a
        )
    else()
        set(SDL_LIBRARY
            ${OSLIBS}/windows/SDL/lib/libSDLmain.a
            ${OSLIBS}/windows/SDL/lib/libSDL.dll.a
        )
    endif()
    set(SDL_FOUND TRUE)
else()
    find_package(SDL REQUIRED)
endif()

if(UNIX AND NOT APPLE)
    # OpenGL
    find_package(OpenGL REQUIRED)

    # Find packages using pkg-config
    find_package(PkgConfig QUIET)
    if(NOT PKG_CONFIG_FOUND)
        message(FATAL_ERROR "pkg-config is required for Linux builds")
    endif()

    # ALSA
    if(USE_ALSA)
        pkg_check_modules(ALSA REQUIRED alsa)
        set(USE_ALSA_FOUND ON)
    endif()

    # Audio codecs (use system libraries on Linux)
    if(USE_CODEC_VORBIS)
        pkg_check_modules(VORBIS REQUIRED vorbisfile vorbis ogg)
    endif()

    if(USE_CODEC_MP3)
        pkg_check_modules(MAD REQUIRED mad)
    endif()

    if(USE_CODEC_FLAC)
        pkg_check_modules(FLAC REQUIRED flac)
    endif()

    if(USE_CODEC_OPUS)
        pkg_check_modules(OPUSFILE REQUIRED opusfile)
    endif()

    if(USE_CODEC_XMP)
        pkg_check_modules(XMP REQUIRED xmp)
    endif()

    # m and dl
    find_library(M_LIBRARY m)
    find_library(DL_LIBRARY dl)
endif()

if(WIN32)
    # For Windows, use prebuilt codecs from oslibs
    set(CODEC_INCLUDE_DIR ${OSLIBS}/windows/codecs/include)
    set(CODEC_LIB_DIR ${OSLIBS}/windows/codecs/${ARCH_DIR})
    include_directories(${CODEC_INCLUDE_DIR})
    link_directories(${CODEC_LIB_DIR})
endif()

#============================================================================
# Timidity Library
#============================================================================
if(USE_CODEC_TIMIDITY)
    include_directories(${LIBS_DIR}/timidity)
    add_definitions(-DTIMIDITY_STATIC=1)

    # Check if prebuilt timidity exists, otherwise build it
    if(TARGET_OS STREQUAL "unix")
        set(TIMIDITY_LIB ${LIBS_DIR}/timidity/libtimidity.a)
        if(NOT EXISTS ${TIMIDITY_LIB})
            message(STATUS "Building timidity library...")
            execute_process(
                COMMAND make clean
                COMMAND make
                WORKING_DIRECTORY ${LIBS_DIR}/timidity
                ECHO_OUTPUT_VARIABLE
            )
        endif()
        if(EXISTS ${TIMIDITY_LIB})
            set(TIMIDITY_FOUND ON)
        else()
            message(WARNING "Timidity library not found, disabling")
            set(USE_CODEC_TIMIDITY OFF)
        endif()
    endif()
endif()

#============================================================================
# Source Files
#============================================================================

# GL Renderer sources
set(GL_RENDERER_SOURCES
    # From hexen2 (client-specific GL)
    ${ENGINE_TOP}/hexen2/gl_rmain.c
    ${ENGINE_TOP}/hexen2/gl_rmisc.c
    ${ENGINE_TOP}/hexen2/gl_rsurf.c
    ${ENGINE_TOP}/hexen2/r_part.c
    # From h2shared
    ${COMMONDIR}/gl_refrag.c
    ${COMMONDIR}/gl_rlight.c
    ${COMMONDIR}/gl_sky.c
    ${COMMONDIR}/gl_screen.c
    ${COMMONDIR}/gl_warp.c
    ${COMMONDIR}/gl_draw.c
    ${COMMONDIR}/gl_fog.c
    ${COMMONDIR}/gl_mesh.c
    ${COMMONDIR}/gl_model.c
    ${COMMONDIR}/gl_texmgr.c
    ${COMMONDIR}/image.c
    ${COMMONDIR}/img_load.c
)

# Client sources from hexen2
set(CLIENT_SOURCES
    ${ENGINE_TOP}/hexen2/cl_demo.c
    ${ENGINE_TOP}/hexen2/cl_effect.c
    ${ENGINE_TOP}/hexen2/cl_inlude.c
    ${ENGINE_TOP}/hexen2/cl_input.c
    ${ENGINE_TOP}/hexen2/cl_main.c
    ${ENGINE_TOP}/hexen2/cl_parse.c
    ${ENGINE_TOP}/hexen2/cl_string.c
    ${ENGINE_TOP}/hexen2/cl_tent.c
    ${ENGINE_TOP}/hexen2/cl_cmd.c
    ${ENGINE_TOP}/hexen2/console.c
    ${ENGINE_TOP}/hexen2/keys.c
    ${ENGINE_TOP}/hexen2/menu.c
    ${ENGINE_TOP}/hexen2/sbar.c
    ${ENGINE_TOP}/hexen2/view.c
    ${ENGINE_TOP}/hexen2/chase.c
)

# Server and common sources
set(COMMON_SOURCES
    # From hexen2
    ${ENGINE_TOP}/hexen2/host.c
    ${ENGINE_TOP}/hexen2/host_cmd.c
    ${ENGINE_TOP}/hexen2/sv_main.c
    ${ENGINE_TOP}/hexen2/sv_phys.c
    ${ENGINE_TOP}/hexen2/sv_user.c
    ${ENGINE_TOP}/hexen2/sv_effect.c
    ${ENGINE_TOP}/hexen2/sv_move.c
    ${ENGINE_TOP}/hexen2/world.c
    ${ENGINE_TOP}/hexen2/net_main.c
    ${ENGINE_TOP}/hexen2/net_loop.c
    ${ENGINE_TOP}/hexen2/net_dgrm.c
    # From h2shared
    ${COMMONDIR}/cmd.c
    ${COMMONDIR}/cvar.c
    ${COMMONDIR}/pr_cmds.c
    ${COMMONDIR}/pr_edict.c
    ${COMMONDIR}/pr_exec.c
    ${COMMONDIR}/mathlib.c
    ${COMMONDIR}/sizebuf.c
    ${COMMONDIR}/link_ops.c
    ${COMMONDIR}/hashindex.c
    ${COMMONDIR}/zone.c
    ${COMMONDIR}/quakefs.c
    ${COMMONDIR}/debuglog.c
    ${COMMONDIR}/host_string.c
    ${COMMONDIR}/cfgfile.c
    ${COMMONDIR}/common.c
    ${COMMONDIR}/wad.c
    ${COMMONDIR}/msg_io.c
    # From common directory
    ${UHEXEN2_SHARED}/qsnprint.c
    ${UHEXEN2_SHARED}/strlcat.c
    ${UHEXEN2_SHARED}/strlcpy.c
    ${UHEXEN2_SHARED}/q_endian.c
    ${UHEXEN2_SHARED}/crc.c
)

#============================================================================
# Sound Sources
#============================================================================
if(USE_SOUND)
    set(SOUND_SOURCES
        ${COMMONDIR}/snd_sys.c
        ${COMMONDIR}/snd_dma.c
        ${COMMONDIR}/snd_mix.c
        ${COMMONDIR}/snd_mem.c
        ${COMMONDIR}/snd_wave.c
        ${COMMONDIR}/snd_mp3tag.c
        ${COMMONDIR}/bgmusic.c
        ${COMMONDIR}/snd_codec.c
    )

    # Optional codecs
    if(USE_CODEC_VORBIS)
        list(APPEND SOUND_SOURCES ${COMMONDIR}/snd_vorbis.c)
        add_definitions(-DUSE_CODEC_VORBIS)
    endif()

    if(USE_CODEC_MP3)
        list(APPEND SOUND_SOURCES ${COMMONDIR}/snd_mp3.c)
        add_definitions(-DUSE_CODEC_MP3)
    endif()

    if(USE_CODEC_FLAC)
        list(APPEND SOUND_SOURCES ${COMMONDIR}/snd_flac.c)
        add_definitions(-DUSE_CODEC_FLAC)
    endif()

    if(USE_CODEC_OPUS)
        list(APPEND SOUND_SOURCES ${COMMONDIR}/snd_opus.c)
        add_definitions(-DUSE_CODEC_OPUS)
    endif()

    if(USE_CODEC_XMP)
        list(APPEND SOUND_SOURCES ${COMMONDIR}/snd_xmp.c)
        add_definitions(-DUSE_CODEC_XMP)
    endif()

    if(USE_CODEC_TIMIDITY)
        list(APPEND SOUND_SOURCES ${COMMONDIR}/snd_timidity.c)
        add_definitions(-DUSE_CODEC_TIMIDITY)
    endif()

    if(USE_CODEC_WAVE)
        add_definitions(-DUSE_CODEC_WAVE)
    endif()

    # Platform-specific sound
    if(WIN32)
        list(APPEND SOUND_SOURCES
            ${COMMONDIR}/snd_win.c
            ${COMMONDIR}/snd_dsound.c
        )
    elseif(UNIX AND NOT APPLE)
        # Use SDL for audio on Unix/Linux
        list(APPEND SOUND_SOURCES ${COMMONDIR}/snd_sdl.c)
        if(USE_ALSA_FOUND)
            list(APPEND SOUND_SOURCES ${COMMONDIR}/snd_alsa.c)
        else()
            add_definitions(-DNO_ALSA_AUDIO)
        endif()
    endif()
else()
    set(SOUND_SOURCES ${COMMONDIR}/snd_null.c ${COMMONDIR}/bgmnull.c)
    add_definitions(-D_NO_SOUND)
endif()

#============================================================================
# Platform-Specific Sources
#============================================================================
if(WIN32)
    # Video
    list(APPEND PLATFORM_SOURCES ${COMMONDIR}/gl_vidnt.c)

    # Input
    list(APPEND PLATFORM_SOURCES ${COMMONDIR}/in_win.c)

    # Network
    list(APPEND PLATFORM_SOURCES
        ${ENGINE_TOP}/hexen2/net_win.c
        ${ENGINE_TOP}/hexen2/net_wins.c
        ${ENGINE_TOP}/hexen2/net_wipx.c
    )

    # System
    list(APPEND PLATFORM_SOURCES ${ENGINE_TOP}/hexen2/sys_win.c)

    # MIDI
    list(APPEND PLATFORM_SOURCES
        ${COMMONDIR}/midi_win.c
        ${COMMONDIR}/mid2strm.c
    )

    # CD Audio
    list(APPEND PLATFORM_SOURCES ${COMMONDIR}/cd_win.c)

    # Resources
    set(RESOURCES ${COMMONDIR}/win32res.rc)

    # DirectX dynamic loading (default)
    add_definitions(-DDX_DLSYM)

elseif(UNIX AND NOT APPLE)
    # Video
    list(APPEND PLATFORM_SOURCES ${COMMONDIR}/gl_vidsdl.c)

    # Input
    list(APPEND PLATFORM_SOURCES ${COMMONDIR}/in_sdl.c)

    # Network
    list(APPEND PLATFORM_SOURCES
        ${ENGINE_TOP}/hexen2/net_bsd.c
        ${ENGINE_TOP}/hexen2/net_udp.c
    )

    # System
    list(APPEND PLATFORM_SOURCES
        ${ENGINE_TOP}/hexen2/sys_unix.c
        ${COMMONDIR}/sys_sdl.c
    )

    # MIDI (null driver for Linux)
    list(APPEND PLATFORM_SOURCES ${COMMONDIR}/midi_nul.c)
    add_definitions(-D_NO_MIDIDRV)

    # CD Audio
    list(APPEND PLATFORM_SOURCES
        ${COMMONDIR}/cd_sdl.c
        ${COMMONDIR}/cd_bsd.c
        ${COMMONDIR}/cd_linux.c
    )
endif()

#============================================================================
# Create Executable
#============================================================================
# Combine all sources
set(ALL_SOURCES
    ${GL_RENDERER_SOURCES}
    ${CLIENT_SOURCES}
    ${COMMON_SOURCES}
    ${SOUND_SOURCES}
    ${PLATFORM_SOURCES}
)

# Create the executable
if(WIN32)
    set(EXECUTABLE_NAME glh2)
    add_executable(${EXECUTABLE_NAME} WIN32 ${ALL_SOURCES} ${RESOURCES})
else()
    set(EXECUTABLE_NAME glhexen2)
    add_executable(${EXECUTABLE_NAME} ${ALL_SOURCES})
endif()

#============================================================================
# Link Libraries
#============================================================================
# SDL is always required
target_link_libraries(${EXECUTABLE_NAME} PRIVATE ${SDL_LIBRARY})
target_include_directories(${EXECUTABLE_NAME} PRIVATE ${SDL_INCLUDE_DIR})

# Platform-specific linking
if(WIN32)
    # Windows libraries
    target_link_libraries(${EXECUTABLE_NAME} PRIVATE
        opengl32
        ws2_32
        winmm
    )

    # Codec libraries for Windows
    if(USE_CODEC_VORBIS)
        target_link_libraries(${EXECUTABLE_NAME} PRIVATE vorbisfile vorbis ogg)
    endif()
    if(USE_CODEC_MP3)
        target_link_libraries(${EXECUTABLE_NAME} PRIVATE mad)
    endif()
    if(USE_CODEC_FLAC)
        target_link_libraries(${EXECUTABLE_NAME} PRIVATE FLAC)
    endif()
    if(USE_CODEC_OPUS)
        target_link_libraries(${EXECUTABLE_NAME} PRIVATE opusfile opus ogg)
    endif()
    if(USE_CODEC_MIKMOD)
        target_link_libraries(${EXECUTABLE_NAME} PRIVATE mikmod)
    endif()
    if(USE_CODEC_XMP)
        target_link_libraries(${EXECUTABLE_NAME} PRIVATE xmp)
    endif()

elseif(UNIX AND NOT APPLE)
    # OpenGL
    target_link_libraries(${EXECUTABLE_NAME} PRIVATE OpenGL::GL)

    # System libraries
    target_link_libraries(${EXECUTABLE_NAME} PRIVATE ${M_LIBRARY})
    if(DL_LIBRARY)
        target_link_libraries(${EXECUTABLE_NAME} PRIVATE ${DL_LIBRARY})
    endif()

    # ALSA
    if(USE_ALSA_FOUND)
        target_link_libraries(${EXECUTABLE_NAME} PRIVATE ${ALSA_LIBRARIES})
        target_include_directories(${EXECUTABLE_NAME} PRIVATE ${ALSA_INCLUDE_DIRS})
    endif()

    # Codec libraries for Linux
    if(USE_CODEC_VORBIS)
        target_link_libraries(${EXECUTABLE_NAME} PRIVATE ${VORBIS_LIBRARIES})
        target_include_directories(${EXECUTABLE_NAME} PRIVATE ${VORBIS_INCLUDE_DIRS})
    endif()
    if(USE_CODEC_MP3)
        target_link_libraries(${EXECUTABLE_NAME} PRIVATE ${MAD_LIBRARIES})
        target_include_directories(${EXECUTABLE_NAME} PRIVATE ${MAD_INCLUDE_DIRS})
    endif()
    if(USE_CODEC_FLAC)
        target_link_libraries(${EXECUTABLE_NAME} PRIVATE ${FLAC_LIBRARIES})
        target_include_directories(${EXECUTABLE_NAME} PRIVATE ${FLAC_INCLUDE_DIRS})
    endif()
    if(USE_CODEC_OPUS)
        target_link_libraries(${EXECUTABLE_NAME} PRIVATE ${OPUSFILE_LIBRARIES})
        target_include_directories(${EXECUTABLE_NAME} PRIVATE ${OPUSFILE_INCLUDE_DIRS})
    endif()
    if(USE_CODEC_MIKMOD)
        target_link_libraries(${EXECUTABLE_NAME} PRIVATE ${MIKMOD_LIBRARIES})
        target_include_directories(${EXECUTABLE_NAME} PRIVATE ${MIKMOD_INCLUDE_DIRS})
    endif()
    if(USE_CODEC_XMP)
        target_link_libraries(${EXECUTABLE_NAME} PRIVATE ${XMP_LIBRARIES})
        target_include_directories(${EXECUTABLE_NAME} PRIVATE ${XMP_INCLUDE_DIRS})
    endif()
endif()

# Timidity
if(USE_CODEC_TIMIDITY AND TIMIDITY_FOUND)
    target_link_libraries(${EXECUTABLE_NAME} PRIVATE ${TIMIDITY_LIB})
    # Add special compile flag for snd_timidity.c
    set_source_files_properties(${COMMONDIR}/snd_timidity.c PROPERTIES
        COMPILE_DEFINITIONS TIMIDITY_STATIC=1
        COMPILE_FLAGS "-I${LIBS_DIR}/timidity"
    )
endif()

#============================================================================
# Install Targets
#============================================================================
install(TARGETS ${EXECUTABLE_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

#============================================================================
# Summary
#============================================================================
message(STATUS "")
message(STATUS "=== glhexen2 Configuration ===")
message(STATUS "Target OS: ${TARGET_OS}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Sound support: ${USE_SOUND}")
message(STATUS "ALSA: ${USE_ALSA}")
message(STATUS "Vorbis codec: ${USE_CODEC_VORBIS}")
message(STATUS "MP3 codec: ${USE_CODEC_MP3}")
message(STATUS "FLAC codec: ${USE_CODEC_FLAC}")
message(STATUS "Opus codec: ${USE_CODEC_OPUS}")
message(STATUS "Timidity: ${USE_CODEC_TIMIDITY}")
message(STATUS "MikMod: ${USE_CODEC_MIKMOD}")
message(STATUS "XMP: ${USE_CODEC_XMP}")
message(STATUS "=============================")
message(STATUS "")

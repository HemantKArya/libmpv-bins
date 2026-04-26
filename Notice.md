# libmpv-prebuilt — License Attribution

This repository distributes pre-built binaries of libmpv and its dependencies.
All components are open-source software. The build scripts in this repository
are licensed under MIT. The binary outputs carry their original licenses.

## Components

| Component   | License          | URL |
|-------------|-----------------|-----|
| mpv         | GPL-2.0-or-later | https://github.com/mpv-player/mpv |
| FFmpeg      | LGPL-2.1-or-later | https://github.com/FFmpeg/FFmpeg |
| libass      | ISC              | https://github.com/libass/libass |
| dav1d       | BSD-2-Clause     | https://code.videolan.org/videolan/dav1d |
| mbedTLS     | Apache-2.0       | https://github.com/Mbed-TLS/mbedtls |
| libplacebo  | LGPL-2.1-or-later | https://github.com/haasn/libplacebo |
| harfbuzz    | MIT              | https://github.com/harfbuzz/harfbuzz |
| freetype    | FTL or GPL-2.0   | https://freetype.org |
| fribidi     | LGPL-2.1-or-later | https://github.com/fribidi/fribidi |
| fontconfig  | MIT-like         | https://www.freedesktop.org/wiki/Software/fontconfig/ |
| libunibreak | zlib             | https://github.com/adah1972/libunibreak |
| lua         | MIT              | https://www.lua.org |

Full license texts are in the LICENSES/ directory.

## Windows Builds

Windows binaries are sourced from
[shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake)
releases (GPL-2.0-or-later).

## macOS/iOS Builds

macOS and iOS binaries are sourced from
[media-kit/libmpv-darwin-build](https://github.com/media-kit/libmpv-darwin-build).
The "default" variant is LGPL-compatible for commercial use (playback only).

## Android Builds

Android binaries are compiled from source using
[mpv-android](https://github.com/mpv-android/mpv-android) buildscripts.

## Linux Builds

Linux binaries are compiled from source using
[mpv-build](https://github.com/mpv-player/mpv-build).
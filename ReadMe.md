# libmpv-prebuilt

Pre-built **libmpv** shared libraries for embedding video playback
in cross-platform applications.

**Android** · **Linux** · **Windows** · **macOS** · **iOS**

[![Release](https://github.com/YOUR_USERNAME/libmpv-prebuilt/actions/workflows/release.yml/badge.svg)](https://github.com/YOUR_USERNAME/libmpv-prebuilt/actions/workflows/release.yml)

---

## Why?

There is no single source of portable, pre-built libmpv C API binaries
for cross-platform projects. This repo fills that gap with automated,
reproducible builds.

| What you get | What you DON'T get |
|---|---|
| Raw `libmpv.so` / `.dll` / `.dylib` with C API | Java AAR wrappers |
| `mpv/client.h`, `render.h`, `render_gl.h` headers | JNI bindings |
| All FFmpeg + dependency shared libs bundled | Gradle integration |
| Works with C, C++, Rust, Python, C#, Go, etc. | Framework-specific glue |

## Quick Start

```bash
# Auto-detect your platform and download
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/libmpv-prebuilt/main/scripts/fetch-deps.sh | bash

# Or clone and use the script
git clone https://github.com/YOUR_USERNAME/libmpv-prebuilt.git
cd libmpv-prebuilt
./scripts/fetch-deps.sh android    # All 4 Android ABIs
./scripts/fetch-deps.sh linux      # Linux x86_64
./scripts/fetch-deps.sh windows    # Windows x86_64 + aarch64
./scripts/fetch-deps.sh macos      # macOS arm64 + x86_64
./scripts/fetch-deps.sh ios        # iOS arm64 + simulators
./scripts/fetch-deps.sh all        # Everything

---

## ⚠️ Android: Critical C++ Runtime Compatibility

**IMPORTANT:** Prebuilt Android libraries are only compatible if your app uses the **same C++ runtime** (libc++) version.

### The Problem
Each NDK version has a different `libc++` (C++ standard library). If your app's runtime doesn't match the prebuilt libraries, you get runtime crashes:
```
UnsatisfiedLinkError: libmpv.so or symbol _ZNSt6__ndk1...
```

### The Solution (One Line)
**Always include the `libc++_shared.so` bundled with these libraries in your APK.**

### Quick Check
1. Extract the Android package: `tar -xzf libmpv-android-arm64-v8a.tar.gz`
2. Look for: `lib/libc++_shared.so` ✅
3. Read `META-INF/BUILD_INFO.txt` for NDK version
4. Ensure your Qt kit or Android build uses the same NDK version

### Full Integration Guide
See [**ANDROID-CONSUMER-GUIDE.md**](ANDROID-CONSUMER-GUIDE.md) for:
- ✅ Step-by-step Qt/Android integration
- ✅ Native Android app integration
- ✅ Troubleshooting UnsatisfiedLinkError crashes
- ✅ ABI selection (arm64-v8a, armeabi-v7a, x86_64, x86)
- ✅ Deployment checklist

---
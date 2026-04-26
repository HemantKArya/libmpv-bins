#!/usr/bin/env bash
#
# verify-archive.sh — Verify a libmpv-prebuilt archive
#
# Usage:
#   ./verify-archive.sh libmpv-android-arm64-v8a.tar.gz
#   ./verify-archive.sh libmpv-linux-x86_64.tar.gz
#   ./verify-archive.sh libmpv-windows-x86_64.tar.gz
#   ./verify-archive.sh libmpv-macos-arm64.tar.gz
#
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: \$0 <archive.tar.gz> [expected-symbols.txt]"
  exit 1
fi

ARCHIVE="\$1"
SYMBOLS_FILE="${2:-$(dirname "\$0")/../config/expected-symbols.txt}"
SCRIPT_DIR="$(cd "$(dirname "\$0")" && pwd)"

echo "══════════════════════════════════════════"
echo "Verifying: $(basename "$ARCHIVE")"
echo "══════════════════════════════════════════"
echo ""

# Parse platform and arch from filename
# libmpv-{platform}-{arch}.tar.gz
BASENAME=$(basename "$ARCHIVE" .tar.gz)
PLATFORM_ARCH=$(echo "$BASENAME" | sed 's/^libmpv-//')

# Determine platform type
case "$PLATFORM_ARCH" in
  android-*)       PLATFORM_TYPE="android" ;;
  linux-*)         PLATFORM_TYPE="linux" ;;
  windows-*)       PLATFORM_TYPE="windows" ;;
  macos-*)         PLATFORM_TYPE="macos" ;;
  ios-*)           PLATFORM_TYPE="ios" ;;
  iossimulator-*)  PLATFORM_TYPE="iossimulator" ;;
  *)               PLATFORM_TYPE="unknown" ;;
esac

echo "Platform type: $PLATFORM_TYPE"
echo ""

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

tar -xzf "$ARCHIVE" -C "$TMPDIR"

ERRORS=0
WARNINGS=0

# ── Check 1: Required headers ──
echo "── Headers ──"
REQUIRED_HEADERS=(client.h render.h render_gl.h)
OPTIONAL_HEADERS=(stream_cb.h)

for hdr in "${REQUIRED_HEADERS[@]}"; do
  if [ -f "$TMPDIR/include/mpv/$hdr" ]; then
    echo "  ✓ include/mpv/$hdr"
  else
    echo "  ✗ MISSING (required): include/mpv/$hdr"
    ERRORS=$((ERRORS + 1))
  fi
done

for hdr in "${OPTIONAL_HEADERS[@]}"; do
  if [ -f "$TMPDIR/include/mpv/$hdr" ]; then
    echo "  ✓ include/mpv/$hdr"
  else
    echo "  ⚠ MISSING (optional): include/mpv/$hdr"
    WARNINGS=$((WARNINGS + 1))
  fi
done

# ── Check 2: Libraries ──
echo ""
echo "── Libraries ──"

case "$PLATFORM_TYPE" in
  android|linux)
    if ls "$TMPDIR"/lib/libmpv.so* 1>/dev/null 2>&1; then
      echo "  ✓ libmpv.so found"
      file "$TMPDIR"/lib/libmpv.so* | sed 's/^/    /'
    else
      echo "  ✗ MISSING: libmpv.so"
      ERRORS=$((ERRORS + 1))
    fi

    # Check architecture
    if [ -f "$TMPDIR/lib/libmpv.so" ]; then
      ARCH_INFO=$(readelf -h "$TMPDIR/lib/libmpv.so" 2>/dev/null | grep Machine || true)
      echo "  Architecture: $ARCH_INFO"
    fi

    # Count total .so files
    SO_COUNT=$(find "$TMPDIR/lib" -name '*.so' -type f | wc -l)
    echo "  Total .so files: $SO_COUNT"
    ;;

  windows)
    HAS_DLL=false
    if [ -f "$TMPDIR/bin/libmpv-2.dll" ]; then
      echo "  ✓ bin/libmpv-2.dll"
      HAS_DLL=true
    elif [ -f "$TMPDIR/bin/mpv-2.dll" ]; then
      echo "  ✓ bin/mpv-2.dll"
      HAS_DLL=true
    fi
    if [ "$HAS_DLL" = false ]; then
      echo "  ✗ MISSING: libmpv-2.dll or mpv-2.dll"
      ERRORS=$((ERRORS + 1))
    fi

    HAS_IMPLIB=false
    if [ -f "$TMPDIR/lib/libmpv.dll.a" ]; then
      echo "  ✓ lib/libmpv.dll.a (MinGW import lib)"
      HAS_IMPLIB=true
    fi
    if [ -f "$TMPDIR/lib/mpv.lib" ]; then
      echo "  ✓ lib/mpv.lib (MSVC import lib)"
      HAS_IMPLIB=true
    fi
    if [ "$HAS_IMPLIB" = false ]; then
      echo "  ⚠ No import library found (libmpv.dll.a or mpv.lib)"
      WARNINGS=$((WARNINGS + 1))
    fi
    ;;

  macos)
    HAS_LIB=false
    if ls "$TMPDIR"/lib/*.dylib 1>/dev/null 2>&1; then
      echo "  ✓ .dylib files found:"
      ls "$TMPDIR"/lib/*.dylib | sed 's/^/    /'
      HAS_LIB=true
    fi
    if ls "$TMPDIR"/lib/*.a 1>/dev/null 2>&1; then
      echo "  ✓ .a files found:"
      ls "$TMPDIR"/lib/*.a | sed 's/^/    /'
      HAS_LIB=true
    fi
    if [ -d "$TMPDIR/Frameworks" ]; then
      echo "  ✓ Frameworks found:"
      find "$TMPDIR/Frameworks" -maxdepth 1 -type d | tail -n +2 | sed 's/^/    /'
      HAS_LIB=true
    fi
    if [ "$HAS_LIB" = false ]; then
      echo "  ✗ MISSING: no .dylib, .a, or .framework"
      ERRORS=$((ERRORS + 1))
    fi
    ;;

  ios|iossimulator)
    HAS_LIB=false
    if ls "$TMPDIR"/lib/*.a 1>/dev/null 2>&1; then
      echo "  ✓ .a (static) files found:"
      ls "$TMPDIR"/lib/*.a | sed 's/^/    /'
      HAS_LIB=true
    fi
    if [ -d "$TMPDIR/Frameworks" ]; then
      echo "  ✓ Frameworks found:"
      find "$TMPDIR/Frameworks" -maxdepth 1 -type d | tail -n +2 | sed 's/^/    /'
      HAS_LIB=true
    fi
    if ls "$TMPDIR"/lib/*.dylib 1>/dev/null 2>&1; then
      echo "  ✓ .dylib files found (unusual for iOS):"
      ls "$TMPDIR"/lib/*.dylib | sed 's/^/    /'
      HAS_LIB=true
    fi
    if [ "$HAS_LIB" = false ]; then
      echo "  ✗ MISSING: no .a, .dylib, or .framework"
      ERRORS=$((ERRORS + 1))
    fi
    ;;

  *)
    echo "  ⚠ Unknown platform, skipping library check"
    WARNINGS=$((WARNINGS + 1))
    ;;
esac

# ── Check 3: Exported symbols (Linux/Android only) ──
if [ "$PLATFORM_TYPE" = "linux" ] || [ "$PLATFORM_TYPE" = "android" ]; then
  if [ -f "$TMPDIR/lib/libmpv.so" ] && command -v nm &>/dev/null; then
    echo ""
    echo "── Exported Symbols ──"

    EXPORTED=$(nm -D "$TMPDIR/lib/libmpv.so" 2>/dev/null | grep ' T mpv_' | awk '{print \$3}' | sort)
    EXPORTED_COUNT=$(echo "$EXPORTED" | grep -c 'mpv_' || true)
    echo "  Total mpv_* symbols: $EXPORTED_COUNT"

    if [ -f "$SYMBOLS_FILE" ]; then
      MISSING_SYMBOLS=0
      while IFS= read -r symbol; do
        # Skip comments and empty lines
        [[ "$symbol" =~ ^#.*$ ]] && continue
        [[ -z "$symbol" ]] && continue
        symbol=$(echo "$symbol" | tr -d '[:space:]')

        if echo "$EXPORTED" | grep -q "^${symbol}$"; then
          : # symbol found
        else
          echo "  ✗ Missing symbol: $symbol"
          MISSING_SYMBOLS=$((MISSING_SYMBOLS + 1))
        fi
      done < "$SYMBOLS_FILE"

      if [ "$MISSING_SYMBOLS" -eq 0 ]; then
        echo "  ✓ All expected symbols present"
      else
        echo "  ⚠ $MISSING_SYMBOLS expected symbol(s) missing"
        WARNINGS=$((WARNINGS + $MISSING_SYMBOLS))
      fi
    else
      echo "  (no expected-symbols.txt file, skipping symbol verification)"
    fi
  fi
fi

# ── Check 4: NOTICE.md ──
echo ""
echo "── Metadata ──"
if [ -f "$TMPDIR/NOTICE.md" ]; then
  echo "  ✓ NOTICE.md present"
else
  echo "  ⚠ NOTICE.md missing"
  WARNINGS=$((WARNINGS + 1))
fi

if [ -f "$TMPDIR/source-url.txt" ]; then
  echo "  ✓ source-url.txt: $(cat "$TMPDIR/source-url.txt" | head -1)"
fi

# ── Summary ──
echo ""
echo "══════════════════════════════════════════"
echo "Files: $(find "$TMPDIR" -type f | wc -l)"
echo "Size:  $(du -sh "$TMPDIR" | cut -f1)"
echo ""

if [ "$ERRORS" -gt 0 ]; then
  echo "RESULT: ✗ FAILED ($ERRORS error(s), $WARNINGS warning(s))"
  exit 1
elif [ "$WARNINGS" -gt 0 ]; then
  echo "RESULT: ⚠ PASSED with $WARNINGS warning(s)"
  exit 0
else
  echo "RESULT: ✓ PASSED"
  exit 0
fi
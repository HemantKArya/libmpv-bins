#!/usr/bin/env bash
#
# Verify that an archive has the expected structure and contents
#
set -euo pipefail

ARCHIVE="\$1"
PLATFORM="${2:-unknown}"

echo "Verifying: $ARCHIVE (platform: $PLATFORM)"
echo "────────────────────────────────────────────"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

tar -xzf "$ARCHIVE" -C "$TMPDIR"

ERRORS=0

# Check required headers
for hdr in client.h render.h render_gl.h; do
    if [ -f "$TMPDIR/include/mpv/$hdr" ]; then
        echo "  ✓ include/mpv/$hdr"
    else
        echo "  ✗ MISSING: include/mpv/$hdr"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check libraries based on platform
case "$PLATFORM" in
    android-*|linux-*)
        if ls "$TMPDIR"/lib/libmpv.so* 1>/dev/null 2>&1; then
            echo "  ✓ lib/libmpv.so"
            file "$TMPDIR"/lib/libmpv.so* | head -1
        else
            echo "  ✗ MISSING: lib/libmpv.so"
            ERRORS=$((ERRORS + 1))
        fi
        ;;
    windows-*)
        HAS_DLL=false
        [ -f "$TMPDIR/bin/libmpv-2.dll" ] && HAS_DLL=true
        [ -f "$TMPDIR/bin/mpv-2.dll" ] && HAS_DLL=true
        if [ "$HAS_DLL" = true ]; then
            echo "  ✓ DLL found"
        else
            echo "  ✗ MISSING: libmpv-2.dll or mpv-2.dll"
            ERRORS=$((ERRORS + 1))
        fi
        ;;
    macos-*|ios-*|iossimulator-*)
        HAS_LIB=false
        ls "$TMPDIR"/lib/*.dylib 1>/dev/null 2>&1 && HAS_LIB=true
        ls "$TMPDIR"/lib/*.a 1>/dev/null 2>&1 && HAS_LIB=true
        [ -d "$TMPDIR/Frameworks" ] && HAS_LIB=true
        if [ "$HAS_LIB" = true ]; then
            echo "  ✓ Libraries/Frameworks found"
        else
            echo "  ✗ MISSING: no .dylib, .a, or .framework found"
            ERRORS=$((ERRORS + 1))
        fi
        ;;
esac

# Summary
echo ""
echo "Files in archive: $(find "$TMPDIR" -type f | wc -l)"
echo "Total size: $(du -sh "$TMPDIR" | cut -f1)"

if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "FAILED: $ERRORS error(s) found"
    exit 1
else
    echo ""
    echo "PASSED ✓"
fi
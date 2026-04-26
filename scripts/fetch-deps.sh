#!/usr/bin/env bash
#
# fetch-deps.sh — Download prebuilt libmpv binaries
#
# Usage:
#   ./fetch-deps.sh                    # auto-detect host platform
#   ./fetch-deps.sh android            # all Android ABIs
#   ./fetch-deps.sh linux              # Linux x86_64
#   ./fetch-deps.sh windows            # Windows x86_64 + aarch64
#   ./fetch-deps.sh macos              # macOS arm64 + x86_64
#   ./fetch-deps.sh ios                # iOS arm64 + simulators
#   ./fetch-deps.sh all                # everything
#   ./fetch-deps.sh --verify           # download for host + verify
#
set -euo pipefail

# ── Config ──
REPO="YOUR_USERNAME/libmpv-prebuilt"
VERSION="2026.04.26"
BASE_URL="https://github.com/${REPO}/releases/download/v${VERSION}"
SCRIPT_DIR="$(cd "$(dirname "\$0")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/../third_party/mpv"
VERIFY=false

# ── Colors (disabled if not a terminal) ──
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; NC=''
fi

info()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
err()   { echo -e "${RED}[✗]${NC} $*"; exit 1; }
step()  { echo -e "${CYAN}[→]${NC} $*"; }

# ── Helpers ──
download() {
  local url="\$1" dest="\$2"
  if command -v curl &>/dev/null; then
    curl -L --fail --progress-bar -o "$dest" "$url"
  elif command -v wget &>/dev/null; then
    wget -q --show-progress -O "$dest" "$url"
  else
    err "Neither curl nor wget found. Install one of them."
  fi
}

fetch_archive() {
  local name="\$1"       # e.g. libmpv-android-arm64-v8a
  local dest_dir="\$2"   # e.g. third_party/mpv/android/arm64-v8a
  local archive="${name}.tar.gz"
  local url="${BASE_URL}/${archive}"
  local version_file="${dest_dir}/.version"

  # Skip if already at correct version
  if [ -f "$version_file" ]; then
    local current
    current=$(cat "$version_file" 2>/dev/null || true)
    if [ "$current" = "$VERSION" ]; then
      info "${name} already at v${VERSION}, skipping"
      return 0
    fi
  fi

  step "Downloading ${archive}..."
  local tmp
  tmp=$(mktemp "/tmp/${archive}.XXXXXX")
  trap "rm -f '$tmp'" RETURN

  if ! download "$url" "$tmp"; then
    rm -f "$tmp"
    err "Failed to download ${url}"
  fi

  step "Extracting to ${dest_dir}..."
  rm -rf "$dest_dir"
  mkdir -p "$dest_dir"
  tar -xzf "$tmp" -C "$dest_dir"
  rm -f "$tmp"

  echo "$VERSION" > "$version_file"
  info "${name} → ${dest_dir}"

  # Optional verification
  if [ "$VERIFY" = true ] && [ -f "${SCRIPT_DIR}/verify-archive.sh" ]; then
    step "Verifying ${name}..."
    # Re-create a temp archive from extracted content for verification
    # (since we already extracted, just run checks on the dir)
    local platform_arch
    platform_arch=$(echo "$name" | sed 's/^libmpv-//')
    bash "${SCRIPT_DIR}/verify-archive.sh" \
      <(cd "$dest_dir" && tar czf - .) \
      "$platform_arch" 2>/dev/null || \
      warn "Verification had issues for ${name} (non-fatal)"
  fi
}

# ── Platform detection ──
detect_platform() {
  case "$(uname -s)" in
    Linux*)
      echo "linux"
      ;;
    Darwin*)
      echo "macos"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "windows"
      ;;
    *)
      err "Unknown platform: $(uname -s). Specify manually: \$0 [android|linux|windows|macos|ios|all]"
      ;;
  esac
}

# ── Platform fetchers ──
fetch_android() {
  step "Fetching Android (4 ABIs)..."
  fetch_archive "libmpv-android-arm64-v8a"    "${OUT_DIR}/android/arm64-v8a"
  fetch_archive "libmpv-android-armeabi-v7a"  "${OUT_DIR}/android/armeabi-v7a"
  fetch_archive "libmpv-android-x86_64"       "${OUT_DIR}/android/x86_64"
  fetch_archive "libmpv-android-x86"          "${OUT_DIR}/android/x86"
}

fetch_linux() {
  step "Fetching Linux..."
  fetch_archive "libmpv-linux-x86_64" "${OUT_DIR}/linux/x86_64"
}

fetch_windows() {
  step "Fetching Windows..."
  fetch_archive "libmpv-windows-x86_64"  "${OUT_DIR}/windows/x86_64"
  fetch_archive "libmpv-windows-aarch64" "${OUT_DIR}/windows/aarch64"
}

fetch_macos() {
  step "Fetching macOS..."
  fetch_archive "libmpv-macos-arm64"  "${OUT_DIR}/macos/arm64"
  fetch_archive "libmpv-macos-x86_64" "${OUT_DIR}/macos/x86_64"
}

fetch_ios() {
  step "Fetching iOS..."
  fetch_archive "libmpv-ios-arm64"             "${OUT_DIR}/ios/arm64"
  fetch_archive "libmpv-iossimulator-arm64"    "${OUT_DIR}/iossimulator/arm64"
  fetch_archive "libmpv-iossimulator-x86_64"   "${OUT_DIR}/iossimulator/x86_64"
}

# ── Parse arguments ──
PLATFORM="auto"
for arg in "$@"; do
  case "$arg" in
    --verify)  VERIFY=true ;;
    --help|-h)
      echo "Usage: \$0 [PLATFORM] [--verify]"
      echo ""
      echo "Platforms:"
      echo "  auto       Auto-detect host platform (default)"
      echo "  android    All 4 Android ABIs"
      echo "  linux      Linux x86_64"
      echo "  windows    Windows x86_64 + aarch64"
      echo "  macos      macOS arm64 + x86_64"
      echo "  ios        iOS arm64 + simulators"
      echo "  all        Everything"
      echo ""
      echo "Options:"
      echo "  --verify   Run verification after download"
      echo ""
      echo "Config:"
      echo "  Repo:      ${REPO}"
      echo "  Version:   ${VERSION}"
      echo "  Output:    ${OUT_DIR}"
      exit 0
      ;;
    android|linux|windows|macos|ios|all|auto)
      PLATFORM="$arg"
      ;;
    *)
      err "Unknown argument: $arg. Use --help for usage."
      ;;
  esac
done

# ── Main ──
echo ""
echo -e "  ${BOLD}libmpv-prebuilt v${VERSION}${NC}"
echo "  ─────────────────────────────"
echo "  Repo:   ${REPO}"
echo "  Output: ${OUT_DIR}"
echo ""

case "$PLATFORM" in
  auto)
    DETECTED=$(detect_platform)
    info "Detected platform: ${DETECTED}"
    echo ""
    "fetch_${DETECTED}"
    ;;
  android)  fetch_android ;;
  linux)    fetch_linux ;;
  windows)  fetch_windows ;;
  macos)    fetch_macos ;;
  ios)      fetch_ios ;;
  all)
    fetch_android
    fetch_linux
    fetch_windows
    fetch_macos
    fetch_ios
    ;;
esac

echo ""
info "Done! Dependencies are in: ${OUT_DIR}"

# Print summary of what's installed
echo ""
echo "  Installed:"
find "$OUT_DIR" -name '.version' -type f 2>/dev/null | sort | while read -r vf; do
  dir=$(dirname "$vf")
  rel_dir=$(echo "$dir" | sed "s|${OUT_DIR}/||")
  ver=$(cat "$vf")
  echo "    ${rel_dir} → v${ver}"
done
echo ""
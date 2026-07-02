#!/usr/bin/env bash
set -u

ANDROID_CLEAN_HOME="${ANDROID_CLEAN_HOME:-/root/AndroidClean}"
ANDROID_BASE_HOME="${ANDROID_BASE_HOME:-/root/Android}"
NDK_VERSION="${NDK_VERSION:-26.3.11579264}"
BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-35.0.0}"
NDK_HOME="${NDK_HOME:-$ANDROID_BASE_HOME/ndk/$NDK_VERSION}"
NDK_BIN="$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin"
AAPT2="$ANDROID_CLEAN_HOME/build-tools/$BUILD_TOOLS_VERSION/aapt2"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing command: $1" >&2; exit 1; }; }
need qemu-x86_64

wrap_file() {
  local file="$1"
  local real="$2"
  local line="$3"
  if [ ! -e "$file" ]; then
    echo "skip missing $file"
    return 0
  fi
  if [ ! -e "$real" ]; then
    mv "$file" "$real"
  fi
  printf '%s\n' '#!/bin/sh' "$line" > "$file"
  chmod +x "$file"
  echo "wrapped $file"
}

echo "[1/4] wrap NDK clang driver"
wrap_file \
  "$NDK_BIN/aarch64-linux-android24-clang" \
  "$NDK_BIN/aarch64-linux-android24-clang.orig" \
  "exec qemu-x86_64 $NDK_BIN/clang --target=aarch64-linux-android24 \"\$@\""

echo "[2/4] wrap lld as ld.lld"
wrap_file \
  "$NDK_BIN/lld" \
  "$NDK_BIN/lld.real" \
  "exec qemu-x86_64 -0 ld.lld $NDK_BIN/lld.real \"\$@\""

echo "[3/4] wrap llvm-readelf"
wrap_file \
  "$NDK_BIN/llvm-readelf" \
  "$NDK_BIN/llvm-readelf.real" \
  "exec qemu-x86_64 $NDK_BIN/llvm-readelf.real \"\$@\""

echo "[4/4] wrap clean SDK aapt2"
if [ -e "$AAPT2" ]; then
  wrap_file \
    "$AAPT2" \
    "$AAPT2.real" \
    "exec qemu-x86_64 $AAPT2.real \"\$@\""
else
  echo "missing aapt2: $AAPT2" >&2
  exit 1
fi

echo "verification:"
"$NDK_BIN/aarch64-linux-android24-clang" --version | head -3 || true
"$NDK_BIN/ld.lld" --version | head -1 || true
"$NDK_BIN/llvm-readelf" --version | head -2 || true
"$AAPT2" version || true
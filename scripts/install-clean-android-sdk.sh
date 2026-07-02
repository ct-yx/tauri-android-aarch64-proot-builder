#!/usr/bin/env bash
set -u

ANDROID_CLEAN_HOME="${ANDROID_CLEAN_HOME:-/root/AndroidClean}"
ANDROID_BASE_HOME="${ANDROID_BASE_HOME:-/root/Android}"
CMDLINE_TOOLS_VERSION_URL="${CMDLINE_TOOLS_VERSION_URL:-https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip}"
NDK_VERSION="${NDK_VERSION:-26.3.11579264}"
PLATFORM_VERSION="${PLATFORM_VERSION:-android-35}"
BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-35.0.0}"

mkdir -p "$ANDROID_CLEAN_HOME/cmdline-tools" "$ANDROID_BASE_HOME"

echo "[1/4] installing Android command line tools into $ANDROID_CLEAN_HOME"
if [ ! -x "$ANDROID_CLEAN_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  tmp="/tmp/android-cmdline-tools-$$"
  mkdir -p "$tmp"
  curl -L -o "$tmp/commandlinetools.zip" "$CMDLINE_TOOLS_VERSION_URL"
  unzip -q "$tmp/commandlinetools.zip" -d "$tmp"
  rm -rf "$ANDROID_CLEAN_HOME/cmdline-tools/latest"
  mv "$tmp/cmdline-tools" "$ANDROID_CLEAN_HOME/cmdline-tools/latest"
  rm -rf "$tmp"
fi

echo "[2/4] installing clean platform/build-tools"
yes | "$ANDROID_CLEAN_HOME/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_CLEAN_HOME" \
  "platform-tools" \
  "platforms;$PLATFORM_VERSION" \
  "build-tools;$BUILD_TOOLS_VERSION"

echo "[3/4] installing NDK into $ANDROID_BASE_HOME"
if [ ! -d "$ANDROID_BASE_HOME/ndk/$NDK_VERSION" ]; then
  mkdir -p "$ANDROID_BASE_HOME/cmdline-tools"
  if [ ! -x "$ANDROID_BASE_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
    cp -a "$ANDROID_CLEAN_HOME/cmdline-tools/latest" "$ANDROID_BASE_HOME/cmdline-tools/latest"
  fi
  yes | "$ANDROID_BASE_HOME/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$ANDROID_BASE_HOME" "ndk;$NDK_VERSION"
fi

echo "[4/4] done"
echo "ANDROID_HOME=$ANDROID_CLEAN_HOME"
echo "NDK_HOME=$ANDROID_BASE_HOME/ndk/$NDK_VERSION"
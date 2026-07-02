#!/usr/bin/env bash
set -u

PROJECT="${1:-}"
if [ -z "$PROJECT" ]; then
  echo "usage: $0 /path/to/tauri-project" >&2
  exit 1
fi

ANDROID_CLEAN_HOME="${ANDROID_CLEAN_HOME:-/root/AndroidClean}"
ANDROID_BASE_HOME="${ANDROID_BASE_HOME:-/root/Android}"
NDK_VERSION="${NDK_VERSION:-26.3.11579264}"
NDK_HOME="${NDK_HOME:-$ANDROID_BASE_HOME/ndk/$NDK_VERSION}"
JAVA_HOME_VALUE="${JAVA_HOME_VALUE:-/usr/lib/jvm/java-17-openjdk-arm64}"
BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-35.0.0}"

cd "$PROJECT" || exit 1

if [ ! -x ./node_modules/.bin/tauri ]; then
  echo "node_modules/.bin/tauri not found; running npm install"
  npm install
fi

if [ ! -d src-tauri/gen/android ]; then
  echo "Android project not initialized; running tauri android init"
  env -i \
    HOME="$HOME" USER="${USER:-root}" SHELL=/bin/bash \
    JAVA_HOME="$JAVA_HOME_VALUE" \
    ANDROID_HOME="$ANDROID_CLEAN_HOME" \
    ANDROID_SDK_ROOT="$ANDROID_CLEAN_HOME" \
    NDK_HOME="$NDK_HOME" \
    ANDROID_NDK_HOME="$NDK_HOME" \
    PATH="$HOME/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    CI=true \
    ./node_modules/.bin/tauri android init --ci --skip-targets-install
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/patch-tauri-project.sh" "$PROJECT"

echo "building Tauri Android arm64 debug APK..."
env -i \
  HOME="$HOME" \
  USER="${USER:-root}" \
  SHELL=/bin/bash \
  JAVA_HOME="$JAVA_HOME_VALUE" \
  ANDROID_HOME="$ANDROID_CLEAN_HOME" \
  ANDROID_SDK_ROOT="$ANDROID_CLEAN_HOME" \
  NDK_HOME="$NDK_HOME" \
  ANDROID_NDK_HOME="$NDK_HOME" \
  PATH="$HOME/.cargo/bin:/root/gradle/gradle-8.7/bin:$ANDROID_CLEAN_HOME/cmdline-tools/latest/bin:$ANDROID_CLEAN_HOME/platform-tools:$ANDROID_CLEAN_HOME/build-tools/$BUILD_TOOLS_VERSION:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
  CI=true \
  ./node_modules/.bin/tauri android build --debug --apk --target aarch64 --ci --config src-tauri/tauri.android.fast.conf.json

find src-tauri/gen/android/app/build/outputs/apk -name '*.apk' -print 2>/dev/null || true
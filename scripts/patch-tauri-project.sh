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
BUILD_TOOLS_VERSION="${BUILD_TOOLS_VERSION:-35.0.0}"
COMPILE_SDK="${COMPILE_SDK:-35}"
TARGET_SDK="${TARGET_SDK:-35}"

cd "$PROJECT" || exit 1

mkdir -p src-tauri/.cargo
cat > src-tauri/.cargo/config.toml <<EOF
[target.aarch64-linux-android]
linker = "$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android24-clang"

[env]
ANDROID_HOME = "$ANDROID_CLEAN_HOME"
ANDROID_SDK_ROOT = "$ANDROID_CLEAN_HOME"
NDK_HOME = "$NDK_HOME"
ANDROID_NDK_HOME = "$NDK_HOME"
EOF

echo "patched src-tauri/.cargo/config.toml"

if [ -f src-tauri/gen/android/gradle.properties ]; then
  if grep -q '^android.aapt2FromMavenOverride=' src-tauri/gen/android/gradle.properties; then
    sed -i "s#^android.aapt2FromMavenOverride=.*#android.aapt2FromMavenOverride=$ANDROID_CLEAN_HOME/build-tools/$BUILD_TOOLS_VERSION/aapt2#" src-tauri/gen/android/gradle.properties
  else
    printf '\nandroid.aapt2FromMavenOverride=%s/build-tools/%s/aapt2\n' "$ANDROID_CLEAN_HOME" "$BUILD_TOOLS_VERSION" >> src-tauri/gen/android/gradle.properties
  fi
  for line in \
    "org.gradle.daemon=true" \
    "org.gradle.caching=true" \
    "org.gradle.parallel=false" \
    "kotlin.incremental=true"; do
    key="${line%%=*}"
    if grep -q "^$key=" src-tauri/gen/android/gradle.properties; then
      sed -i "s#^$key=.*#$line#" src-tauri/gen/android/gradle.properties
    else
      printf '%s\n' "$line" >> src-tauri/gen/android/gradle.properties
    fi
  done
  echo "patched src-tauri/gen/android/gradle.properties"
fi

cat > src-tauri/tauri.android.fast.conf.json <<'EOF'
{
  "$schema": "https://schema.tauri.app/config/2",
  "build": {
    "beforeBuildCommand": "",
    "frontendDist": "../dist"
  }
}
EOF
echo "created src-tauri/tauri.android.fast.conf.json"

APP_GRADLE="src-tauri/gen/android/app/build.gradle.kts"
if [ -f "$APP_GRADLE" ]; then
  sed -i "s/compileSdk = [0-9][0-9]*/compileSdk = $COMPILE_SDK/" "$APP_GRADLE"
  sed -i "s/targetSdk = [0-9][0-9]*/targetSdk = $TARGET_SDK/" "$APP_GRADLE"
  echo "patched $APP_GRADLE"
fi

node - <<'NODE'
const fs = require('fs');
const file = 'package.json';
if (!fs.existsSync(file)) process.exit(0);
const pkg = JSON.parse(fs.readFileSync(file, 'utf8'));
pkg.scripts ||= {};
if (!pkg.scripts.tauri) pkg.scripts.tauri = 'tauri';
fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + '\n');
console.log('patched package.json scripts.tauri');
NODE

echo "done"
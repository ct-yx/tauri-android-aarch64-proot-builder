# Tauri Android Builder on aarch64 proot

Build Tauri v2 Android APKs inside an `aarch64` Linux/proot environment, such as Android-hosted Ubuntu.

This repository contains **only build environment scripts and documentation**. It does **not** include any proprietary web assets, APKs, reverse-engineered bundles, `models.zip`, wasm files, or application-specific resources.

## Problem

Tauri Android builds normally expect a Linux x86_64 host because Android SDK/NDK command-line tools are distributed as x86_64 binaries.

On an Android phone running Ubuntu/proot, the host is usually:

```txt
aarch64
```

Typical failures include:

```txt
AAPT2 ... Daemon startup failed
Illegal instruction
cannot execute: required file not found
clang-17: error: unable to execute command: Illegal instruction
llvm-readelf exited with signal 4
```

## Solution

Use a clean Android SDK plus qemu-user wrappers around x86_64 Android SDK/NDK tools:

- `aapt2`
- `aarch64-linux-android24-clang`
- `lld` / `ld.lld`
- `llvm-readelf`

Then run Tauri with a clean environment so NDK x86_64 binaries do not pollute the host `PATH`.

## Tested setup

- Host: Ubuntu/proot on Android
- Host arch: `aarch64`
- Java: OpenJDK 17
- Node/npm: Node 24 / npm 11
- Rust: stable
- Tauri CLI: v2
- Android SDK platform: 35
- Android build-tools: 35.0.0
- Android NDK: 26.3.11579264
- Gradle: 8.7+ or generated Gradle wrapper

## Quick start

### 1. Install base tools

```bash
sudo apt-get update
sudo apt-get install -y curl unzip git qemu-user qemu-user-static build-essential
```

If you are root inside proot, omit `sudo`.

### 2. Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
source "$HOME/.cargo/env"
rustup target add aarch64-linux-android
```

### 3. Install clean Android SDK

```bash
bash scripts/install-clean-android-sdk.sh
```

By default this creates:

```txt
/root/AndroidClean
/root/Android/ndk/26.3.11579264
```

### 4. Apply qemu wrappers

```bash
bash scripts/patch-android-tools-for-aarch64-proot.sh
```

### 5. Patch your Tauri Android project

After `tauri android init`, run:

```bash
bash scripts/patch-tauri-project.sh /path/to/your/tauri-project
```

This adds/updates:

- `src-tauri/.cargo/config.toml`
- `src-tauri/gen/android/gradle.properties`
- Android generated `compileSdk` / `targetSdk`
- `package.json` script: `"tauri": "tauri"`

### 6. Build APK

```bash
bash scripts/build-tauri-android-aarch64.sh /path/to/your/tauri-project
```

The build script uses a fast Tauri config that reuses existing `dist/` and avoids rerunning the frontend build every time. Rebuild your frontend manually when assets change.

Expected output is usually under:

```txt
src-tauri/gen/android/app/build/outputs/apk/
```

## Important notes

### Keep NDK bin out of global PATH

Do **not** put this directory globally in `PATH`:

```txt
$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin
```

If you do, host Rust build scripts may accidentally use the x86_64 `ld`, causing:

```txt
collect2: fatal error: ld terminated with signal 4 [Illegal instruction]
```

Use target-specific Cargo linker config instead.

### Use a clean SDK

If your existing SDK has inconsistent directories, for example:

```txt
platforms/android-35 contains AndroidVersion.ApiLevel=34
build-tools/35.0.0 contains Pkg.Revision=29.0.3
```

create a clean SDK root instead of trying to repair the old one.

### Do not publish proprietary assets

This template is for build tooling only. Put your own web app under your Tauri `public/` or `dist/` as appropriate, but do not publish third-party bundles you do not have rights to redistribute.

## Repository contents

```txt
scripts/
  install-clean-android-sdk.sh
  patch-android-tools-for-aarch64-proot.sh
  patch-tauri-project.sh
  build-tauri-android-aarch64.sh
examples/
  cargo-config.toml
  gradle.properties.snippet
```

## License

MIT
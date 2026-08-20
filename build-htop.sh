#!/usr/bin/env bash
set -e

# ================================
# Configuration for Android 15+ arm64 (x64 host machine)
# ================================
API=35                              # Android 15+ (arm64-v8a)
NDK_VERSION=r29                    # Latest NDK
WORKDIR=$HOME/htop-android-build   # Changed from /home/benkos to $HOME for portability
PREFIX=${WORKDIR}/install
OUTPUT=${WORKDIR}/build-output     # Changed from 'output' to 'build-output'

# ================================
# Preparing the environment
# ================================
mkdir -p "$WORKDIR" "$PREFIX" "$OUTPUT"
cd "$WORKDIR"

# Download NDK if it doesn't exist
if [ ! -d "${HOME}/android-ndk-${NDK_VERSION}" ]; then
    echo "[+] Downloading Android NDK ${NDK_VERSION}..."
    wget -q https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip
    unzip -q android-ndk-${NDK_VERSION}-linux.zip -d $HOME
fi

export NDK=${HOME}/android-ndk-${NDK_VERSION}
export PATH=${NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH

echo "--- NDK Setup Verification ---"
if [ -z "$(which aarch64-linux-android35-clang 2>/dev/null)" ]; then
    echo "[!] Warning: aarch64-linux-android35-clang not found in PATH."
    echo "      Check if NDK was extracted correctly at: ${NDK}"
fi
echo "Compiler Binaries:"
which aarch64-linux-android35-clang 2>/dev/null || true
which aarch64-linux-android35-clang++ 2>/dev/null || true
echo "------------------------------"

# ================================
# Cross-Compilation Notes for x64 Machine
# ================================
# This script compiles htop for Android 15 (arm64-v8a) on an x64 Linux machine.
# The resulting binary will be statically linked and ready to run on Android devices.
# No additional setup required - the NDK toolchain handles cross-compilation.

echo "--- Cross-Compilation Toolchain Check ---"
if [ -z "$(which aarch64-linux-android35-clang 2>/dev/null)" ]; then
    echo "[!] Error: aarch64-linux-android35-clang not found."
    echo "      Expected path: ${NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android35-clang"
    exit 1
fi
echo "Found compiler: $(which aarch64-linux-android35-clang)"
echo "----------------------------------------"

# Set toolchain variables
TOOLCHAIN_DIR=${NDK}/toolchains/llvm/prebuilt/linux-x86_64/bin
export CC="${TOOLCHAIN_DIR}/aarch64-linux-android${API}-clang"
export CXX="${TOOLCHAIN_DIR}/aarch64-linux-android${API}-clang++"
export AR="${TOOLCHAIN_DIR}/llvm-ar"
export LD="${TOOLCHAIN_DIR}/ld.lld"
export STRIP="${TOOLCHAIN_DIR}/llvm-strip"

# ================================
# Building ncurses
# ================================
if [ ! -d ncurses-6.6 ]; then
    echo "[+] Downloading ncurses..."
    wget -q https://invisible-mirror.net/archives/ncurses/ncurses-6.6.tar.gz
    tar xf ncurses-6.6.tar.gz
fi

cd ncurses-6.6
echo "[+] Building ncurses..."
./configure --disable-stripping \
    --host=aarch64-linux-android \
    --prefix=$PREFIX \
    --with-termlib \
    --without-tests \
    --without-debug \
    --enable-widec \
    --enable-static \
    --disable-shared \
    CC=$CC CXX=$CXX AR=$AR LD=$LD

# Changed from nproc to fixed 8 jobs for cross-compilation
make -j8
make install
cd ..

# ================================
# Building htop
# ================================
if [ ! -d htop ]; then
    echo "[+] Downloading htop..."
    git clone https://github.com/htop-dev/htop.git
fi

cd htop
echo "[+] Building htop..."

# Ensure autogen.sh creates Makefile correctly
./autogen.sh

PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig CPPFLAGS="-I$PREFIX/include -I$PREFIX/include/ncursesw" LDFLAGS="-L$PREFIX/lib" CFLAGS="-static" CXXFLAGS="-static" ./configure \
    --host=aarch64-linux-android \
    --prefix=$PREFIX \
    --enable-unicode \
    --with-termlib

# Changed from nproc to fixed 8 jobs for cross-compilation
make -j8
make install
cd ..

# ================================
# Finalization
# ================================
cp $PREFIX/bin/htop $OUTPUT/

# Strip the binary if available
if [ -n "$(which ${STRIP})" ]; then
    echo "[+] Stripping binary..."
    ${STRIP} "$OUTPUT/htop" 2>/dev/null || true
fi

# ================================
# Final Verification
# ================================
echo "[+] Verifying binary architecture..."
if command -v file &> /dev/null; then
    echo "Binary info: $(file "$OUTPUT/htop")"
fi

# Check if it's an ARM64 executable
if readelf -h "$OUTPUT/htop" 2>/dev/null | grep -q "Class:.*ARM"; then
    echo "[+] Success! Binary is compiled for ARM64 (aarch64)"
elif readelf -h "$OUTPUT/htop" 2>/dev/null | grep -q "Machine:.*AArch64"; then
    echo "[+] Success! Binary is compiled for ARM64 (AArch64)"
else
    echo "[!] Warning: Could not determine architecture. Check with 'file $OUTPUT/htop'"
fi

echo ""
echo "[+] Done! The binary file can be found in: $OUTPUT/htop"
echo "File size: $(du -h "$OUTPUT/htop" | cut -f1)"
echo "To install on an Android device, copy this file to your device and run directly."

# ================================
# Save Location Prompt
# ================================
echo ""
echo "=========================================================="
read -p "[+] Where would you like to save the binary? [Default: $OUTPUT/htop] " SAVE_PATH
if [ -z "$SAVE_PATH" ]; then
    SAVE_PATH="$OUTPUT/htop"
fi

# If user provided a full path, use it; otherwise prepend OUTPUT dir
if [[ ! "$SAVE_PATH" =~ ^[\/] ]]; then
    SAVE_PATH="$OUTPUT/$SAVE_PATH"
fi

echo "[+] Saving to: $SAVE_PATH"

# Copy file to the specified location
cp "$OUTPUT/htop" "$SAVE_PATH"
echo "[+] Binary copied successfully!"

# ================================
# Cleanup Prompt
# ================================
echo ""
echo "=========================================================="
read -p "[+] Would you like to delete the build folders? [y/N] " CLEANUP_CHOICE

if [ "$CLEANUP_CHOICE" = "y" ] || [ "$CLEANUP_CHOICE" = "Y" ]; then
    echo "[+] Deleting android-ndk-r29..."
    if [ -d "${HOME}/android-ndk-${NDK_VERSION}" ]; then
        rm -rf "${HOME}/android-ndk-${NDK_VERSION}"
        echo "[+] Deleted ${HOME}/android-ndk-${NDK_VERSION}"
    else
        echo "[!] android-ndk-r29 not found, skipping..."
    fi

    echo "[+] Deleting htop-android-build folder..."
    if [ -d "$WORKDIR" ]; then
        rm -rf "$WORKDIR"
        echo "[+] Deleted $WORKDIR"
    else
        echo "[!] htop-android-build folder not found, skipping..."
    fi

    echo "[+] Cleanup complete!"
else
    echo "[+] Keeping build folders. They can be found in: $WORKDIR"
fi

echo ""
echo "=========================================================="
echo "[+] Build and save complete! Your binary is ready to use."
echo "=========================================================="

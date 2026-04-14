#!/usr/bin/env bash
set -e

# ================================
# Configuration
# ================================
API=35                              # Android 15+
NDK_VERSION=r29                    # Version NDK
WORKDIR=$HOME/android-build
PREFIX=$WORKDIR/install
OUTPUT=$WORKDIR/output

# ================================
# Preparing the environment
# ================================
mkdir -p "$WORKDIR" "$PREFIX" "$OUTPUT"
cd "$WORKDIR"

# Download NDK if it doesn't exist
if [ ! -d "$HOME/android-ndk-$NDK_VERSION" ]; then
    echo "[+] Downloading Android NDK $NDK_VERSION..."
    wget -q https://dl.google.com/android/repository/android-ndk-$NDK_VERSION-linux.zip
    unzip -q android-ndk-$NDK_VERSION-linux.zip -d $HOME
fi

export NDK=$HOME/android-ndk-$NDK_VERSION
export PATH=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH

TOOLCHAIN_DIR=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin
export CC="$TOOLCHAIN_DIR/aarch64-linux-android$API-clang"
export CXX="$TOOLCHAIN_DIR/aarch64-linux-android$API-clang++"
export AR="$TOOLCHAIN_DIR/llvm-ar"
export LD="$TOOLCHAIN_DIR/ld.lld"
export STRIP="$TOOLCHAIN_DIR/llvm-strip"p

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
make -j$(nproc)
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
./autogen.sh
PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig \
CPPFLAGS="-I$PREFIX/include -I$PREFIX/include/ncursesw" \
LDFLAGS="-L$PREFIX/lib" \
./configure \
    --host=aarch64-linux-android \
    --prefix=$PREFIX \
    --enable-unicode
make -j$(nproc)
make install
cd ..

# ================================
# Finalization
# ================================
cp $PREFIX/bin/htop $OUTPUT/
echo "[+] Done! The binary file can be found in: $OUTPUT/htop"

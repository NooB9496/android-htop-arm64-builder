#!/usr/bin/env bash
set -e

# ================================
# Configuration
# ================================
API=33                              # Android 13+
NDK_VERSION=r26b                    # Version NDK
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

export CC=aarch64-linux-android$API-clang
export CXX=aarch64-linux-android$API-clang++
export AR=llvm-ar
export LD=ld.lld
export STRIP=llvm-strip

# ================================
# Building ncurses
# ================================
if [ ! -d ncurses-6.4 ]; then
    echo "[+] Downloading ncurses..."
    wget -q https://invisible-mirror.net/archives/ncurses/ncurses-6.4.tar.gz
    tar xf ncurses-6.4.tar.gz
fi

cd ncurses-6.4
echo "[+] Building ncurses..."
./configure \
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

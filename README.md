This script compiles HTOP for Android ARM64 versions 15+.
The script downloads the Android NDK, ncurses version 6.6, and HTOP.
It then compiles ncurses for Android ARM64 and htop.
The compiled htop binary is saved in the $OUTPUT/htop.

You can run this script on your linux machine with x64 CPU.

Just use this commands

chmod +x ./build-htop.sh

./build-htop.sh

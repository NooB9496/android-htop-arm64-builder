This script compiles HTOP for Android ARM64 versions 15+.
The script downloads the Android NDK, ncurses version 6.6, and HTOP.
It then compiles ncurses for Android ARM64 and htop.
The compiled htop binary is saved in the $OUTPUT/htop.

Docker needed for making small container and compile binary.

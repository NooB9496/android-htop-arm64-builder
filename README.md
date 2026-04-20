This script compiles HTOP for Android ARM64 versions 15+.
The script downloads the Android NDK, ncurses version 6.6, and HTOP.
It then compiles ncurses for Android ARM64 and htop.
The compiled htop binary is saved in the $OUTPUT/htop.

Docker needed for making small container and compile binary.

sudo usermod -aG docker $USER ## after that, reboot or restart docker and docker service

docker build -t htop-builder .

## buildozer is a user profile name, change to your profile name

docker run -rm \
-v "$(pwd):/home/buildozer" \
htop-builder bash /home/buildozer/build-htop.sh

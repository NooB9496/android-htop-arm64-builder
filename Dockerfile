# Use a stable and small Debian image as a base.
FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive


# Install all necessary system tools (Host Dependencies)
# that script requires (wget, tar, git, autoconf/automake).
RUN apt update && apt install -y \
    build-essential \
    git \
    wget \
    tar \
    unzip \
    autoconf \
    automake \
    python3 \
    pkg-config

# Create a workspace in a container.
RUN useradd -ms /bin/bash buildozer
USER buildozer
WORKDIR /home/buildozer

# Copy the entire bash script to the container.
COPY build-htop.sh .

# Execute the script immediately after starting the container.
CMD ["/bin/bash", "build-htop.sh"]

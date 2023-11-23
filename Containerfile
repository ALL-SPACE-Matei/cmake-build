ARG ARM_R5_GNUTOOLS_FILENAME=gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2
ARG ARM_R5_GNUTOOLS_SOURCE=https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/${ARM_R5_GNUTOOLS_FILENAME}
ARG ARM_R5_GNUTOOLS_SHA256=bcd840f839d5bf49279638e9f67890b2ef3a7c9c7a9b25271e83ec4ff41d177a
ARG ARM_R5_GNUTOOLS_DESTINATION=/usr/local/tools/ARM/r5

ARG ARM_A53_GNUTOOLS_FILENAME=gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu.tar.xz
ARG ARM_A53_GNUTOOLS_SOURCE=https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/${ARM_A53_GNUTOOLS_FILENAME}
ARG ARM_A53_GNUTOOLS_SHA256=8dfe681531f0bd04fb9c53cf3c0a3368c616aa85d48938eebe2b516376e06a66
ARG ARM_A53_GNUTOOLS_DESTINATION=/usr/local/tools/ARM/a53

ARG NXP_GNUTOOLS_FILENAME=NXP_GNUTools_9.3.1.tar.bz2
ARG NXP_GNUTOOLS_SOURCE=https://github.com/ALL-SPACE-Matei/cmake-build/releases/download/archives/${NXP_GNUTOOLS_FILENAME}
ARG NXP_GNUTOOLS_SHA256=2cb2de1c50a153aa331dd129e427afcd60b7defa3353a07e896e5e59ee575147
ARG NXP_GNUTOOLS_DESTINATION=/usr/local/tools/NXP

ARG ARM_OPENSSL_FILENAME=openssl.tar.xz
ARG ARM_OPENSSL_SOURCE=https://github.com/ALL-SPACE-Matei/openssl-a53/releases/download/latest/${ARM_OPENSSL_FILENAME}
ARG ARM_OPENSSL_SHA256=6d9f0fbf0e6b3fa748f459800f32f6ed4608ea421701f87d81fbf6f0f7b6954d
ARG ARM_OPENSSL_DESTINATION=/usr/local/lib/ARM/a53/openssl

# General configuration
ARG UBUNTU_VERSION=20.04
ARG CLANG_VERSION=10
ARG GCC_VERSION=9
ARG NODE_MAJOR=18

# Use a 'downloads' stage to avoid having the original archives in the final image,
# and since 'ADD' doesn't also unpack the archives
FROM scratch AS downloads

ARG ARM_R5_GNUTOOLS_SOURCE
ARG ARM_A53_GNUTOOLS_SOURCE
ARG NXP_GNUTOOLS_SOURCE
ARG ARM_OPENSSL_SOURCE
ARG ARM_R5_GNUTOOLS_SHA256
ARG ARM_A53_GNUTOOLS_SHA256
ARG NXP_GNUTOOLS_SHA256
ARG ARM_OPENSSL_SHA256

ADD --checksum=sha256:${ARM_R5_GNUTOOLS_SHA256}  ${ARM_R5_GNUTOOLS_SOURCE}  /
ADD --checksum=sha256:${ARM_A53_GNUTOOLS_SHA256} ${ARM_A53_GNUTOOLS_SOURCE} /
ADD --checksum=sha256:${NXP_GNUTOOLS_SHA256}     ${NXP_GNUTOOLS_SOURCE}     /
ADD --checksum=sha256:${ARM_OPENSSL_SHA256}      ${ARM_OPENSSL_SOURCE}      /

FROM ubuntu:${UBUNTU_VERSION}

ARG CLANG_VERSION
ARG GCC_VERSION
ARG NODE_MAJOR

ARG ARM_R5_GNUTOOLS_FILENAME
ARG ARM_R5_GNUTOOLS_DESTINATION

ARG ARM_A53_GNUTOOLS_FILENAME
ARG ARM_A53_GNUTOOLS_DESTINATION

ARG NXP_GNUTOOLS_FILENAME
ARG NXP_GNUTOOLS_DESTINATION

ARG ARM_OPENSSL_FILENAME
ARG ARM_OPENSSL_DESTINATION

LABEL org.opencontainers.image.title="ALL-SPACE C++/node development"
LABEL org.opencontainers.image.source=https://github.com/ALL-SPACE-Matei/cmake-build
LABEL org.opencontainers.image.description="C++/node build container based ubuntu-${UBUNTU_VERSION}, cmake, clang-${CLANG_VERSION}, gcc-${GCC_VERSION}, ARM toolchains and node-${NODE_MAJOR}"

ENV TZ=UTC
ENV DEBIAN_FRONTEND=noninteractive

# Install system requirements
RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata && \
    apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    clang-${CLANG_VERSION} \
    clang-tools-${CLANG_VERSION} \
    clangd-${CLANG_VERSION} \
    cmake \
    cppcheck \
    doxygen \
    file \
    gcc-${GCC_VERSION} \
    g++-${GCC_VERSION} \
    gcovr \
    gdb \
    git \
    gnupg \
    libssl-dev \
    libunwind-dev \
    libncurses-dev \
    openssh-server \
    python3 \
    srecord \
    vim \
    xz-utils \
    zstd

# Set gcc version
RUN update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} 50 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 50 && \
    update-alternatives --install /usr/bin/cpp cpp-bin /usr/bin/cpp-${GCC_VERSION} 50 && \
    update-alternatives --set g++ /usr/bin/g++-${GCC_VERSION} && \
    update-alternatives --set gcc /usr/bin/gcc-${GCC_VERSION} && \
    update-alternatives --set cpp-bin /usr/bin/cpp-${GCC_VERSION}

# Add ARM toolchains
# Bind mounts are to avoid copying the archives in the final image
RUN --mount=from=downloads,target=/downloads \
    mkdir -p ${ARM_R5_GNUTOOLS_DESTINATION} && \
    tar -xf /downloads/${ARM_R5_GNUTOOLS_FILENAME} -C ${ARM_R5_GNUTOOLS_DESTINATION} && \
    mkdir -p ${ARM_A53_GNUTOOLS_DESTINATION} && \
    tar -xf /downloads/${ARM_A53_GNUTOOLS_FILENAME} -C ${ARM_A53_GNUTOOLS_DESTINATION} && \
    mkdir -p ${NXP_GNUTOOLS_DESTINATION} && \
    tar -xf /downloads/${NXP_GNUTOOLS_FILENAME} -C ${NXP_GNUTOOLS_DESTINATION} && \
    mkdir -p ${ARM_OPENSSL_DESTINATION} && \
    tar -xf /downloads/${ARM_OPENSSL_FILENAME} -C ${ARM_OPENSSL_DESTINATION}

# Download and import the Nodesource GPG key
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

# Create deb repository
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list

# Run Update and Install nodejs
RUN apt-get update && \
    apt-get install -y --no-install-recommends nodejs

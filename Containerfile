ARG ARM_R5_GNUTOOLS_FILENAME=gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2
ARG ARM_R5_GNUTOOLS_SOURCE=https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/${ARM_R5_GNUTOOLS_FILENAME}
ARG ARM_R5_GNUTOOLS_SHA256=bcd840f839d5bf49279638e9f67890b2ef3a7c9c7a9b25271e83ec4ff41d177a
ARG ARM_R5_GNUTOOLS_DESTINATION=/usr/local/tools/ARM/r5

ARG ARM_A53_GNUTOOLS_FILENAME=gcc-arm-none-eabi-9-2020-q2-update-x86_64-linux.tar.bz2
ARG ARM_A53_GNUTOOLS_SOURCE=https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2020q2/${ARM_A53_GNUTOOLS_FILENAME}
ARG ARM_A53_GNUTOOLS_SHA256=5adc2ee03904571c2de79d5cfc0f7fe2a5c5f54f44da5b645c17ee57b217f11f
ARG ARM_A53_GNUTOOLS_DESTINATION=/usr/local/tools/ARM/a53

ARG NXP_GNUTOOLS_FILENAME=NXP_GNUTools_9.3.1.tar.bz2
ARG NXP_GNUTOOLS_SOURCE=https://github.com/ALL-SPACE-Matei/build-container/releases/download/archives/${NXP_GNUTOOLS_FILENAME}
ARG NXP_GNUTOOLS_SHA256=2cb2de1c50a153aa331dd129e427afcd60b7defa3353a07e896e5e59ee575147
ARG NXP_GNUTOOLS_DESTINATION=/usr/local/tools/NXP

ARG ARM_OPENSSL_FILENAME=openssl-1.1.1o.tar.bz2
ARG ARM_OPENSSL_SOURCE=https://github.com/ALL-SPACE-Matei/build-container/releases/download/archives/${ARM_OPENSSL_FILENAME}
ARG ARM_OPENSSL_SHA256=86841853b62ceaac4e3124ed1a2dbbc78e783d7ae6e4738ceddc20b007528fc1
ARG ARM_OPENSSL_DESTINATION=${ARM_A53_GNUTOOLS_DESTINATION}

ARG CLANG_VERSION=10
ARG GCC_VERSION=9
ARG NODE_MAJOR=18

FROM scratch AS downloads

ARG ARM_R5_GNUTOOLS_SOURCE
ARG ARM_A53_GNUTOOLS_SOURCE
ARG NXP_GNUTOOLS_SOURCE
ARG ARM_OPENSSL_SOURCE

# Checksum support is present in buildah since commit cb30712, tag v1.33.0
# Uncomment when the version of buildah in use is updated
# ARG ARM_R5_GNUTOOLS_SHA256
# ARG ARM_A53_GNUTOOLS_SHA256
# ARG NXP_GNUTOOLS_SHA256
# ARG ARM_OPENSSL_SHA256
# ADD --checksum=sha256=${ARM_R5_GNUTOOLS_SHA256}  ${ARM_R5_GNUTOOLS_SOURCE}  /
# ADD --checksum=sha256=${ARM_A53_GNUTOOLS_SHA256} ${ARM_A53_GNUTOOLS_SOURCE} /
# ADD --checksum=sha256=${NXP_GNUTOOLS_SHA256}     ${NXP_GNUTOOLS_SOURCE}     /
# ADD --checksum=sha256=${ARM_OPENSSL_SHA256}      ${ARM_OPENSSL_SOURCE}      /

ADD ${ARM_R5_GNUTOOLS_SOURCE}  /
ADD ${ARM_A53_GNUTOOLS_SOURCE} /
ADD ${NXP_GNUTOOLS_SOURCE}     /
ADD ${ARM_OPENSSL_SOURCE}      /

FROM ubuntu:20.04

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

LABEL org.opencontainers.image.description "C++ build container based on cmake, clang-${CLANG_VERSION}, gcc-${GCC_VERSION}, ARM toolchains and node-${NODE_MAJOR}"

ENV TZ=UTC
ENV DEBIAN_FRONTEND=noninteractive

# Add ARM toolchains
RUN --mount=type=bind,from=downloads,source=/${ARM_R5_GNUTOOLS_FILENAME},target=/${ARM_R5_GNUTOOLS_FILENAME} \
    mkdir -p ${ARM_R5_GNUTOOLS_DESTINATION}  && tar -xf ${ARM_R5_GNUTOOLS_FILENAME}  -C ${ARM_R5_GNUTOOLS_DESTINATION}
RUN --mount=type=bind,from=downloads,source=/${ARM_A53_GNUTOOLS_FILENAME},target=/${ARM_A53_GNUTOOLS_FILENAME} \
    mkdir -p ${ARM_A53_GNUTOOLS_DESTINATION} && tar -xf ${ARM_A53_GNUTOOLS_FILENAME} -C ${ARM_A53_GNUTOOLS_DESTINATION}
RUN --mount=type=bind,from=downloads,source=/${NXP_GNUTOOLS_FILENAME},target=/${NXP_GNUTOOLS_FILENAME} \
    mkdir -p ${NXP_GNUTOOLS_DESTINATION}     && tar -xf ${NXP_GNUTOOLS_FILENAME}     -C ${NXP_GNUTOOLS_DESTINATION}
RUN --mount=type=bind,from=downloads,source=/${ARM_OPENSSL_FILENAME},target=/${ARM_OPENSSL_FILENAME} \
    mkdir -p ${ARM_OPENSSL_DESTINATION}      && tar -xf ${ARM_OPENSSL_FILENAME}      -C ${ARM_OPENSSL_DESTINATION}

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata && \
    apt-get install -y --no-install-recommends \
    build-essential \
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
    libssl-dev \
    libunwind-dev \
    libncurses-dev \
    openssh-server \
    python3 \
    srecord \
    vim \
    zstd

# Set gcc version
RUN \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} 50 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 50 && \
    update-alternatives --install /usr/bin/cpp cpp-bin /usr/bin/cpp-${GCC_VERSION} 50 && \
    update-alternatives --set g++ /usr/bin/g++-${GCC_VERSION} && \
    update-alternatives --set gcc /usr/bin/gcc-${GCC_VERSION} && \
    update-alternatives --set cpp-bin /usr/bin/cpp-${GCC_VERSION}

# Install requirements
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg

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

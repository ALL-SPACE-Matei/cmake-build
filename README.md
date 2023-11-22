[![Container image](https://github.com/ALL-SPACE-Matei/cmake-build/actions/workflows/container-build-and-publish.yml/badge.svg?branch=main)](https://github.com/ALL-SPACE-Matei/cmake-build/actions/workflows/container-build-and-publish.yml)

## Description

This is a build environment container based on Ubuntu and composed of:

- NXP, ARM R5, ARM A53 toolchains
- prebuilt OpenSSL for ARM
- C/C++ build tools: gcc, clang, cmake
- nodejs

## Usage

The latest version ca be pulled via:

`docker pull ghcr.io/all-space-matei/cmake-build:<TAG>`

where `<TAG>` can be one of:

- `latest`
- version tag: `v1`
- commit hash: `7377712609393c6e7844c4c696c41b899dbe25dd`

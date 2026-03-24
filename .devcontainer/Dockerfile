# syntax=docker/dockerfile:1

# Prebuilt Rust devcontainer image (includes Rust toolchain + rust-analyzer friendly setup).
FROM mcr.microsoft.com/devcontainers/rust:2-bookworm

# Tools for bindgen + typical native dependencies.
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    pkg-config \
    clang \
    llvm \
    libclang-dev \
    cmake \
    ninja-build \
    gcc-arm-none-eabi \
    binutils-arm-none-eabi \
    libnewlib-arm-none-eabi \
    libstdc++-arm-none-eabi-newlib \
    gdb-multiarch \
    libudev-dev \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd -f plugdev \
  && usermod -aG plugdev vscode

USER vscode

# Install Rust target artifacts used for nRF52 builds ("thumbv7em headers").
# Also install rust-src for better rust-analyzer support in no_std/cross setups.
RUN rustup target add thumbv7em-none-eabihf thumbv7em-none-eabi \
  && rustup component add rust-src \
  && cargo install probe-rs-tools

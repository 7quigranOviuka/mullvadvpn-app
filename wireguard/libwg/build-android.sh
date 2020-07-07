#!/usr/bin/env bash

set -eu

# Ensure we are in the correct directory for the execution of this script
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $script_dir

# Keep a GOPATH in the build directory to maintain a cache of downloaded libraries
export GOPATH=$script_dir/../../build/android-go-path/
mkdir -p $GOPATH

for arch in arm arm64 x86_64 x86; do
    case "$arch" in
        "arm64")
            export ANDROID_LLVM_TRIPLE="aarch64-linux-android"
            export RUST_TARGET_TRIPLE="aarch64-linux-android"
            export ANDROID_ABI="arm64-v8a"
            ;;
        "x86_64")
            export ANDROID_LLVM_TRIPLE="x86_64-linux-android"
            export RUST_TARGET_TRIPLE="x86_64-linux-android"
            export ANDROID_ABI="x86_64"
            ;;
        "arm")
            export ANDROID_LLVM_TRIPLE="armv7a-linux-androideabi"
            export RUST_TARGET_TRIPLE="armv7-linux-androideabi"
            export ANDROID_ABI="armeabi-v7a"
            ;;
        "x86")
            export ANDROID_LLVM_TRIPLE="i686-linux-android"
            export RUST_TARGET_TRIPLE="i686-linux-android"
            export ANDROID_ABI="x86"
            ;;
    esac

    export ANDROID_C_COMPILER="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/${ANDROID_LLVM_TRIPLE}21-clang"
    export ANDROID_ARCH_NAME=$arch

    # Build Wireguard-Go
    echo $(pwd)
    make -f Android.mk clean

    export CFLAGS="-D__ANDROID_API__=21"

    make -f Android.mk
    # Copy build artifacts to `build/libs/$RUST_TARGET_TRIPLE` to be able to build `mullvad-jni`
    chmod 777 ../../android/build/
    chmod 777 ../../android/build/extraJni
    chmod 777 ../../android/build/extraJni/*
    mkdir -p ../../build/lib/$RUST_TARGET_TRIPLE
    cp ../../android/build/extraJni/$ANDROID_ABI/libwg.so ../../build/lib/$RUST_TARGET_TRIPLE
    chmod 777 ../../android/build/extraJni/$ANDROID_ABI/libwg.so ../../build/lib/$RUST_TARGET_TRIPLE
    rm -rf build
done

# ensure `git clean -fd` does not require root permissions
find $GOPATH -exec chmod +rw {} \;

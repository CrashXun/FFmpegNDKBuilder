#!/bin/bash
#set -e


echo "===================="
echo "[*] Toolchain $1"
echo "===================="

export ARCH=$1

if [ -z "$ARCH" ]; then
    echo "You must specific an architecture 'arm, armv7a, x86, ...'."
    echo ""
    exit 1
elif [ -z "$FF_NDK" ]; then
    echo "You must define ANDROID_NDK before starting."
    echo "They must point to your NDK directories."
    echo ""
    exit 1
fi

ANDROID_VER_32=android-14
ANDROID_VER_64=android-21

export GCC_VER=4.9
export GCC_64_VER=4.9
export SYSROOT=
export CROSS_PREFIX=
export TOOLCHAIN=
export ANDROID_PLATFORM=

#eg: --cross-prefix=$CFLAG_CROSS_PREFIX
export CFLAG_CROSS_PREFIX=
#eg: --sysroot=$CFLAG_SYSROOT
export CFLAG_SYSROOT=



armv5() {
    CROSS_PREFIX=arm-linux-androideabi
    ANDROID_PLATFORM=$ANDROID_VER_32
    SYSROOT=$FF_NDK/platforms/$ANDROID_PLATFORM/arch-arm
}

armv7a() {
    CROSS_PREFIX=arm-linux-androideabi
    ANDROID_PLATFORM=$ANDROID_VER_32
    SYSROOT=$FF_NDK/platforms/$ANDROID_PLATFORM/arch-arm

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS \
-march=armv7-a \
-mcpu=cortex-a8 \
-mfpu=vfpv3-d16 \
-mfloat-abi=softfp \
-mthumb"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -Wl,--fix-cortex-a8"
}

arm64() {
    CROSS_PREFIX=aarch64-linux-android
    ANDROID_PLATFORM=$ANDROID_VER_64
    SYSROOT=$FF_NDK/platforms/$ANDROID_PLATFORM/arch-arm64
}

x86(){
    CROSS_PREFIX=i686-linux-android
    ANDROID_PLATFORM=$ANDROID_VER_32
    SYSROOT=$FF_NDK/platforms/$ANDROID_PLATFORM/arch-x86
}

x86_64(){
    CROSS_PREFIX=x86_64-linux-android
    ANDROID_PLATFORM=$ANDROID_VER_64
    SYSROOT=$FF_NDK/platforms/$ANDROID_PLATFORM/arch-x86_64
}

set -x
case "$ARCH" in
    armv5)
        armv5
    ;;

    armv7a)
        armv7a
    ;;

    arm64)
        arm64
    ;;

    x86)
        x86
    ;;

    x86_64)
        x86_64
    ;;

    *)
        echo "please enter ARCH"
        exit 1
    ;;
esac

TOOLCHAIN=$FF_NDK/toolchains/${CROSS_PREFIX}-${GCC_VER}/prebuilt/$TOOLCHAIN_SYSTEM
CFLAG_CROSS_PREFIX=$TOOLCHAIN/bin/${CROSS_PREFIX}-
CFLAG_SYSROOT=$SYSROOT

#export CC="${FF_CROSS_PREFIX}-gcc"
export LD=${CFLAG_CROSS_PREFIX}ld
#export AR=${FF_CROSS_PREFIX}-ar
#export STRIP=${FF_CROSS_PREFIX}-strip





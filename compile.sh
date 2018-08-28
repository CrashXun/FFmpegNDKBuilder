#!/bin/bash
set -e

basepath=$(cd `dirname $0`; pwd)
source environment.sh

UNI_BUILD_ROOT=`pwd`
FF_TARGET=$1
FF_TARGET_EXTRA=$2

FF_ACT_ARCHS_32="armv5 armv7a x86"
FF_ACT_ARCHS_64="armv5 armv7a arm64 x86 x86_64"
FF_ACT_ARCHS_ALL=$FF_ACT_ARCHS_64


#absolute path
export SOURCE_FFMPEG="/Users/xunxun/source/ndk/ffmpeg/ffmpeg"
export SOURCE_X264=
export SOURCE_FDK_AAC=

if test ! -d $SOURCE_FFMPEG; then
    SOURCE_FFMPEG="/home/xunxun/Documents/ffmpeg/ffmpeg"
fi

export COM_OUTPUT_FOLD="build"

echo_archs() {
    echo "===================="
    echo "[*] check archs"
    echo "===================="
    echo "FF_ALL_ARCHS = $FF_ACT_ARCHS_ALL"
    echo "FF_ACT_ARCHS = $*"
    echo ""
}

echo_usage() {
    echo "Usage:"
    echo "  compile.sh armv5|armv7a|arm64|x86|x86_64"
    echo "  compile.sh all|all32"
    echo "  compile.sh all64"
    echo "  compile.sh clean"
    echo "  compile.sh check"
    exit 1
}

startCompile() {
    cd $basepath
    archparam=$1
    source toolchain.sh $archparam
    cd $SOURCE_FFMPEG
    source ${basepath}/ffmpeg_common_param.sh $archparam
    sh ${basepath}/compile_ffmpeg.sh $archparam
    
    # cd $SOURCE_X264
    # sh ${basepath}/compile_x264.sh $archparam

    # cd $SOURCE_FDK_AAC
    # sh ${basepath}/compile_fdk_aac.sh $archparam
}

check_var() {
    if [ ! -d "$SOURCE_FFMPEG" ]; then
        echo "error"
        echo "please set var SOURCE_FFMPEG and SOURCE_X264 and SOURCE_FDK_AAC"
        exit 1
    fi
}

check_var
case "$FF_TARGET" in
    armv5|armv7a|arm64|x86|x86_64)
        echo_archs $FF_TARGET 
        startCompile $FF_TARGET
    ;;
    all32)
        echo_archs $FF_ACT_ARCHS_32
        for ARCH in $FF_ACT_ARCHS_32
        do
            startCompile $ARCH
        done
    ;;
    all|all64)
        echo_archs $FF_ACT_ARCHS_64
        for ARCH in $FF_ACT_ARCHS_64
        do
            startCompile $ARCH
        done
    ;;
    clean)
        echo_archs FF_ACT_ARCHS_64
        rm -rf ./build/ffmpeg-*
    ;;
    check)
        echo_archs FF_ACT_ARCHS_ALL
    ;;
    *)
        echo_usage
        exit 1
    ;;
esac

exit 0


createSo(){
	$TOOLCHAIN/bin/arm-linux-androideabi-ld \
-rpath-link=$PLATFORM/usr/lib \
-L$PLATFORM/usr/lib \
-L$PREFIX/lib \
-L$X264_LIB \
-soname libffmpeg.so -shared -nostdlib -Bsymbolic --whole-archive --no-undefined -o \
$PREFIX/libffmpeg.so \
libavcodec/libavcodec.a \
libavdevice/libavdevice.a \
libavresample/libavresample.a \
libpostproc/libpostproc.a \
libavfilter/libavfilter.a \
libswresample/libswresample.a \
libavformat/libavformat.a \
libavutil/libavutil.a \
libswscale/libswscale.a \
$X264_LIB/libx264.a \
$fdkaac_LIB/libfdk-aac.a \
-lc -lm -lz -ldl -llog --dynamic-linker=/system/bin/linker \
$TOOLCHAIN/lib/gcc/arm-linux-androideabi/4.9.x/libgcc.a
}

export NDK=/home/xunxun/devtool/android-ndk-r15c
export TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64
export PLATFORM=$NDK/platforms/android-16/arch-arm

#libx264编译产物位置，ffmpeg编译需要依赖
x264_lib=/home/xunxun/dev/x264_build4android/arm
X264_INCLUDE=${x264_lib}/include
X264_LIB=${x264_lib}/lib

fdkaac_lib=/home/xunxun/Documents/ffmpeg/fdk-aac/fdk-aac-0.1.5/android/arm
fdkaac_INCLUDE=${fdkaac_lib}/include
fdkaac_LIB=${fdkaac_lib}/lib

# arm v7vfp



echo "build finish"
sleep 5
echo "createSo"
#链接静态库为一个动态库
createSo


#!/bin/bash
set -e

export basepath=$(cd `dirname $0`; pwd)
source environment.sh

UNI_BUILD_ROOT=`pwd`
FF_TARGET=$1
FF_TARGET_EXTRA=$2

#x86 x86_64
FF_ACT_ARCHS_32="armv5 armv7a x86"
FF_ACT_ARCHS_64="armv5 armv7a arm64"
FF_ACT_ARCHS_ALL=$FF_ACT_ARCHS_64

#absolute path
export SOURCE_FFMPEG="/Users/xunxun/source/ndk/ffmpeg/ffmpeg"
export SOURCE_X264="/Users/xunxun/source/ndk/ffmpeg/x264"
export SOURCE_FDK_AAC="/Users/xunxun/source/ndk/ffmpeg/fdk-aac/fdk-aac-0.1.5"
export SOURCE_YUV="/Users/xunxun/source/ndk/ffmpeg/libyuv"

export OUTPUT_FFMPEG=$basepath/output/ffmpeg
export OUTPUT_X264=$basepath/output/x264
export OUTPUT_FDK_AAC=$basepath/output/fdk-aac
export OUTPUT_YUV=$basepath/output/yuv

mkdir -p $OUTPUT_FFMPEG
mkdir -p $OUTPUT_X264
mkdir -p $OUTPUT_FDK_AAC
mkdir -p $OUTPUT_YUV

if test ! -d $SOURCE_FFMPEG; then
    SOURCE_FFMPEG="/home/xunxun/Documents/ffmpeg/ffmpeg"
fi

if test ! -d $SOURCE_X264; then
    SOURCE_X264="/home/xunxun/Documents/ffmpeg/x264"
fi

if test ! -d $SOURCE_FDK_AAC; then
    SOURCE_FDK_AAC="/home/xunxun/Documents/ffmpeg/fdk-aac/fdk-aac-0.1.5"
    #SOURCE_FDK_AAC="/home/xunxun/Documents/ffmpeg/fdk-aac-0.1.6"
fi

if test ! -d $SOURCE_YUV; then
    SOURCE_YUV="/home/xunxun/Documents/ffmpeg/libyuv"
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

    if [ "$FF_TARGET_EXTRA"="link" ]; then
        cd $SOURCE_FFMPEG
        source ${basepath}/ffmpeg_common_param.sh $archparam
        sh ${basepath}/compile_ffmpeg.sh $archparam $FF_TARGET_EXTRA
    else
        #************x264************
        cd $SOURCE_X264
        sh ${basepath}/compile_x264.sh $archparam

        #************fdk-aac************
        cd $SOURCE_FDK_AAC
        sh ${basepath}/compile_fdk-aac.sh $archparam

        #************ffmpeg************
        cd $SOURCE_FFMPEG
        source ${basepath}/ffmpeg_common_param.sh $archparam
        sh ${basepath}/compile_ffmpeg.sh $archparam
        
        #************yuv************
        cd $SOURCE_YUV
        sh ${basepath}/compile_yuv.sh $archparam
    fi
}

check_var() {
    if [ ! -d "$SOURCE_FFMPEG" ]; then
        echo "error"
        echo "please set var SOURCE_FFMPEG"
        exit 1
    fi

    if [ ! -d "$SOURCE_X264" ]; then
        echo "error"
        echo "please set var SOURCE_X264"
        exit 1
    fi

    if [ ! -d "$SOURCE_FDK_AAC" ]; then
        echo "error"
        echo "please set var SOURCE_FDK_AAC"
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
        #call subscript clean
#...
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



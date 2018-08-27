#!/bin/bash
set -e


source environment.sh

UNI_BUILD_ROOT=`pwd`
FF_TARGET=$1
FF_TARGET_EXTRA=$2

FF_ACT_ARCHS_32="armv5 armv7a x86"
FF_ACT_ARCHS_64="armv5 armv7a arm64 x86 x86_64"
FF_ACT_ARCHS_ALL=$FF_ACT_ARCHS_64



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


case "$FF_TARGET" in
    armv5|armv7a|arm64|x86|x86_64)
        echo_archs $FF_TARGET 
        source toolchain.sh $FF_TARGET
    ;;
    all32)
        echo_archs $FF_ACT_ARCHS_32
        for ARCH in $FF_ACT_ARCHS_32
        do
            source toolchain.sh $ARCH
        done
    ;;
    all|all64)
        echo_archs $FF_ACT_ARCHS_64
        for ARCH in $FF_ACT_ARCHS_64
        do
            source toolchain.sh $ARCH
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

 build_one() {
    ./configure \
--prefix=$PREFIX \
--arch=arm \
--cpu=armv7-a \
--target-os=android \
--enable-cross-compile \
--cross-prefix=$TOOLCHAIN/bin/arm-linux-androideabi- \
--sysroot=$PLATFORM \
--extra-cflags="-I$X264_INCLUDE -I$fdkaac_INCLUDE -I$PLATFORM/usr/include" \
--extra-ldflags="-L$X264_LIB -L$fdkaac_LIB" \
--cc=$TOOLCHAIN/bin/arm-linux-androideabi-gcc \
--nm=$TOOLCHAIN/bin/arm-linux-androideabi-nm \
--disable-shared \
--enable-static \
--enable-gpl \
--enable-version3 \
--enable-pthreads \
--enable-runtime-cpudetect \
--disable-small \
--enable-network \
--disable-vda \
--disable-iconv \
--enable-asm \
--enable-neon \
--enable-yasm \
--disable-encoders \
--enable-libx264 \
--enable-libfdk-aac \
--enable-encoder=libx264 \
--enable-encoder=aac \
--enable-encoder=mpeg4 \
--enable-encoder=mjpeg \
--enable-encoder=png \
--disable-muxers \
--enable-muxer=mov \
--enable-muxer=mp4 \
--enable-muxer=adts \
--enable-muxer=h264 \
--enable-muxer=mjpeg \
--disable-decoders \
--enable-decoder=aac \
--enable-decoder=aac_latm \
--enable-decoder=mp3 \
--enable-decoder=h264 \
--enable-decoder=mpeg4 \
--enable-decoder=mjpeg \
--enable-decoder=png \
--disable-demuxers \
--enable-demuxer=rtsp \
--enable-demuxer=image2 \
--enable-demuxer=h264 \
--enable-demuxer=aac \
--enable-demuxer=mp3 \
--enable-demuxer=mpc \
--enable-demuxer=mpegts \
--enable-demuxer=mov \
--disable-parsers \
--enable-parser=aac \
--enable-parser=ac3 \
--enable-parser=h264 \
--disable-protocols \
--enable-protocol=file \
--enable-protocol=concat \
--enable-protocol=tcp \
--enable-protocol=udp \
--enable-filters \
--enable-zlib \
--disable-outdevs \
--disable-doc \
--disable-ffplay \
--disable-ffmpeg \
--disable-ffserver \
--disable-debug \
--disable-ffprobe \
--enable-postproc \
--enable-avdevice \
--enable-avresample \
--enable-nonfree \
--disable-symver \
--disable-stripping \
--enable-jni \
--enable-mediacodec \
--enable-decoder=h264_mediacodec \
--enable-hwaccel=h264_mediacodec \
--enable-decoder=hevc_mediacodec \
--extra-cflags="-Os -fpic $ADDI_CFLAGS" \
--extra-ldflags="$ADDI_LDFLAGS" \
$ADDITIONAL_CONFIGURE_FLAG


echo "config finish"
sleep 5
    make clean
    make -j8
    make install



}

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
CPU=arm-v7a
OPTIMIZE_CFLAGS="-mfloat-abi=softfp -mfpu=vfp -marm -march=armv7-a "
ADDI_CFLAGS="-marm"
#本次编译产物位置
PREFIX=/home/xunxun/dev/ffmpeg_build4android/android/$CPU

#生成静态库
build_one

echo "build finish"
sleep 5
echo "createSo"
#链接静态库为一个动态库
createSo


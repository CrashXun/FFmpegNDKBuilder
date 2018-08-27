#!/bin/bash

#set -x

ARCH=$1

echo "===================="
echo "[*] FFmpeg $1"
echo "===================="

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

#ffmpeg param
FF_CFG_FLAGS=

#ffmpeg compile param
FF_CFLAGS=
FF_EXTRA_CFLAGS=
FF_EXTRA_LDFLAGS=

OUTPUT_PATH=${SOURCE_FFMPEG}/${COM_OUTPUT_FOLD}/$ARCH
x264output=${SOURCE_X264}/${COM_OUTPUT_FOLD}/${ARCH}
aacoutput=${SOURCE_FDK_AAC}/${COM_OUTPUT_FOLD}/${ARCH}


armv5() {
   FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=arm --enable-asm --enable-inline-asm"
   FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=armv5te -mtune=arm9tdmi -msoft-float"
   FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
}

armv7a() {
	FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=arm --cpu=cortex-a8 --enable-asm --enable-inline-asm" 
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-neon"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-thumb"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS \
-march=armv7-a \
-mcpu=cortex-a8 \
-mfpu=vfpv3-d16 \
-mfloat-abi=softfp \
-mthumb"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -Wl,--fix-cortex-a8"
}

arm64() {
   	FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=aarch64 --enable-yasm --enable-asm --enable-inline-asm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
}

x86(){
	FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=x86 --cpu=i686 --enable-yasm --disable-asm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=atom -msse3 -ffast-math -mfpmath=sse"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
}

x86_64(){
    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=x86_64 --enable-yasm --enable-asm --enable-inline-asm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
}

_common(){
		echo "===============_common()==============="
	FF_CFG_FLAGS="$FF_CFG_FLAGS --prefix=$OUTPUT_PATH"
	FF_CFG_FLAGS="$FF_CFG_FLAGS --cross-prefix=$CFLAG_CROSS_PREFIX"
	FF_CFG_FLAGS="$FF_CFG_FLAGS --sysroot=$CFLAG_SYSROOT"
	FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-cross-compile"


	#FF_CFG_FLAGS="$FF_CFG_FLAGS --target-os=linux"
	#这里指定android,否则使用--enable-jni将报错
	FF_CFG_FLAGS="$FF_CFG_FLAGS --target-os=android"

	FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-pic"

	FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-optimizations"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-debug"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-small"

    FF_CFG_FLAGS="$FF_CFG_FLAGS $COMMON_FF_CFG_FLAGS"

    FF_CFLAGS="-O3 -Wall -pipe \
    -std=c99 \
    -ffast-math \
    -fstrict-aliasing -Werror=strict-aliasing \
    -Wno-psabi -Wa,--noexecstack \
    -DANDROID -DNDEBUG"

    #x264
    #FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-libx264"
    # FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -I${x264output}/include"
	# FF_DEP_LIBS="$FF_EXTRA_LDFLAGS -L${x264output}/lib"

    #aac
    #FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-libfdk-aac"

    # FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -I${aacoutput}/include"
	# FF_DEP_LIBS="$FF_EXTRA_LDFLAGS -L${aacoutput}/lib"

    #ndk
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -I${CFLAG_SYSROOT}/usr/include"
	# FF_DEP_LIBS="$FF_EXTRA_LDFLAGS -L${CFLAG_SYSROOT}/usr/lib"
    #FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -Os -fpic -marm"
}


_configure(){
	echo "===============_configure()==============="

	if [ ! -f "configure" ]; then
	    echo ""
	    echo "!! ERROR"
	    echo "!! Can not find ffmpeg's configure"
	    echo ""
	    exit 1
	fi

	./configure $FF_CFG_FLAGS \
		--cc=$NDK_CC \
		--nm=$NDK_LD \
        --extra-cflags="$FF_CFLAGS $FF_EXTRA_CFLAGS" \
        --extra-ldflags="$FF_DEP_LIBS $FF_EXTRA_LDFLAGS"
    
}

_make(){
	echo "===============_make()==============="
	make clean
    make -j8
    if [ -d "${OUTPUT_PATH}" ]; then
    	echo "rm ${OUTPUT_PATH}"
    	sleep 5
    	rm -rf ${OUTPUT_PATH}
    fi
    make install
    mkdir -p ${OUTPUT_PATH}/include/libffmpeg
	cp -f config.h ${OUTPUT_PATH}/include/libffmpeg/config.h
}

_link(){
	echo "===============_link()==============="
	LINK_FLG="$LINK_FLG -rpath-link=${CFLAG_SYSROOT}/usr/lib"
	LINK_FLG="$LINK_FLG -L${CFLAG_SYSROOT}/usr/lib"
	LINK_FLG="$LINK_FLG -L${OUTPUT_PATH}/lib"

	#LINK_FLG="$LINK_FLG -L${x264output}/lib"
	#LINK_FLG="$LINK_FLG -L${aacoutput}/lib"
	LINK_FLG="$LINK_FLG -soname libffmpeg.so -shared -nostdlib -Bsymbolic --whole-archive --no-undefined"
	LINK_FLG="$LINK_FLG -o ${OUTPUT_PATH}/libffmpeg.so"

	LINK_FLG="$LINK_FLG libavcodec/libavcodec.a"
	LINK_FLG="$LINK_FLG libavdevice/libavdevice.a"
	LINK_FLG="$LINK_FLG libavresample/libavresample.a"
	LINK_FLG="$LINK_FLG libpostproc/libpostproc.a"
	LINK_FLG="$LINK_FLG libavfilter/libavfilter.a"
	LINK_FLG="$LINK_FLG libswresample/libswresample.a"
	LINK_FLG="$LINK_FLG libavformat/libavformat.a"
	LINK_FLG="$LINK_FLG libavutil/libavutil.a"
	LINK_FLG="$LINK_FLG libswscale/libswscale.a"
	#LINK_FLG="$LINK_FLG ${x264output}/lib/libx264.a"
	#LINK_FLG="$LINK_FLG ${aacoutput}/lib/libfdk-aac.a"
	LINK_FLG="$LINK_FLG -lc -lm -lz -ldl -llog"
	LINK_FLG="$LINK_FLG --dynamic-linker=/system/bin/linker"
	LINK_FLG="$LINK_FLG $TOOLCHAIN/lib/gcc/$CROSS_PREFIX/4.9.x/libgcc.a"


	$NDK_LD $LINK_FLG
}


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

_common
_configure
sleep 5
_make
_link


# --extra-ldflags="$ADDI_LDFLAGS" \
# OPTIMIZE_CFLAGS="-mfloat-abi=softfp -mfpu=vfp -marm -march=armv7-a "


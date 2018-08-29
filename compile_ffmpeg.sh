#!/bin/bash

#set -x

ARCH=$1
FF_TARGET_EXTRA=$2

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
FF_ASSEMBLER_SUB_DIRS=
FF_MODULE_DIRS="compat libavcodec libavdevice libavresample libpostproc libavfilter libswresample \
libavformat libavutil libswscale"

OUTPUT_PATH=${SOURCE_FFMPEG}/${COM_OUTPUT_FOLD}/$ARCH
set -x
x264output=${OUTPUT_X264}/${ARCH}
aacoutput=${OUTPUT_FDK_AAC}/${ARCH}
yuvoutput=${OUTPUT_YUV}/${ARCH}
set +x

armv5() {
   FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=arm --enable-asm --enable-inline-asm"
   FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=armv5te -mtune=arm9tdmi -msoft-float"
   FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
    FF_ASSEMBLER_SUB_DIRS="arm"
}

armv7a() {
	FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=arm --cpu=cortex-a8 --enable-asm --enable-inline-asm" 
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-neon"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-thumb"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=armv7-a"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -mcpu=cortex-a8"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -mfpu=vfpv3-d16"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -mfloat-abi=softfp"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -mthumb"

    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -Wl,--fix-cortex-a8"
    FF_ASSEMBLER_SUB_DIRS="arm"
}

arm64() {
   	FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=aarch64 --enable-yasm --enable-asm --enable-inline-asm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
    FF_ASSEMBLER_SUB_DIRS="aarch64 neon"
}

x86(){
	FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=x86 --cpu=i686 --enable-yasm --disable-asm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=atom -msse3 -ffast-math -mfpmath=sse"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
    FF_ASSEMBLER_SUB_DIRS="x86"
}

x86_64(){
    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=x86_64 --enable-yasm --enable-asm --enable-inline-asm"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
    FF_ASSEMBLER_SUB_DIRS="x86"
}

_common(){
		echo "===============_common()==============="
	FF_CFG_FLAGS="$FF_CFG_FLAGS --prefix=$OUTPUT_PATH"
	FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-cross-compile"
	FF_CFG_FLAGS="$FF_CFG_FLAGS --cross-prefix=$CFLAG_CROSS_PREFIX"
	FF_CFG_FLAGS="$FF_CFG_FLAGS --sysroot=$CFLAG_SYSROOT"
    #FF_CFG_FLAGS="$FF_CFG_FLAGS --pkg-config-flags=--static" 
    #FF_CFG_FLAGS="$FF_CFG_FLAGS --bindir=$HOME/bin"

	#FF_CFG_FLAGS="$FF_CFG_FLAGS --target-os=linux"
	#这里指定android,否则使用--enable-jni将报错
	FF_CFG_FLAGS="$FF_CFG_FLAGS --target-os=android"

	FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-pic"

	FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-optimizations"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-debug"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-small"

    FF_CFG_FLAGS="$FF_CFG_FLAGS $COMMON_FF_CFG_FLAGS"

    FF_CFLAGS="$FF_CFLAGS -O3 -Wall -pipe"
    FF_CFLAGS="$FF_CFLAGS -std=c99"
    FF_CFLAGS="$FF_CFLAGS -ffast-math"
    FF_CFLAGS="$FF_CFLAGS -fstrict-aliasing -Werror=strict-aliasing"
    FF_CFLAGS="$FF_CFLAGS -Wno-psabi -Wa,--noexecstack"
    FF_CFLAGS="$FF_CFLAGS -DANDROID -DNDEBUG"

    #x264
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-libx264"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-encoder=libx264"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -I${x264output}/include"
	FF_DEP_LIBS="$FF_DEP_LIBS -L${x264output}/lib"
    
    #aac
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-libfdk-aac"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-encoder=libfdk_aac"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-decoder=libfdk_aac"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -I${aacoutput}/include"
	FF_DEP_LIBS="$FF_DEP_LIBS -L${aacoutput}/lib"

    

    #ndk
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -I${CFLAG_SYSROOT}/usr/include"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -L${CFLAG_SYSROOT}/usr/lib"
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -Os -fpic"
# -marm
    #FF_DEP_LIBS="$FF_EXTRA_LDFLAGS -lgcc"
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
        --nm=$NDK_NM \
        --extra-cflags="$FF_CFLAGS $FF_EXTRA_CFLAGS" \
        --extra-ldflags="$FF_DEP_LIBS $FF_EXTRA_LDFLAGS"

    if [ "$?" = "1" ];then
        exit 1
    fi
}

_make(){
	echo "===============_make()==============="
	make clean
    echo "delect *.o"
    set -x
    for MODULE_DIR in $FF_MODULE_DIRS
    do
        rm -f $MODULE_DIR/*.o

        for ASM_SUB_DIR in $FF_ASSEMBLER_SUB_DIRS
        do
            rm -f $MODULE_DIR/$ASM_SUB_DIR/*.o
           
        done
    done
    set +x
    make -j4
    if [ -d "${OUTPUT_PATH}" ]; then
    	echo "rm ${OUTPUT_PATH}"
    	sleep 2
    	rm -rf ${OUTPUT_PATH}
    fi

    if [ "$?" = "1" ];then
        exit 1
    fi

    make install
    mkdir -p ${OUTPUT_PATH}/include/libffmpeg
	cp -f config.h ${OUTPUT_PATH}/include/libffmpeg/config.h
}

_link(){
	echo "===============_link()==============="
    echo "--------------------"
    echo "[*] link ffmpeg"
    echo "--------------------"
    echo $FF_MODULE_DIRS

    FF_C_OBJ_FILES=
    FF_ASM_OBJ_FILES=
    for MODULE_DIR in $FF_MODULE_DIRS
    do
        C_OBJ_FILES="$MODULE_DIR/*.o"
        if ls $C_OBJ_FILES 1> /dev/null 2>&1; then
            echo "link $MODULE_DIR/*.o"
            FF_C_OBJ_FILES="$FF_C_OBJ_FILES $C_OBJ_FILES"
        fi

        for ASM_SUB_DIR in $FF_ASSEMBLER_SUB_DIRS
        do
            ASM_OBJ_FILES="$MODULE_DIR/$ASM_SUB_DIR/*.o"
            if ls $ASM_OBJ_FILES 1> /dev/null 2>&1; then
                echo "link $MODULE_DIR/$ASM_SUB_DIR/*.o"
                FF_ASM_OBJ_FILES="$FF_ASM_OBJ_FILES $ASM_OBJ_FILES"
            fi
        done
    done

    #set -x
    $NDK_CC -lm -lz -shared --sysroot=$CFLAG_SYSROOT -Wl,--no-undefined -Wl,-z,noexecstack \
        $FF_EXTRA_LDFLAGS \
        -Wl,-soname,libffmpeg.so \
        $FF_C_OBJ_FILES \
        $FF_ASM_OBJ_FILES \
        -Wl,-Bstatic \
        $FF_DEP_LIBS \
        -lx264 -lfdk-aac \
        -Wl,-Bdynamic \
        -o $OUTPUT_PATH/libffmpeg.so

    if [ "$?" = "1" ];then
        exit 1
    fi

}

_cp2ouput(){
    echo "===============_cp2ouput==============="
    set -x
    rm -rf $OUTPUT_FFMPEG/$ARCH
    cp -r $OUTPUT_PATH $OUTPUT_FFMPEG/$ARCH
    set +x
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
#if [ "$FF_TARGET_EXTRA"="link" ]; then
    #_link
#else
    _configure
    sleep 2
    _make
    sleep 2
    _link
    sleep 2  
#fi

_cp2ouput


# --extra-ldflags="$ADDI_LDFLAGS" \
# OPTIMIZE_CFLAGS="-mfloat-abi=softfp -mfpu=vfp -marm -march=armv7-a "


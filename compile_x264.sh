#!/bin/bash

#set -x

ARCH=$1

echo "===================="
echo "[*] X264 $1"
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

OUTPUT_PATH=${SOURCE_X264}/${COM_OUTPUT_FOLD}/${ARCH}


armv5() {
   FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-asm"
   FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=armv5te -mtune=arm9tdmi -msoft-float"
   FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
    
}

armv7a() {
	

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS \
-march=armv7-a \
-mcpu=cortex-a8 \
-mfpu=vfpv3-d16 \
-mfloat-abi=softfp \
-mthumb"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -Wl,--fix-cortex-a8"
    
}

arm64() {

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
}

x86(){
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=atom -msse3 -ffast-math -mfpmath=sse"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
}

x86_64(){

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
}

_common(){
		echo "===============_common()==============="
	FF_CFG_FLAGS="$FF_CFG_FLAGS --prefix=$OUTPUT_PATH"
	FF_CFG_FLAGS="$FF_CFG_FLAGS --cross-prefix=$CFLAG_CROSS_PREFIX"
	FF_CFG_FLAGS="$FF_CFG_FLAGS --sysroot=$CFLAG_SYSROOT"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-static"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-pic"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-strip"
    #FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-thread"
    #FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-asm"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --host=${CROSS_PREFIX}"


    #FF_CFLAGS="$FF_CFLAGS -O3 -Wall -pipe"
    #FF_CFLAGS="$FF_CFLAGS -std=c99"
    #FF_CFLAGS="$FF_CFLAGS -ffast-math"
    #FF_CFLAGS="$FF_CFLAGS -fstrict-aliasing -Werror=strict-aliasing"
    #FF_CFLAGS="$FF_CFLAGS -Wno-psabi -Wa,--noexecstack"
    #FF_CFLAGS="$FF_CFLAGS -DANDROID -DNDEBUG"

   
    #ndk
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -I${CFLAG_SYSROOT}/usr/include"
	# FF_DEP_LIBS="$FF_EXTRA_LDFLAGS -L${CFLAG_SYSROOT}/usr/lib"
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
        --extra-cflags="$FF_CFLAGS $FF_EXTRA_CFLAGS" \
        --extra-ldflags="$FF_DEP_LIBS $FF_EXTRA_LDFLAGS"
    if [ "$?" = "1" ];then
        exit 1
    fi
}

_make(){
	echo "===============_make()==============="
	make clean
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
    mkdir -p ${OUTPUT_PATH}/include/libx264
	cp -f config.h ${OUTPUT_PATH}/include/libx264/config.h
}

_link(){
	echo "===============_link()==============="
	
    echo ""
    echo "--------------------"
    echo "[*] link X264"
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
    $NDK_CC -lm -lz -shared --sysroot=$CFLAG_SYSROOT -Wl,--no-undefined -Wl,-z,noexecstack $FF_EXTRA_LDFLAGS \
        -Wl,-soname,libijkffmpeg.so \
        $FF_C_OBJ_FILES \
        $FF_ASM_OBJ_FILES \
        $FF_DEP_LIBS \
        -o $OUTPUT_PATH/libijkffmpeg.so
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
sleep 2
_configure
sleep 2
#sleep 5
_make
sleep 2
#_link


# --extra-ldflags="$ADDI_LDFLAGS" \
# OPTIMIZE_CFLAGS="-mfloat-abi=softfp -mfpu=vfp -marm -march=armv7-a "


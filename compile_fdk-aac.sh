#!/bin/bash
set -e
#set -x

ARCH=$1

echo "===================="
echo "[*] fdk-aac $1"
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


OUTPUT_PATH=${SOURCE_FDK_AAC}/${COM_OUTPUT_FOLD}/${ARCH}

DEP_SOURCE_ARCH_NAME=
armv5() {
   FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-asm"
   FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=armv5te -mtune=arm9tdmi -msoft-float"
   FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
    DEP_SOURCE_ARCH_NAME=armeabi
}

armv7a() {
	

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS \
-march=armv7-a \
-mcpu=cortex-a8 \
-mfpu=vfpv3-d16 \
-mfloat-abi=softfp \
-mthumb"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -Wl,--fix-cortex-a8"
    DEP_SOURCE_ARCH_NAME=armeabi-v7a
}

arm64() {

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
    DEP_SOURCE_ARCH_NAME=arm64-v8a
}

x86(){
    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=atom -msse3 -ffast-math -mfpmath=sse"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
    DEP_SOURCE_ARCH_NAME=x86
}

x86_64(){

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"
    DEP_SOURCE_ARCH_NAME=x86_64
}

_common(){
		echo "===============_common()==============="
	FF_CFG_FLAGS="$FF_CFG_FLAGS --prefix=$OUTPUT_PATH"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-static"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-shared"
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

    export CXX="$NDK_CXX --sysroot=$CFLAG_SYSROOT"
    export CC="$NDK_CC --sysroot=$CFLAG_SYSROOT"

    
    ARM_INC=${CFLAG_SYSROOT}/usr/include
    ARM_LIB=${CFLAG_SYSROOT}/usr/lib

    echo $CXX
    echo $CC
    echo $FF_CFG_FLAGS
    export LDFLAGS=" -nostdlib -Bdynamic -Wl,--whole-archive -Wl,--no-undefined -Wl,-z,noexecstack  -Wl,-z,nocopyreloc -Wl,-soname,/system/lib/libz.so -Wl,-rpath-link=${ARM_LIB},-dynamic-linker=/system/bin/linker -L${FF_NDK}/sources/cxx-stl/gnu-libstdc++/4.9/libs/${DEP_SOURCE_ARCH_NAME} -L${TOOLCHAIN}/${CROSS_PREFIX}/lib -L${ARM_LIB}  -lc -lgcc -lm -ldl  "
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


	./configure $FF_CFG_FLAGS
        #--extra-cflags="$FF_CFLAGS $FF_EXTRA_CFLAGS" \
        #--extra-ldflags="$FF_DEP_LIBS $FF_EXTRA_LDFLAGS"
    if [ "$?" = "1" ];then
        exit 1
    fi
}

_make(){
	echo "===============_make()==============="
    if [ -d "${OUTPUT_PATH}" ]; then
    	echo "rm ${OUTPUT_PATH}"
    	sleep 2
    	rm -rf ${OUTPUT_PATH}
    fi
	make clean
    make -j4
    if [ "$?" = "1" ];then
        exit 1
    fi
    make install
    #mkdir -p ${OUTPUT_PATH}/include/libfdk-aac
	#cp -f config.h ${OUTPUT_PATH}/include/libfdk-aac/config.h
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


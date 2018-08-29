#!/bin/bash

ARCH=$1
set -x
projectPath=$SOURCE_YUV
appmk=Application.mk
platform=
arch=

_cp2ouput(){
    echo "===============_cp2ouput==============="
    set -x
    rm -rf $OUTPUT_YUV/$ARCH
    cp -r $OUTPUT_PATH $OUTPUT_YUV/$ARCH
    cp -r $SOURCE_YUV/include $OUTPUT_YUV/$ARCH/include
    set +x
}
case "$ARCH" in
    armv5)
        #appmk=Application_armv5.mk
        platform=android-14
        arch=armeabi
    ;;

    armv7a)
        #appmk=Application_armv7a.mk
        platform=android-14
        arch=armeabi-v7a
    ;;

    arm64)
        #appmk=Application_arm64.mk
        platform=android-21
        arch=arm64-v8a
    ;;

    #  x86)
    #    x86
    #;;

    # x86_64)
    #    x86_64
    #;;

    *)
        echo "please enter ARCH"
        exit 1
    ;;
esac
OUTPUT_PATH=$SOURCE_YUV/obj/local/$arch

command="$FF_NDK/ndk-build \
    NDK_PROJECT_PATH=$projectPath \
    NDK_APPLICATION_MK=$appmk \
    APP_PLATFORM=$platform \
    APP_ABI=$arch"
$command clean
$command

if [ "$?" = "1" ];then
    exit 1
fi
_cp2ouput



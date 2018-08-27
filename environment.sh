#!/bin/bash
#set -e
#set -x
UNAME_S=$(uname -s)
UNAME_SM=$(uname -sm)
echo "build on $UNAME_SM"


export FF_NDK="/home/xunxun/devtool/android-ndk-r15c"

if [ -d "$ANDROID_NDK" ]; then
    FF_NDK=$ANDROID_NDK
fi

if [ -z "$FF_NDK" ]; then
    echo "You must define ANDROID_NDK before starting."
    echo "They must point to your NDK directories."
    echo ""
    exit 1
fi

# try to detect NDK version

export TOOLCHAIN_SYSTEM=
export MAKE_TOOLCHAIN_FLAGS=
export MAKE_FLAG=
export NDK_REL=$(grep -o '^r[0-9]*.*' $FF_NDK/RELEASE.TXT 2>/dev/null | sed 's/[[:space:]]*//g' | cut -b2-)
case "$NDK_REL" in
    10e*)
        # we don't use 4.4.3 because it doesn't handle threads correctly.
        if test -d ${FF_NDK}/toolchains/arm-linux-androideabi-4.8
        # if gcc 4.8 is present, it's there for all the archs (x86, mips, arm)
        then
            echo "NDKr$NDK_REL detected"

            case "$UNAME_S" in
                Darwin)
                    export MAKE_TOOLCHAIN_FLAGS="$MAKE_TOOLCHAIN_FLAGS --system=darwin-x86_64"
                ;;
                CYGWIN_NT-*)
                    export MAKE_TOOLCHAIN_FLAGS="$MAKE_TOOLCHAIN_FLAGS --system=windows-x86_64"
                ;;
            esac
        else
            echo "hahaha"
            echo "You need the NDKr10e or later"
            exit 1
        fi
    ;;
    *)
        NDK_REL=$(grep -o '^Pkg\.Revision.*=[0-9]*.*' $FF_NDK/source.properties 2>/dev/null | sed 's/[[:space:]]*//g' | cut -d "=" -f 2)
        echo "NDK_REL=$NDK_REL"
        case "$NDK_REL" in
            11*|12*|13*|14*|15*)
                if test -d ${FF_NDK}/toolchains/arm-linux-androideabi-4.9
                then
                    echo "NDKr$NDK_REL detected"
                else
                    echo "hahaha"
                    echo "You need the NDKr10e or later"
                    exit 1
                fi
            ;;
            *)
                echo "hahaha"
                echo "You need the NDKr10e or later"
                exit 1
            ;;
        esac
    ;;
esac

case "$UNAME_S" in
    Darwin)
        export MAKE_FLAG=-j`sysctl -n machdep.cpu.thread_count`
        TOOLCHAIN_SYSTEM=darwin-x86_64
    ;;
    CYGWIN_NT-*)
        TOOLCHAIN_SYSTEM=windows-x86_64
        IJK_WIN_TEMP="$(cygpath -am /tmp)"
        export TEMPDIR=$IJK_WIN_TEMP/

        echo "Cygwin temp prefix=$IJK_WIN_TEMP/"
    ;;
    Linux)
        TOOLCHAIN_SYSTEM=linux-x86_64
    ;;
esac



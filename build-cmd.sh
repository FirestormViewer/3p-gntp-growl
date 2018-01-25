#!/bin/bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

GNTP_SEND_SOURCE_DIR="gntp-send"

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# load autobuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

stage="$(pwd)/stage"
echo "1.0" > "${stage}/VERSION.txt"

pushd "${GNTP_SEND_SOURCE_DIR}"
    case "${AUTOBUILD_PLATFORM}" in
        windows*)
            load_vsvars

            if [ "${AUTOBUILD_WIN_VSPLATFORM}" = "Win32" ] ; then
              cmake . -G "Visual Studio 12"
            else
              cmake . -G "Visual Studio 12 Win64"
            fi

            build_sln Project.sln "RelWithDebInfo|$AUTOBUILD_WIN_VSPLATFORM" growl
            build_sln Project.sln "RelWithDebInfo|$AUTOBUILD_WIN_VSPLATFORM" growl++

            mkdir -p "${stage}/lib/debug"
            mkdir -p "${stage}/lib/release"

            cp RelWithDebInfo/*.dll "${stage}/lib/debug"
            cp RelWithDebInfo/*.lib "${stage}/lib/debug"
#           cp RelWithDebInfo/*.pdb "${stage}/lib/debug"
            cp RelWithDebInfo/*.dll "${stage}/lib/release"
            cp RelWithDebInfo/*.lib "${stage}/lib/release"
#           cp RelWithDebInfo/*.pdb "${stage}/lib/release"
        ;;

        darwin*)
            libdir="${stage}/lib"
            mkdir -p "$libdir"/{debug,release}
            MACOSX_DEPLOYMENT_TARGET=10.7 cmake .
            MACOSX_DEPLOYMENT_TARGET=10.7 make

            cp *.dylib "${libdir}/debug"
            cp *.dylib "${libdir}/release"

            # Ugly, but get rid of static paths
            install_name_tool -id @executable_path/../Resources/libgrowl.dylib \
                "${stage}/lib/debug/libgrowl.dylib"
            install_name_tool -id @executable_path/../Resources/libgrowl.dylib \
                "${stage}/lib/release/libgrowl.dylib"
            install_name_tool -id @executable_path/../Resources/libgrowl++.dylib \
                "${stage}/lib/debug/libgrowl++.dylib"
            install_name_tool -id @executable_path/../Resources/libgrowl++.dylib \
                "${stage}/lib/release/libgrowl++.dylib"
            install_name_tool -change $(pwd)/libgrowl.dylib \
                @executable_path/../Resources/libgrowl.dylib \
                "${stage}/lib/debug/libgrowl++.dylib"
            install_name_tool -change $(pwd)/libgrowl.dylib \
                @executable_path/../Resources/libgrowl.dylib \
                "${stage}/lib/release/libgrowl++.dylib"
        ;;

        linux*)
        ;;
    esac

    mkdir -p "${stage}/include/Growl"
    cp headers/{growl++.hpp,growl.h} "${stage}/include/Growl"
    mkdir -p "$stage/LICENSES"
    cp LICENSE "$stage/LICENSES/gntp-growl.txt"
popd


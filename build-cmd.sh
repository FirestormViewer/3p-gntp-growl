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
pushd "${GNTP_SEND_SOURCE_DIR}"
    case "$AUTOBUILD_PLATFORM" in
        "windows")
            load_vsvars

            if [ "${AUTOBUILD_ARCH}" == "x64" ]
            then
				cmake . -G "Visual Studio 10 Win64"

				build_sln Project.sln "RelWithDebInfo|x64" growl
				build_sln Project.sln "RelWithDebInfo|x64" growl++
			else
				cmake . -G "Visual Studio 10"

				build_sln Project.sln "RelWithDebInfo|Win32" growl
				build_sln Project.sln "RelWithDebInfo|Win32" growl++
			fi

			mkdir -p "${stage}/lib/debug"
			mkdir -p "${stage}/lib/release"
			mkdir -p "${stage}/include/Growl"

			cp RelWithDebInfo/*.dll "${stage}/lib/debug"
			cp RelWithDebInfo/*.lib "${stage}/lib/debug"
			cp RelWithDebInfo/*.pdb "${stage}/lib/debug"
			cp RelWithDebInfo/*.dll "${stage}/lib/release"
			cp RelWithDebInfo/*.lib "${stage}/lib/release"
			cp RelWithDebInfo/*.pdb "${stage}/lib/release"
            cp headers/{growl++.hpp,growl.h} "${stage}/include/Growl"
        ;;
        "darwin")
        ;;            
			
        "linux")
        ;;
    esac
    mkdir -p "$stage/LICENSES"
    cp LICENSE "$stage/LICENSES/gntp-growl.txt"
popd

pass


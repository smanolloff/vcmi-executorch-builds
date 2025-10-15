#!/bin/sh

#
# Warning for win-* targets:
#
# Windows builds on GHA are successful, but they are still unusable as they
# cause memory corruption at runtime and should NOT be used.
# (possibly caused by different size of C `long` type on windows)
# Future versions of executorch might eventually fix this.
#

set -eux

[ -d "$ARTIFACT_ROOT" ] || { echo "ARTIFACT_ROOT does not exist: $ARTIFACT_ROOT"; exit 1; }
[ -d "$ARTIFACT_ROOT/executorch" ] && { echo "$ARTIFACT_ROOT/executorch already exists"; exit 1; } || :

TARGET=$1

cd executorch

case "$TARGET" in
win-*)
    . .venv/Scripts/activate
    args=(
        -DCMAKE_PREFIX_PATH="$VIRTUAL_ENV/Lib/site-packages"
        -DPYTHON_EXECUTABLE="$VIRTUAL_ENV/Scripts/python.exe"
    )
    ;;
android-*)
    . .venv/bin/activate
    # sudo apt-get update && sudo apt-get install -y shaderc
    brew install shaderc spirv-tools
    # Verify
    glslc --version
    args=(
        # -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake"
        # -DCMAKE_MAKE_PROGRAM="$(which make)"
    )
    ;;
*)
    . .venv/bin/activate ;;
esac

cp ../CMakeUserPresets.json ./
cp ../install_headers.cmake ./

preset="vcmi-$TARGET"

cmake --preset "$preset" "${args[@]-}"
cmake --build --preset "$preset" -j3
cmake --preset "$preset" -P install_headers.cmake

mv out/executorch "$ARTIFACT_ROOT/executorch"

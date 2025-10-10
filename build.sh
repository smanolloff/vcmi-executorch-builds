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
    . .venv/Scripts/activate ;;
*)
    . .venv/bin/activate ;;
esac

case "$TARGET" in
win-arm64)
    export PYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
    git -c core.autocrlf=false apply ../patch/windows.patch
    git -c core.autocrlf=false apply --whitespace=nowarn ../patch/windows-arm64.patch
    ;;
win-x64)
    export PYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
    git -c core.autocrlf=false apply ../patch/windows.patch
    ;;
win-x86)
    export PYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
    git -c core.autocrlf=false apply ../patch/windows.patch
    git -c core.autocrlf=false apply --whitespace=nowarn ../patch/windows-x86.patch
    ;;
android-armv7)
    # https://github.com/pytorch/executorch/pull/12146
    git -c core.autocrlf=false apply ../patch/android-armv7.patch
    ;;
esac

cp ../CMakeUserPresets.json ./
cp ../install_headers.cmake ./

git -c core.autocrlf=false apply ../patch/xnndebug.patch

cmake --preset "$TARGET"
cmake --build --preset "$TARGET" -j3
cmake --preset "$TARGET" -P install_headers.cmake

mv out/executorch "$ARTIFACT_ROOT/executorch"

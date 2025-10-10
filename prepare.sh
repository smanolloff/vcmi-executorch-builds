#!/bin/sh

set -euxo pipefail

TARGET=$1

cd executorch

patch_dir=../patch/executorch-$EXECUTORCH_REF

case "$TARGET" in
win-arm64)
    git -c core.autocrlf=false apply $patch_dir/windows.patch
    git -c core.autocrlf=false apply --whitespace=nowarn $patch_dir/windows-arm64.patch
    ;;
win-x64)
    git -c core.autocrlf=false apply $patch_dir/windows.patch
    ;;
win-x86)
    git -c core.autocrlf=false apply $patch_dir/windows.patch
    git -c core.autocrlf=false apply --whitespace=nowarn $patch_dir/windows-x86.patch
    ;;
android-armv7)
    # https://github.com/pytorch/executorch/pull/12146
    git -c core.autocrlf=false apply $patch_dir/android-armv7.patch
    ;;
esac

python -m venv .venv

case "$TARGET" in
win-arm64)
    . .venv/Scripts/activate
    pip install setuptools_rust
    export PYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
    ;;
win-x64)
    . .venv/Scripts/activate
    export PYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
    ;;
win-x86)
    . .venv/Scripts/activate
    export PYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
    ;;
*)
    . .venv/bin/activate
    ;;
esac

./install_requirements.sh

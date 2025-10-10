#!/bin/sh

set -euxo pipefail

TARGET=$1
patch_dir="$PWD/patch/executorch-$EXECUTORCH_REF"

cd executorch
python -m venv .venv

git -c core.autocrlf=false apply "$patch_dir/xnndebug.patch"

case "$TARGET" in
win-arm64)
    . .venv/Scripts/activate
    pip install setuptools_rust
    export PYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
    git -c core.autocrlf=false apply "$patch_dir/windows.patch"
    git -c core.autocrlf=false apply --whitespace=nowarn "$patch_dir/windows-arm64.patch"
    ;;
win-x64)
    . .venv/Scripts/activate
    export PYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
    git -c core.autocrlf=false apply "$patch_dir/windows.patch"
    ;;
win-x86)
    . .venv/Scripts/activate
    export PYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
    git -c core.autocrlf=false apply "$patch_dir/windows.patch"
    git -c core.autocrlf=false apply --whitespace=nowarn "$patch_dir/windows-x86.patch"
    ;;
android-armv7)
    . .venv/bin/activate
    # https://github.com/pytorch/executorch/pull/12146
    git -c core.autocrlf=false apply "$patch_dir/android-armv7.patch"
    ;;
*)
    . .venv/bin/activate
    ;;
esac

./install_requirements.sh

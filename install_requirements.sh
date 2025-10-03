#!/bin/sh

set -eux

# windows-2025 -> windows; macos-14 -> macos; ... etc
TARGET=$1

cd executorch
python -m venv .venv

case "$TARGET" in
win-arm64)
    . .venv/Scripts/activate
    pip install setuptools_rust
    export PYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
    git -c core.autocrlf=false apply --whitespace=nowarn ../../executorch/patch/windows-arm64.patch
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

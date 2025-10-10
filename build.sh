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

cp ../CMakeUserPresets.json ./
cp ../install_headers.cmake ./

cmake --preset "$TARGET"
cmake --build --preset "$TARGET" -j3
cmake --preset "$TARGET" -P install_headers.cmake

mv out/executorch "$ARTIFACT_ROOT/executorch"

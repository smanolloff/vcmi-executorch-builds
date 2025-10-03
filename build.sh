#!/bin/sh

set -eux

# windows-2025 -> windows; macos-14 -> macos; ... etc
TARGET=$1
BUILD_TYPE=${2:-Release}

cd executorch

case "$TARGET" in
win-*)
    . .venv/Scripts/activate ;;
*)
    . .venv/bin/activate ;;
esac

flags=("-DCMAKE_BUILD_TYPE=$BUILD_TYPE")

case "$TARGET" in
win-x64)
    export PYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
    git -c core.autocrlf=false apply ../patch/windows.patch
    flags+=(
        -G 'Visual Studio 17 2022'
        -T ClangCL
        -A x64
        -DPYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
        -DCMAKE_PREFIX_PATH=$VIRTUAL_ENV/Lib/site-packages

        # Fixes error : no such file or directory: '/vlen=256'
        # See comment in backends/xnnpack/third-party/XNNPACK/CMakeLists.txt:
        # regarding "/vlen option not supported"
        -DXNNPACK_ENABLE_AVX256SKX=OFF
        -DXNNPACK_ENABLE_AVX256VNNI=OFF
        -DXNNPACK_ENABLE_AVX256VNNIGFNI=OFF
        -DXNNPACK_ENABLE_AVX512BF16=OFF
        # -DXNNPACK_ENABLE_AVX512F=OFF
        # -DXNNPACK_ENABLE_AVX512SKX=OFF
        # -DXNNPACK_ENABLE_AVX512VBMI=OFF
        # -DXNNPACK_ENABLE_AVX512VNNI=OFF
        # -DXNNPACK_ENABLE_AVX512VNNIGFNI=OFF
        # -DXNNPACK_ENABLE_AVX512AMX=OFF
        # -DXNNPACK_ENABLE_AVX512FP16=OFF
    )
    ;;
win-x86)
    export PYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
    git -c core.autocrlf=false apply ../patch/windows.patch
    git -c core.autocrlf=false apply --whitespace=nowarn ../patch/windows-x86.patch
    flags+=(
        -G 'Visual Studio 17 2022'
        -T ClangCL
        -A Win32
        -DPYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
        -DCMAKE_PREFIX_PATH=$VIRTUAL_ENV/Lib/site-packages
        -DXNNPACK_ENABLE_AVX256SKX=OFF
        -DXNNPACK_ENABLE_AVX256VNNI=OFF
        -DXNNPACK_ENABLE_AVX256VNNIGFNI=OFF
        -DXNNPACK_ENABLE_AVX512BF16=OFF
    )
    ;;
win-arm64)
    export PYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
    git -c core.autocrlf=false apply ../patch/windows.patch
    flags+=(
        -G 'Visual Studio 17 2022'
        -T ClangCL
        -A ARM64
        -DPYTHON_EXECUTABLE=$VIRTUAL_ENV/Scripts/python.exe
        -DCMAKE_PREFIX_PATH=$VIRTUAL_ENV/Lib/site-packages
        -DCMAKE_C_FLAGS="/clang:-march=armv8.2-a+fp16+dotprod+i8mm+bf16"
        -DCMAKE_CXX_FLAGS="/EHsc /clang:-march=armv8.2-a+fp16+dotprod+i8mm+bf16"
        -DEXECUTORCH_BUILD_KERNELS_OPTIMIZED=OFF
        -DEXECUTORCH_BUILD_KERNELS_QUANTIZED=OFF
        -DXNNPACK_ENABLE_ASSEMBLY=OFF
    )
    ;;
linux-x64)
    # no special flags
    ;;
macos-x64)
    flags+=(
        -DCMAKE_OSX_ARCHITECTURES=x86_64
        -DCMAKE_OSX_DEPLOYMENT_TARGET=10.13     # os.version in VCMI macos-intel conan profile
    )
    ;;
macos-arm64)
    flags+=(
        -DCMAKE_OSX_ARCHITECTURES=arm64
        -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0     # os.version in VCMI macos-arm conan profile
    )
    ;;
ios-arm64)
    flags+=(
      -DCMAKE_SYSTEM_NAME=iOS
      -DCMAKE_OSX_SYSROOT=iphoneos
      -DCMAKE_OSX_ARCHITECTURES=arm64
      -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0    # as per VCMI's root CMakeLists
    )
    ;;
android-arm64)
    flags+=(
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake
        -DANDROID_ABI=arm64-v8a
        -DANDROID_PLATFORM=21     # os.api_level in VCMI android-64 conan profile
    )
    ;;
android-armv7)
    # https://github.com/pytorch/executorch/pull/12146
    git -c core.autocrlf=false apply ../patch/android-armv7.patch
    flags+=(
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake
        -DANDROID_ABI=armeabi-v7a
        -DANDROID_ARM_NEON=ON
        -DANDROID_PLATFORM=19
    )
    ;;
android-x64)
    flags+=(
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake
        -DANDROID_ABI=x86_64
        -DANDROID_PLATFORM=21     # os.api_level in VCMI android-x64 conan profile
    )
    ;;
*)
    echo "Unknown TARGET: $TARGET"
    exit 1
    ;;
esac

cp ../CMakeUserPresets.json ./
cp ../install_headers.cmake ./

git -c core.autocrlf=false apply ../patch/xnndebug.patch

cmake --preset mmai-executorch-release "${flags[@]}"
cmake --build --preset mmai-executorch-release --config $BUILD_TYPE -j3
cmake --preset mmai-executorch-release -P install_headers.cmake

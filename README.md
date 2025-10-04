# ExecuTorch builds for VCMI

This repository contains CI builds for producing executorch libraries for VCMI's ML-powered "MMAI".

As of Oct 2025, ExecuTorch (v0.7) performs slower than libtorch on edge devices, at least with the current build configuration.

It also causes memory corruption on Windows so it's unusable there.

However, it does look a promising and may one day become a viable alternative to libtorch for MMAI.


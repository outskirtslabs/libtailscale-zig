# libtailscale-zig

This is [libtailscale][libtailscale], packaged for Zig with cross-compilation support for Linux and macOS.

libtailscale is a C library that allows embedding [Tailscale][tailscale] connectivity into applications. This wrapper uses Zig's cross-compilation toolchain to build shared libraries for multiple platforms from a single host.

- Fetches upstream libtailscale source automatically via zig's package manager
- Uses zig cc as the C compiler for Go's cgo, enabling cross-compilation
- Outputs shared libraries (`.so` / `.dylib`) with corresponding C headers

Supported targets:

- `x86_64-linux` (libtailscale_linux_amd64.so)
- `aarch64-linux` (libtailscale_linux_arm64.so)
- `aarch64-macos` (libtailscale_darwin_arm64.dylib)

## Quick start

1. Install [zig][zig] and [go][go]
2. `zig build`

Output will be in `zig-out/`.

## Prerequisites

You need the following installed:

- [Zig][zig] 0.15.2
- [Go][go] 1.21+

If you have nix you can use the dev shell provided by the flake in this repo:

```bash
nix develop
zig build
```

## Build Commands

```bash
# Build all targets
zig build

# Build specific target
zig build libtailscale_linux_amd64.so
zig build libtailscale_linux_arm64.so
zig build libtailscale_darwin_arm64.dylib
```

## Cross-Compilation to macOS

When cross-compiling from Linux to macOS, the build requires the `APPLE_SDK_PATH` environment variable to be set. This points to the macOS SDK that provides system headers and libraries.

Using Nix (Recommended):

The provided nix flake automatically sets up `APPLE_SDK_PATH` when you enter the development shell:

```bash
nix develop
zig build
```

Manual Setup:

If not using nix, you'll need to obtain a macOS SDK and set the environment variable:

```bash
export APPLE_SDK_PATH=/path/to/MacOSX.sdk
zig build libtailscale_darwin_arm64.dylib
```

The SDK must contain `usr/include` with macOS system headers and `System/Library/Frameworks` with CoreFoundation, Security, and IOKit frameworks.

## License

Copyright 2026 Casey Link

This zig build wrapper is distributed under the [BSD-3-Clause][bsd3] license.

libtailscale is distributed under the [BSD-3-Clause][bsd3] license by Tailscale Inc.

[libtailscale]: https://github.com/tailscale/libtailscale
[tailscale]: https://tailscale.com/
[zig]: https://ziglang.org/
[go]: https://go.dev/
[bsd3]: https://spdx.org/licenses/BSD-3-Clause.html

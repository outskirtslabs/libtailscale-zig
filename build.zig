const std = @import("std");

const Target = struct {
    goos: []const u8,
    goarch: []const u8,
    zig_target: []const u8,
    output: []const u8,
    needs_darwin_sdk: bool = false,
};

const targets = [_]Target{
    .{ .goos = "linux", .goarch = "amd64", .zig_target = "x86_64-linux-gnu", .output = "libtailscale_linux_amd64.so" },
    .{ .goos = "linux", .goarch = "arm64", .zig_target = "aarch64-linux-gnu", .output = "libtailscale_linux_arm64.so" },
    .{ .goos = "darwin", .goarch = "arm64", .zig_target = "aarch64-macos", .output = "libtailscale_darwin_arm64.dylib", .needs_darwin_sdk = true },
};

pub fn build(b: *std.Build) void {
    const apple_sdk_path = b.option([]const u8, "apple-sdk", "Path to macOS SDK") orelse
        std.posix.getenv("APPLE_SDK_PATH") orelse
        null;

    const libtailscale_dep = b.dependency("libtailscale", .{});
    const libtailscale_path = libtailscale_dep.path(".").getPath(b);

    // Create a step for building all targets
    const all_step = b.step("all", "Build all shared libraries");

    for (targets) |target| {
        const step = b.step(target.output, b.fmt("Build {s}", .{target.output}));

        // Build CC string with zig cc and target
        const cc_string = if (target.needs_darwin_sdk)
            if (apple_sdk_path) |sdk|
                b.fmt("zig cc -target {s} -isystem {s}/usr/include -F{s}/System/Library/Frameworks -iframework {s}/System/Library/Frameworks -L{s}/usr/lib", .{ target.zig_target, sdk, sdk, sdk, sdk })
            else blk: {
                std.log.warn("Darwin target requires APPLE_SDK_PATH or -Dapple-sdk=<path>", .{});
                break :blk b.fmt("zig cc -target {s}", .{target.zig_target});
            }
        else
            b.fmt("zig cc -target {s}", .{target.zig_target});

        const go_build = b.addSystemCommand(&.{
            "go", "build", "-v", "-buildmode=c-shared", "-o",
        });
        go_build.addArg(b.fmt("{s}/{s}", .{ b.install_path, target.output }));
        go_build.setCwd(.{ .cwd_relative = libtailscale_path });
        go_build.setEnvironmentVariable("CGO_ENABLED", "1");
        go_build.setEnvironmentVariable("GOOS", target.goos);
        go_build.setEnvironmentVariable("GOARCH", target.goarch);
        go_build.setEnvironmentVariable("CC", cc_string);
        // Use absolute path for zig cache since go runs from dependency dir
        const zig_cache_abs = b.build_root.join(b.allocator, &.{".zig-cache"}) catch @panic("OOM");
        go_build.setEnvironmentVariable("ZIG_GLOBAL_CACHE_DIR", zig_cache_abs);

        step.dependOn(&go_build.step);
        all_step.dependOn(&go_build.step);
    }

    // Build echo_server example for native target
    const example_step = b.step("example", "Build echo_server example (native)");

    // Determine which .so/.dylib to use based on host
    const builtin = @import("builtin");
    const native_lib = if (builtin.os.tag == .macos)
        "libtailscale_darwin_arm64.dylib"
    else if (builtin.cpu.arch == .aarch64)
        "libtailscale_linux_arm64.so"
    else
        "libtailscale_linux_amd64.so";

    const exe_module = b.createModule(.{
        .target = b.graph.host,
        .optimize = .Debug,
    });

    const echo_server = b.addExecutable(.{
        .name = "echo_server",
        .root_module = exe_module,
    });
    echo_server.addCSourceFile(.{
        .file = libtailscale_dep.path("example/echo_server.c"),
    });
    echo_server.addIncludePath(libtailscale_dep.path("."));
    echo_server.addLibraryPath(.{ .cwd_relative = b.install_path });
    echo_server.root_module.linkSystemLibrary("tailscale_linux_amd64", .{});
    echo_server.linkLibC();

    // Depend on the shared library build (find existing step)
    for (b.top_level_steps.values()) |step_info| {
        if (std.mem.eql(u8, step_info.step.name, native_lib)) {
            echo_server.step.dependOn(&step_info.step);
            break;
        }
    }

    const install_example = b.addInstallArtifact(echo_server, .{});
    example_step.dependOn(&install_example.step);

    b.default_step = all_step;
}

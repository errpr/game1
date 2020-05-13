const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("game1", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    const winblows = true;

    if (winblows) {
        exe.addVcpkgPaths(.Dynamic) catch |err| std.debug.warn("failed to add vcpkg path: {}\n", .{err});
        exe.linkSystemLibrary("gdi32");
    } else {
        std.debug.warn("linsux / macos not implemented", .{});
    }
    
    exe.linkSystemLibrary("c");
    exe.addIncludeDir("include");
    exe.addCSourceFile("src/glad.c", &[_][]const u8{"-std=c99"});
    exe.linkSystemLibrary("sdl2");
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mod = b.addModule("pcm", .{
        .root_source_file = b.path("src/pcm.zig"),
        .target = target,
        .optimize = optimize,
    });

    var out_code: u8 = undefined;
    const configured_hooks_path = std.mem.trim(u8, b.runAllowFail(&[_][]const u8{
        "git",
        "config",
        "get",
        "--global",
        "core.hookspath",
    }, &out_code, .ignore) catch "", " \n\r");

    var hooks_path: []const u8 = undefined;
    if (configured_hooks_path.len > 0 and createHooksDirectory(b.graph.io, configured_hooks_path)) {
        hooks_path = configured_hooks_path;
    } else {
        hooks_path = buildHooksPath(b);
        _ = createHooksDirectory(b.graph.io, hooks_path);
        _ = b.runAllowFail(&[_][]const u8{
            "git",
            "config",
            "set",
            "--global",
            "core.hookspath",
            hooks_path,
        }, &out_code, .ignore) catch "";
    }

    const exe = b.addExecutable(.{
        .name = "prepare-commit-msg",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "pcm",
                    .module = mod,
                },
            },
        }),
    });

    if (optimize == .ReleaseFast) {
        mod.strip = true;
        exe.root_module.strip = true;
        b.install_path = hooks_path;
        const install_exe = b.addInstallArtifact(exe, .{
            .dest_dir = .{ .override = .prefix },
        });
        b.getInstallStep().dependOn(&install_exe.step);
    } else {
        b.installArtifact(exe);
    }

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);

    const clean_up = b.addSystemCommand(&.{ "rm", "-rf", "zig-out" });
    const clean_step = b.step("clean", "Clean up");
    clean_step.dependOn(&clean_up.step);
}

fn createHooksDirectory(io: std.Io, hooks_path: []const u8) bool {
    std.Io.Dir.createDir(.cwd(), io, hooks_path, .default_dir) catch |err| switch (err) {
        error.PathAlreadyExists => return true,
        else => {
            std.debug.print("Could not create directory: {s}: {}\n", .{ hooks_path, err });
            return false;
        },
    };
    return true;
}

fn buildHooksPath(b: *std.Build) []const u8 {
    const home = b.graph.environ_map.get("HOME") orelse
        std.debug.panic("Could not find home directory\n", .{});
    const hooks_path = std.fs.path.join(b.allocator, &[_][]const u8{
        home,
        ".git_hooks",
    }) catch |err| {
        std.debug.panic("Could not build hooks path: {}\n", .{err});
    };
    return hooks_path;
}

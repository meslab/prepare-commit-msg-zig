const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mod = b.addModule("pcm", .{
        .root_source_file = b.path("src/pcm.zig"),
        .target = target,
        .optimize = optimize,
        .strip = true,
    });

    var git_hooks_path: u8 = undefined;
    var hooks_path: []const u8 = undefined;
    const git_res = std.mem.trim(u8, b.runAllowFail(&[_][]const u8{ "git", "config", "get", "--global", "core.hookspath" }, &git_hooks_path, .Ignore) catch "", " \n\r");
    if (git_res.len > 0) {
        hooks_path = git_res;
        // std.debug.print("Inside if: {s}\n", .{hooks_path});
        createHooksDirectory(hooks_path);
    } else {
        hooks_path = buildHooksPath(b.allocator);
        // std.debug.print("Inside else: {s}\n", .{hooks_path});
        createHooksDirectory(hooks_path);
        _ = b.runAllowFail(&[_][]const u8{ "git", "config", "set", "--global", "core.hookspath", hooks_path }, &git_hooks_path, .Ignore) catch "";
    }

    const exe = b.addExecutable(.{
        .name = "prepare-commit-msg",
        .root_module = b.createModule(.{ .root_source_file = b.path("src/main.zig"), .target = target, .optimize = optimize, .strip = true, .imports = &.{
            .{ .name = "pcm", .module = mod },
        } }),
    });

    if (optimize == .ReleaseFast) {
        b.install_path = hooks_path;
        const install_exe = b.addInstallArtifact(exe, .{
            .dest_dir = .{ .override = .prefix },
        });

        b.getInstallStep().dependOn(&install_exe.step);

        const rm = b.addSystemCommand(&.{"rm"});
        rm.addArg(b.pathJoin(&.{ hooks_path, exe.name }));
        b.getUninstallStep().dependOn(&rm.step);
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
}

fn createHooksDirectory(hooks_path: []const u8) void {
    std.fs.cwd().makeDir(hooks_path) catch |err| switch (err) {
        error.PathAlreadyExists => return,
        else => {
            std.debug.print("Could not create directory: {}\n", .{err});
        },
    };
}

fn buildHooksPath(allocator: std.mem.Allocator) []const u8 {
    const home = std.process.getEnvVarOwned(allocator, "HOME") catch unreachable;
    const hooks_path = std.fs.path.join(allocator, &[_][]const u8{ home, ".git_hooks" }) catch unreachable;
    return hooks_path;
}

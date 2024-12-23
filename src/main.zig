const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const process = std.process;
const pcm = @import("root.zig");

/// Main entry point of the application.
/// This function reads a commit message file and prepends the current Git branch name
/// to the message, unless the branch is a default branch or its name cannot be determined.
/// On multi-line commits empty lines are removed and each line is bulleted
///
/// # Errors
/// - Returns an error if the branch name cannot be fetched or the commit message cannot be updated.
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <commit_msg_file>\n", .{args[0]});
        process.exit(1);
    }

    const commit_msg_file_path = args[1];

    const branch_name = (try pcm.getCurrentGitBranch(allocator, .{})) orelse {
        std.debug.print("Cannot find branch name.\n", .{});
        return;
    };

    if (mem.eql(u8, branch_name, "") or isDefaultBranch(branch_name)) {
        std.debug.print("On default branch. Skipping commit message update.\n", .{});
        return;
    }

    try pcm.updateCommitMessage(allocator, commit_msg_file_path, branch_name);
    std.debug.print("Commit message updated with branch name `{s}`.\n", .{branch_name});
}

fn isDefaultBranch(branch_name: []const u8) bool {
    const default_branch_names = comptime [_][]const u8{ "main", "master" };
    for (default_branch_names) |default_branch| {
        if (mem.eql(u8, branch_name, default_branch)) return true;
    }
    return false;
}

const std = @import("std");
const mem = std.mem;
const pcm = @import("pcm.zig");
const expect = std.testing.expect;

/// Main entry point of the application.
/// This function reads a commit message file and prepends the current Git branch name
/// to the message, unless the branch is a default branch or its name cannot be determined.
/// On multi-line commits empty lines are removed and each line is bulleted
///
/// # Errors
/// - Returns an error if the branch name cannot be fetched or the commit message cannot be updated.
pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();

    const args = try std.process.Args.toSlice(init.minimal.args, allocator);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <commit_msg_file>\n", .{args[0]});
        std.process.exit(1);
    }

    const commit_msg_file_path = args[1];

    const branch_name = (try pcm.getCurrentGitBranch(init.io, allocator, .{})) orelse {
        std.debug.print("Cannot find branch name.\n", .{});
        return;
    };

    if (mem.eql(u8, branch_name, "") or pcm.isDefaultBranch(branch_name)) {
        std.debug.print("On default branch. Skipping commit message update.\n", .{});
        return;
    }

    try pcm.updateCommitMessage(init.io, allocator, commit_msg_file_path, branch_name);
    std.debug.print("Commit message updated with branch name `{s}`.\n", .{branch_name});
}

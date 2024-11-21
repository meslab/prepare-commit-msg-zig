const std = @import("std");
const process = std.process;
const fs = std.fs;
const mem = std.mem;
const pcm = @import("root.zig");

const BRANCH_NAMES = [_][]const u8{ "main", "master" };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Get command line arguments
    const args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <commit_msg_file>\n", .{args[0]});
        process.exit(1);
    }

    const commit_msg_file_path = args[1];

    // Get branch name
    const branch_name = (try pcm.getCurrentGitBranch(allocator)) orelse {
        std.debug.print("No branch name found. Skipping commit message update.\n", .{});
        return;
    };

    // Check if on default branch
    if (mem.eql(u8, branch_name, "") or
        for (BRANCH_NAMES) |default_branch|
    {
        if (mem.eql(u8, branch_name, default_branch)) break true;
    } else false) {
        std.debug.print("On default branch. Skipping commit message update.\n", .{});
        return;
    }

    // Update commit message
    try pcm.updateCommitMessage(allocator, commit_msg_file_path, branch_name);
    std.debug.print("Commit message updated with branch name.\n", .{});
}

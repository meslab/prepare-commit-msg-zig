const std = @import("std");
const pcm = @import("root.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // Create a general-purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Get the current branch
    if (try pcm.getCurrentGitBranch(allocator)) |branch| {
        defer allocator.free(branch);
        try stdout.print("Current branch: {s}\n", .{branch});
    } else {
        try stdout.writeAll("Could not determine current branch\n");
    }
}

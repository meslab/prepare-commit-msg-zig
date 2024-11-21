const std = @import("std");
const testing = std.testing;

/// Retrieves the current Git branch name from the current directory
/// Caller is responsible for freeing the returned memory
pub fn getCurrentGitBranch(allocator: std.mem.Allocator) !?[]const u8 {
    const head_path = try std.fs.cwd().realpathAlloc(allocator, ".git/HEAD");
    defer allocator.free(head_path);

    const head_file = try std.fs.openFileAbsolute(head_path, .{});
    defer head_file.close();

    var buffer: [1024]u8 = undefined;
    const bytes_read = try head_file.readAll(&buffer);

    if (bytes_read > 16 and std.mem.startsWith(u8, buffer[0..bytes_read], "ref: refs/heads/")) {
        const content = buffer[0..bytes_read];

        if (std.mem.lastIndexOf(u8, content, "/")) |last_slash_index| {
            const branch_name = std.mem.trim(u8, content[last_slash_index + 1 ..], " \n\r");
            return try allocator.dupe(u8, branch_name);
        }
    }

    return null;
}

/// Updates commit message file
/// Caller is responsible for freeing the returned memory
pub fn updateCommitMessage(allocator: std.mem.Allocator, file_path: []const u8, branch_name: []const u8) !void {
    const file_contents = try std.fs.cwd().readFileAlloc(allocator, file_path, 1024 * 1024);
    defer allocator.free(file_contents);

    const new_message = try std.fmt.allocPrint(allocator, "{s}: {s}", .{branch_name, file_contents});
    defer allocator.free(new_message);

    try std.fs.cwd().writeFile(.{
        .sub_path = file_path,
        .data = new_message,
    });
}
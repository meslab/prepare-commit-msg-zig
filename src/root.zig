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
    // Read the original commit message
    const file_content = try std.fs.cwd().readFileAlloc(allocator, file_path, 1024 * 1024);
    defer allocator.free(file_content);

    const trimmed_file_content = std.mem.trim(u8, file_content, " \t\n\r-");

    var branch_name_buffer: [256]u8 = undefined;
    const formatted_branch_name = try std.fmt.bufPrint(&branch_name_buffer, "{s}:", .{branch_name});

    // Check if the message is multiline
    const line_count = std.mem.count(u8, trimmed_file_content, "\n");

    if (line_count > 0) {
        // Prepare the new message for multiline
        var message = std.ArrayList(u8).init(allocator);
        defer message.deinit();

        var buffer: [256]u8 = undefined;

        // Add the branch name as the first line
        try message.writer().writeAll(formatted_branch_name);

        // Prepend each original line with `- `
        var lines = std.mem.split(u8, trimmed_file_content, "\n");
        while (lines.next()) |line| {
            const formatted = try std.fmt.bufPrint(&buffer, "\n- {s}", .{line});
            try message.writer().writeAll(formatted);
        }

        // Write the new message to the file
        try std.fs.cwd().writeFile(.{
            .sub_path = file_path,
            .data = message.items,
        });
    } else {
        // Single-line message, format as `branch_name: original_message`
        const message = try std.fmt.allocPrint(allocator, "{s} {s}", .{ formatted_branch_name, trimmed_file_content });
        defer allocator.free(message);

        try std.fs.cwd().writeFile(.{
            .sub_path = file_path,
            .data = message,
        });
    }
}

test "updateCommitMessage updates the commit message with the branch name multiline" {
    const allocator = testing.allocator;

    const test_dir_rel_path = "test_update_commit_message";
    const commit_msg_file_name = "COMMIT_MSG";
    const commit_msg_file_path = test_dir_rel_path ++ "/" ++ commit_msg_file_name;

    const initial_msg =
        \\Initial commit
        \\Muti-line commit
    ;
    const trimmed_initial_msg =
        \\- Initial commit
        \\- Muti-line commit
    ;

    const feature_branch = "feature-branch";

    try std.fs.cwd().makeDir(test_dir_rel_path);
    var test_dir = try std.fs.cwd().openDir(
        test_dir_rel_path,
        .{},
    );
    defer {
        test_dir.close();
        std.fs.cwd().deleteTree(test_dir_rel_path) catch unreachable;
    }

    const commit_msg_file = try test_dir.createFile(commit_msg_file_name, .{});
    defer commit_msg_file.close();

    const len = try commit_msg_file.write(initial_msg);
    try testing.expectEqual(len, initial_msg.len);

    try updateCommitMessage(allocator, commit_msg_file_path, feature_branch);

    const updated_msg = try std.fs.cwd().readFileAlloc(allocator, commit_msg_file_path, 1024 * 1024);
    defer allocator.free(updated_msg);

    try testing.expectEqualStrings(feature_branch ++ ":\n" ++ trimmed_initial_msg, updated_msg);
}

test "updateCommitMessage updates the commit message with the branch name" {
    const allocator = testing.allocator;

    const test_dir_rel_path = "test_update_commit_message";
    const commit_msg_file_name = "COMMIT_MSG";
    const commit_msg_file_path = test_dir_rel_path ++ "/" ++ commit_msg_file_name;

    const initial_msg = "Initial commit\n";
    const trimmed_initial_msg =
        \\Initial commit
    ;

    const feature_branch = "feature-branch";

    try std.fs.cwd().makeDir(test_dir_rel_path);
    var test_dir = try std.fs.cwd().openDir(
        test_dir_rel_path,
        .{},
    );
    defer {
        test_dir.close();
        std.fs.cwd().deleteTree(test_dir_rel_path) catch unreachable;
    }

    const commit_msg_file = try test_dir.createFile(commit_msg_file_name, .{});
    defer commit_msg_file.close();

    const len = try commit_msg_file.write(initial_msg);
    try testing.expectEqual(len, initial_msg.len);

    try updateCommitMessage(allocator, commit_msg_file_path, feature_branch);

    const updated_msg = try std.fs.cwd().readFileAlloc(allocator, commit_msg_file_path, 1024 * 1024);
    defer allocator.free(updated_msg);

    try testing.expectEqualStrings(feature_branch ++ ": " ++ trimmed_initial_msg, updated_msg);
}

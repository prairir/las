const std = @import("std");
const os = std.os;

const Allocator = std.mem.Allocator;

pub fn run(allocator: Allocator, paths: [][]const u8) anyerror!void {
    _ = allocator;

    for (paths) |path| {
        const stat = try os.fstatat(-100, path, 0);
        std.debug.print("{d}\n", .{stat.mode});
    }
}

const std = @import("std");
const os = std.os;

const Allocator = std.mem.Allocator;

const cat = @import("cat.zig");

const AT_FDCWD = -100;

pub fn run(allocator: Allocator, paths: [][]const u8) !void {
    var outBufWriter = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer outBufWriter.flush() catch unreachable;

    var writer = outBufWriter.writer();

    for (paths) |path| {
        const stat = try os.fstatat(AT_FDCWD, path, 0);

        switch (stat.mode & std.os.S.IFMT) {
            std.os.linux.S.IFREG => {
                try cat.run(allocator, path, stat, writer);
            },
            std.os.linux.S.IFDIR => {
                std.debug.print("REGULAR DIR LS LS\n", .{});
            },
            else => {
                std.debug.print("WHO KNOWS\n", .{});
            },
        }
    }
}

const std = @import("std");
const os = std.os;

const Allocator = std.mem.Allocator;

const AT_FDCWD = -100;

pub fn run(allocator: Allocator, paths: [][]const u8) anyerror!void {
    _ = allocator;

    for (paths) |path| {
        const stat = try os.fstatat(AT_FDCWD, path, 0);
        std.debug.print("{d}\n", .{stat.mode});

        switch (stat.mode & std.os.S.IFMT) {
            std.os.linux.S.IFREG => {
                std.debug.print("REGULAR FILE CAT CAT\n", .{});
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

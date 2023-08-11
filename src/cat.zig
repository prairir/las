const std = @import("std");
const os = std.os;
const io = std.io;
const fs = std.fs;
const File = fs.File;
const Allocator = std.mem.Allocator;

pub fn run(allocator: Allocator, path: []const u8, stat: os.Stat, writer: anytype) !void {
    const f = try fs.cwd().openFile(path, .{});

    var n: usize = undefined;
    var buf = try allocator.alloc(u8, @bitCast(stat.blksize));
    while (true) {
        n = try f.read(buf[0..]);

        _ = try writer.write(buf[0..n]);
        if (n < buf.len) {
            break;
        }
    }
}

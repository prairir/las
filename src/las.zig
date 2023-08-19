const std = @import("std");
const os = std.os;

const Allocator = std.mem.Allocator;

const cat = @import("cat.zig");
const ls = @import("ls.zig");

const states = @import("states.zig");

const Flags = @import("types.zig").Flags;

const AT_FDCWD = -100;

pub fn run(allocator: Allocator, paths: [][]const u8, flags: Flags) !void {
    var outBufWriter = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer outBufWriter.flush() catch unreachable;

    var writer = outBufWriter.writer();

    const states_list = try states.Parse(allocator, flags);
    defer allocator.free(states_list);

    var first = true;
    for (paths) |path| {
        if (first) {
            first = false;
        } else {
            try writer.print("\n", .{});
        }

        if (paths.len != 1) {
            try writer.print("{s}:\n", .{path});
        }

        const stat = try os.fstatat(AT_FDCWD, path, 0);

        switch (stat.mode & std.os.S.IFMT) {
            std.os.linux.S.IFREG => {
                try cat.run(allocator, path, stat, writer);
            },
            std.os.linux.S.IFDIR => {
                try ls.run(allocator, path, stat, writer, flags, states_list);
            },
            else => {
                try writer.print("WHO KNOWS\n", .{});
            },
        }
    }
}

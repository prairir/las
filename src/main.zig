const std = @import("std");
const io = std.io;

const clap = @import("clap");

const las = @import("las.zig");

const Flags = @import("types.zig").Flags;

pub fn main() !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help	displays this message
        \\-a, --all	do not ignore entries starting with .
        \\<FILE>
    );

    const parsers = comptime .{
        .FILE = clap.parsers.string,
    };

    var res = try clap.parse(clap.Help, &params, parsers, .{});
    defer res.deinit();

    if (res.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var files = std.ArrayList([]const u8).init(allocator);
    defer files.deinit();
    if (res.positionals.len == 0) {
        const files_arr = [_]u8{'.'};
        try files.append(files_arr[0..]);
    } else {
        for (res.positionals) |pos| {
            try files.append(pos);
        }
    }

    const fslice = try files.toOwnedSlice();

    var flags = Flags{ .All = res.args.all != 0 };
    try las.run(allocator, fslice, flags);
}

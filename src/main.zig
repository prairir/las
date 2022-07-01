const std = @import("std");
const io = std.io;
const os = std.os;

const clap = @import("clap");

const las = @import("las.zig");

const log = @import("log.zig");

const parsers = .{
    .FILE = clap.parsers.string,
};

pub fn main() anyerror!void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help	Displays this message
        \\<FILE>
    );

    const res = try clap.parse(clap.Help, &params, parsers, .{});

    if (res.args.help) {
        try log.errWriter.writeAll("Usage: las ");
        try clap.usage(log.errWriter, clap.Help, &params);
        try log.errWriter.writeAll("\n\nOptions:\n");
        try clap.help(log.errWriter, clap.Help, &params, .{});
        std.os.exit(0);
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
    las.run(allocator, files.toOwnedSlice()) catch |err| {
        try log.errWriter.print("las: ERROR: \"{s}\"", .{@errorName(err)});
    };
    os.exit(0);
}

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
    defer os.exit(0); //return 0 if exits nicely
    errdefer os.exit(1); // return 1 if error

    const params = comptime clap.parseParamsComptime(
        \\-h, --help	Displays this message
        \\-l, --long	Displays stat of arg. Similar to ls -l
        \\-a, --all		Displays all files including those starting with `.`
        \\<FILE>
    );

    const res = try clap.parse(clap.Help, &params, parsers, .{});

    if (res.args.help) {
        try log.errWriter.writeAll("Usage: las ");
        try clap.usage(log.errWriter, clap.Help, &params);
        try log.errWriter.writeAll("\n\nOptions:\n");
        try clap.help(log.errWriter, clap.Help, &params, .{});
        return;
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

    las.run(allocator, &log.outBufWriter.writer(), log.errWriter, files.toOwnedSlice(), res.args) catch |err| {
        try log.errWriter.print("las: ERROR: \"{s}\"\n", .{@errorName(err)});
        try log.errWriter.print("las: ERROR: {s}", .{@errorReturnTrace()});
        return err;
    };
    try log.outBufWriter.flush(); // flushed away
}

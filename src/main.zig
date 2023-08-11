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
        \\-a, --all	Displays all files including those starting with `.`
        \\<FILE>
    );

    const res = try clap.parse(clap.Help, &params, parsers, .{});

    if (res.args.help) {
        const errWriter = io.getStdErr().writer();
        try errWriter.writeAll("Usage: las ");
        try clap.usage(errWriter, clap.Help, &params);
        try errWriter.writeAll("\n\nOptions:\n");
        try clap.help(errWriter, clap.Help, &params, .{});
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

    var outBufWriter = std.io.bufferedWriter(std.io.getStdOut().writer());

    const errWriter = io.getStdErr().writer();

    var filesSlice = try files.toOwnedSlice();

    las.run(allocator, &outBufWriter.writer(), log.errWriter, filesSlice, res.args) catch |err| {
        try errWriter.print("las: ERROR: \"{s}\"\n", .{@errorName(err)});
        try errWriter.print("las: ERROR: {s}", .{@errorReturnTrace()});
        return err;
    };
    try log.outBufWriter.flush(); // flushed away
}

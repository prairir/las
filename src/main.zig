const std = @import("std");
const io = std.io;

const clap = @import("clap");

pub fn main() !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help	Displays this message
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

    for (res.positionals) |pos| {
        std.debug.print("{s}\n", .{pos});
    }
}

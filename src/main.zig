const std = @import("std");
const io = std.io;

const clap = @import("clap");

const parsers = .{
    .FILE = clap.parsers.string,
};

pub fn main() anyerror!void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help	Displays this message
        \\<FILE>
    );

    const res = try clap.parse(clap.Help, &params, parsers, .{});

    var errWriter = std.io.getStdErr().writer();

    if (res.args.help) {
        try errWriter.writeAll("Usage: las ");
        try clap.usage(errWriter, clap.Help, &params);
        try errWriter.writeAll("\n\nOptions:\n");
        try clap.help(errWriter, clap.Help, &params, .{});
        std.os.exit(0);
    }

    // Note that info level log messages are by default printed only in Debug
    // and ReleaseSafe build modes.
    for (res.positionals) |pos| {
        std.log.info("{s}", .{pos});
    }
}

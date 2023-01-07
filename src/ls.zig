const std = @import("std");
const fs = std.fs;
const Dir = fs.Dir;

pub fn run(outWriter: anytype, dir: Dir, args: anytype) anyerror!void {
    _ = args;

    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        try outWriter.print("{s}\n", .{entry.name});
    }

    //
    //var largest = while (try iter.next()) |entry| {
    //    try writer.print("{s} {d}\n", .{ entry.name, entry.name.len });
    //};
}

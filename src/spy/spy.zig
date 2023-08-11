const std = @import("std");
const fs = std.fs;

const types = @import("../types.zig");

const Allocator = std.mem.Allocator;

// spy.run: runs the spy algorithm on a slice of entries.
// returns: allocates entries array. callers responsibilty to free
//
// all
pub fn run(allocator: Allocator, errWriter: anytype, all: bool, params: []u8) anyerror![]type.Entry {
    _ = allocator;
    _ = errWriter;
    _ = all;
    _ = params;
    var entries = std.MultiArrayList(types.Entry);

    return &entries.Slice;
}

fn walk(allocator: Allocator, all: bool, path: []u8, entries: std.MultiArrayList(types.Entry)) anyerror!void {
    _ = allocator;
    _ = all;
    _ = entries;

    var outBufWriter = std.io.bufferedWriter(std.io.getStdOut().writer());
    defer outBufWriter.flush();

    var dir = fs.openDirAbsolute(path, .{ .iterate = true }) catch |err| switch (err) {
        fs.Dir.OpenError.NotDir => {},
        else => {
            return err;
        },
    };
    _ = dir;
}

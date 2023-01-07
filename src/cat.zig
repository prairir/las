const std = @import("std");
const fs = std.fs;
const File = fs.File;
const os = std.os;

pub fn run(outWriter: anytype, file: File, args: anytype) anyerror!void {
    var n: usize = undefined;

    _ = args;

    var buf = [_]u8{0} ** 2048; // buffer is 2KB
    while (true) {
        n = try file.read(buf[0..]);

        _ = try outWriter.write(buf[0..n]);
        if (n < buf.len) { // n < buf.len is true when read hits EOF
            return;
        }
    }
}

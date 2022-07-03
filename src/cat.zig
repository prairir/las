const std = @import("std");
const fs = std.fs;
const File = fs.File;
const os = std.os;

const log = @import("log.zig");

pub fn run(file: File) anyerror!void {
    var n: usize = undefined;

    var writer = log.outBufWriter.writer();

    var buf = [_]u8{0} ** 2048; // buffer is 2KB
    while (true) {
        n = try file.read(buf[0..]);

        _ = try writer.write(buf[0..n]);
        if (n < buf.len) { // n < buf.len is true when read hits EOF
            try log.outBufWriter.flush();
            os.exit(0);
            return;
        }
    }
}

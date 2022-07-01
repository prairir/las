const std = @import("std");
const fs = std.fs;
const File = fs.File;
const fmt = std.fmt;

pub fn run(file: File) void {
    std.log.info("cat: {*}", .{&file});
    //const stat = file.stat(){};
    //fmt.format(, comptime fmt: []const u8, args: anytype)
}

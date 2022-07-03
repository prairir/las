const std = @import("std");
const fs = std.fs;
const Dir = fs.Dir;

pub fn run(dir: Dir) anyerror!void {
    std.log.info("ls: {*}", .{&dir});
}

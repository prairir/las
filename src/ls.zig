const std = @import("std");
const fs = std.fs;
const Dir = fs.Dir;

pub fn run(dir: Dir) void {
    std.log.info("ls: {*}", .{&dir});
}

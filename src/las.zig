const std = @import("std");
const os = std.os;
const fs = std.fs;
const File = fs.File;
const Dir = fs.Dir;
const Allocator = std.mem.Allocator;

const log = @import("log.zig");

const ls = @import("ls.zig");
const cat = @import("cat.zig");

pub fn run(allocator: Allocator, files: [][]const u8) anyerror!void {
    for (files) |path| {
        var absPath: []u8 = try std.fs.path.resolve(allocator, (&[_][]const u8{path})[0..]);

        var directory: Dir = fs.openDirAbsolute(absPath, .{ .iterate = true }) catch |err| {
            if (err == Dir.OpenError.NotDir) {
                const file: File = try fs.openFileAbsolute(absPath, .{ .mode = fs.File.OpenMode.read_only });
                defer file.close();
                cat.run(file);
                return;
            } else if (err == Dir.OpenError.FileNotFound) {
                try log.errWriter.print("\"{s}\": not found\n", .{path});
                os.exit(1);
                return;
            }

            return err;
        };
        defer directory.close();
        ls.run(directory);
    }
}

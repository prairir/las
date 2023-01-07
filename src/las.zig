const std = @import("std");
const os = std.os;
const fs = std.fs;
const File = fs.File;
const Dir = fs.Dir;
const Allocator = std.mem.Allocator;

const ls = @import("ls.zig");
const cat = @import("cat.zig");

const long = @import("long.zig");

const cmd = @import("cmd.zig");

pub fn run(allocator: Allocator, outWriter: anytype, errWriter: anytype, files: [][]const u8, args: anytype) anyerror!void {
    if (args.long) {
        try long.run(allocator, outWriter, errWriter, files, args);
        return;
    }

    for (files) |path| {
        var absPath: []u8 = try std.fs.path.resolve(allocator, (&[_][]const u8{path})[0..]);

        var result = cmd.dirOrFile(absPath) catch |err| {
            if (err == Dir.OpenError.FileNotFound) {
                try errWriter.print("\"{s}\": not found\n", .{path});
                return;
            }
            return err;
        };
        switch (result) {
            .dir => {
                defer result.dir.close();
                try ls.run(outWriter, result.dir, args);
            },
            .file => {
                defer result.file.close();
                try cat.run(outWriter, result.file, args);
            },
        }
        //var directory: Dir = fs.openDirAbsolute(absPath, .{ .iterate = true }) catch |err| {
        //    if (err == Dir.OpenError.NotDir) {
        //        const file: File = try fs.openFileAbsolute(absPath, .{ .mode = fs.File.OpenMode.read_only });
        //        defer file.close();
        //        try cat.run(outWriter, file, args);
        //        continue;
        //    } else if (err == Dir.OpenError.FileNotFound) {
        //        try errWriter.print("\"{s}\": not found\n", .{path});
        //        return;
        //    }

        //    return err;
        //};
        //defer directory.close();
        //try ls.run(outWriter, directory, args);
    }
}

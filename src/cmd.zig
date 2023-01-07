const std = @import("std");
const os = std.os;
const fs = std.fs;
const File = fs.File;
const Dir = fs.Dir;

const dir_or_file = union(enum) {
    file: File,
    dir: Dir,
};

// path needs to be absolute
pub fn dirOrFile(path: []const u8) anyerror!dir_or_file {
    var dir = fs.openDirAbsolute(path, .{ .iterate = true }) catch |err| {
        if (err == Dir.OpenError.NotDir) {
            var file = try fs.openFileAbsolute(path, .{ .mode = fs.File.OpenMode.read_only });
            return dir_or_file{ .file = file };
        }
        return err;
    };
    return dir_or_file{ .dir = dir };
}

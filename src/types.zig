const std = @import("std");

pub const Entry = union(enum) {
    var kind = std.fs.IterableDir.Entry.Kind;

    path: []u8,

    Dir: Dir,
    File: File,
};

pub const File = struct {
    path: []u8,
};

pub const Dir = struct {
    path: []u8,
    Children: []Entry,
};

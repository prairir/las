const std = @import("std");
const os = std.os;
const fs = std.fs;
const Allocator = std.mem.Allocator;

const Entry = struct {
    allocator: Allocator,
    parent_path: []const u8,
    name: ?[]const u8,

    pub fn init(allocator: Allocator, parent_path: []const u8) !Entry {
        const pp_copy = try allocator.dupe(parent_path);
        return Entry{
            .allocator = allocator,
            .parent_path = pp_copy,
        };
    }

    pub fn deinit(self: *Entry) void {
        self.allocator.free(self.parent_path);
        self.allocator.free(self.name);
    }
};

pub fn run(allocator: Allocator, path: []const u8, stat: os.Stat, writer: anytype) !void {
    _ = writer;
    _ = stat;

    try spy(allocator, path, .{State.name});

    try print();
}

const State = enum {
    name,
    strmode,
};

// type to simplify passing around the dir entry and stat
// and processing entries with special processing rules. This also adds the ability
// to do nice DI
const SpyEntry = struct {
    dir_entry: fs.IterableDir.Entry,
    stat: ?os.Stat,

    pub fn process(self: SpyEntry, state: State, entry: *Entry) !void {
        switch (state) {
            .name => process_name(self, entry),
        }
    }

    fn process_name(self: State, entry: *Entry) void {
        entry.name = self.dir_entry.name;
    }
};

// spy: dir walk + populate entry table. Returned list of entries is owned by caller
pub fn spy(allocator: Allocator, path: []const u8, states: []const State) ![]Entry {
    var entries = std.ArrayList(Entry).init(allocator);
    const d = try fs.cwd().openIterableDir(path, .{}); //openFile works like fstatat in terms of relativicity
    for (d) |dir_entry| {
        const e = try Entry.init(allocator, path);

        const spy_entry = SpyEntry{ .dir_entry = dir_entry, .stat = null };
        for (states) |state| {
            try spy_entry.process(state, &e);
        }

        try entries.append(e);
    }

    return entries.toOwnedSlice();
}

pub fn print() !void {}

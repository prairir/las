const std = @import("std");
const os = std.os;
const fs = std.fs;
const Allocator = std.mem.Allocator;

// type to simplify passing around the dir entry and stat
pub const SpyContext = struct {
    dir_entry: fs.IterableDir.Entry,
    stat: ?os.Stat,
};

pub const Entry = struct {
    allocator: Allocator,
    parent_path: []const u8,
    name: ?[]const u8,

    pub fn init(allocator: Allocator, parent_path: []const u8) !Entry {
        const pp_copy = try allocator.dupe(u8, parent_path);
        return .{
            .allocator = allocator,
            .parent_path = pp_copy,
            .name = null,
        };
    }

    pub fn setName(self: *Entry, name: []const u8) !void {
        if (self.name != null) {
            self.allocator.free(self.name.?);
        }

        self.name = try self.allocator.dupe(u8, name);
    }

    pub fn deinit(self: *Entry) void {
        self.allocator.free(self.parent_path);

        if (self.name != null) {
            self.allocator.free(self.name.?);
        }
    }
};

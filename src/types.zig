const std = @import("std");
const os = std.os;
const fs = std.fs;
const Allocator = std.mem.Allocator;

pub const Config = struct {
    ShowHidden: bool = false,
    ShowSelf: bool = false,
    ShowParent: bool = false,

    pub fn init(flags: anytype) Config {
        var config: Config = .{};

        if (flags.all != 0) {
            config.ShowHidden = true;
            config.ShowSelf = true;
            config.ShowParent = true;
        }

        return config;
    }
};

// type to simplify passing around the dir entry and stat
pub const SpyContext = struct {
    name: []const u8,
    kind: ?fs.File.Kind = null,
    stat: ?os.Stat = null,
};

pub const Entry = struct {
    allocator: Allocator,
    name: ?[]const u8 = null,

    pub fn setName(self: *Entry, name: []const u8) !void {
        if (self.name != null) {
            self.allocator.free(self.name.?);
        }

        self.name = try self.allocator.dupe(u8, name);
    }

    pub fn deinit(self: *Entry) void {
        if (self.name != null) {
            self.allocator.free(self.name.?);
        }
    }
};

const std = @import("std");
const os = std.os;
const fs = std.fs;
const Allocator = std.mem.Allocator;

pub const AT_FDCWD = -100;

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
    allocator: Allocator,
    parent_path: []const u8,
    name: []const u8,
    kind: ?fs.File.Kind = null,
    stat: ?os.Stat = null,

    pub fn getStat(self: *SpyContext) !os.Stat {
        if (self.stat == null) {
            var paths = [_][]const u8{ self.parent_path, self.name };
            const path = try fs.path.join(self.allocator, &paths);
            defer self.allocator.free(path);

            self.stat = try os.fstatat(AT_FDCWD, path, 0);
        }

        return self.stat.?;
    }
};

pub const Entry = struct {
    allocator: Allocator,
    name: ?[]const u8 = null,
    strmode: ?[10]u8 = null,
    size: ?usize = null,

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

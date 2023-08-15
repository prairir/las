const std = @import("std");

const Allocator = std.mem.Allocator;

const Types = @import("types.zig");
const SpyContext = Types.SpyContext;
const Entry = Types.Entry;

pub const State = union(enum) {
    name: Name,
};

// name of file
pub const Name = struct {
    pub fn spy(self: Name, context: SpyContext, entry: *Entry) void {
        _ = self;
        entry.name = context.dir_entry.name;
    }

    pub fn calculate(self: Name, entry: Entry) u32 {
        _ = self;
        return entry.name.len;
    }

    pub fn print(self: Name, entry: Entry, writer: anytype) !void {
        _ = self;
        try writer.print("{s}", .{entry.name.?});
    }
};

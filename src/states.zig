const std = @import("std");

const Allocator = std.mem.Allocator;

const Types = @import("types.zig");
const SpyContext = Types.SpyContext;
const Entry = Types.Entry;
const Config = Types.Config;

pub const State = union(enum) {
    name: Name,
    end: End, // end state, this makes every printable state to be optional
};

// owner owns states array
pub fn Parse(allocator: Allocator, config: Config) ![]State {
    var states = std.ArrayList(State).init(allocator);
    defer states.deinit();
    _ = config;

    try states.append(.{ .name = .{ .a = true } });

    try states.append(.{ .end = .{ .a = true } });

    return states.toOwnedSlice();
}

pub const End = struct {
    a: bool,
};

// name of file
pub const Name = struct {
    a: bool, // this is literally just to make the compiler happy and not a 0 size type
    pub fn spy(self: Name, context: SpyContext, entry: *Entry) !void {
        _ = self;
        try entry.setName(context.name);
    }

    pub fn calculate(self: Name, entry: Entry) usize {
        _ = self;
        return entry.name.?.len;
    }

    pub fn print(self: Name, entry: Entry, writer: anytype) !void {
        _ = self;
        try writer.print("{s}", .{entry.name.?});
    }
};

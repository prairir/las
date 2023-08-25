const std = @import("std");

const Allocator = std.mem.Allocator;

const Types = @import("types.zig");
const SpyContext = Types.SpyContext;
const Entry = Types.Entry;
const Config = Types.Config;

pub const State = union(enum) {
    name: Name,
    strmode: Strmode,
    end: End, // end state, this makes every printable state to be optional
};

// owner owns states array
pub fn Parse(allocator: Allocator, config: Config) ![]State {
    var states = std.ArrayList(State).init(allocator);
    defer states.deinit();
    _ = config;

    try states.append(.{ .strmode = .{} });

    try states.append(.{ .name = .{} });

    try states.append(.{ .end = .{} });

    return states.toOwnedSlice();
}

pub const End = struct {
    a: bool = true,
};

const permsVals = struct {
    key: u16,
    value: u8,
};

const permsArr = [_]permsVals{
    .{
        .key = 0o400,
        .value = 'r',
    },
    .{
        .key = 0o200,
        .value = 'w',
    },
    .{
        .key = 0o100,
        .value = 'x',
    },
    .{
        .key = 0o040,
        .value = 'r',
    },
    .{
        .key = 0o020,
        .value = 'w',
    },
    .{
        .key = 0o010,
        .value = 'x',
    },
    .{
        .key = 0o004,
        .value = 'r',
    },
    .{
        .key = 0o002,
        .value = 'w',
    },
    .{
        .key = 0o001,
        .value = 'x',
    },
};

pub const Strmode = struct {
    a: bool = true,
    pub fn spy(self: Strmode, context: *SpyContext, entry: *Entry) !void {
        _ = self;
        var str = [_]u8{'-'} ** 10;

        const stat = try context.getStat();
        const mode = stat.mode;

        inline for (permsArr, 0..) |perm, i| {
            if (mode & perm.key == perm.key) {
                str[i + 1] = perm.value;
            }
        }

        switch (mode & 0o170000) {
            0o010000 => str[0] = 'p', // fifo
            0o020000 => str[0] = 'c', // character special
            0o040000 => str[0] = 'd', // directory
            0o060000 => str[0] = 'b', // block special
            0o100000 => {}, // regular file
            0o120000 => str[0] = 'l', // symbolic link
            0o140000 => str[0] = 's', // socket
            else => str[0] = '?', // unknown
        }

        if ((mode & (0o000010 | 0o002000)) == 0o002000) {
            str[6] = 'S';
        } else if ((mode & (0o000010 | 0o002000)) == (0o000010 | 0o002000)) {
            str[6] = 's';
        }

        if ((mode & (0o000001 | 0o001000)) == 0o001000) {
            str[9] = 'T';
        } else if ((mode & (0o000001 | 0o001000)) == (0o000001 | 0o001000)) {
            str[6] = 's';
        }

        entry.strmode = str;
    }

    pub fn calculate(self: Strmode) usize {
        _ = self;
        return 10;
    }

    pub fn print(self: Strmode, entry: Entry, writer: anytype) !void {
        _ = self;
        try writer.print("{s}", .{entry.strmode.?});
    }
};

// name of file
pub const Name = struct {
    a: bool = true, // this is literally just to make the compiler happy and not a 0 size type
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

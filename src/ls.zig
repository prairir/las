const std = @import("std");
const os = std.os;
const fs = std.fs;
const Allocator = std.mem.Allocator;

const States = @import("states.zig");

const Types = @import("types.zig");
const SpyContext = Types.SpyContext;
const Entry = Types.Entry;
const Flags = Types.Flags;

// run: main entry point for ls. `Stat` can be passed in to avoid re-calling `stat`.
// under the hood, it uses a modular system of states. that way printing can be semi plug and play.
//
// I literally spent **a year** tinkering with this.
pub fn run(allocator: Allocator, path: []const u8, stat: os.Stat, writer: anytype, flags: Flags) !void {
    _ = stat;

    const s_list = &[_]States.State{States.State{ .name = .{} }};
    var entries = try spy(allocator, path, s_list, flags);

    const max_widths = try calculate(allocator, s_list, entries);
    defer allocator.free(max_widths);

    try print(writer, s_list, entries, max_widths);

    for (entries) |*e| {
        e.deinit();
    }
}

// spy: dir walk + populate entry array. Returned list of entries is owned by caller
pub fn spy(allocator: Allocator, path: []const u8, states: []const States.State, flags: Flags) ![]Entry {
    var entries = std.ArrayList(Entry).init(allocator);
    const d = try fs.cwd().openIterableDir(path, .{}); //openFile works like fstatat in terms of relativicity
    var iterator = d.iterate();

    while (try iterator.next()) |dir_entry| {
        if (!flags.All and dir_entry.name[0] == '.') {
            continue;
        }

        var e = try Entry.init(allocator, path);

        const spy_entry = .{ .dir_entry = dir_entry, .stat = null };
        for (states) |state| switch (state) {
            .name => |s| {
                try s.spy(spy_entry, &e);
            },
        };

        try entries.append(e);
    }

    return entries.toOwnedSlice();
}

// calculate: calculate the max length of each column
pub fn calculate(allocator: Allocator, states: []const States.State, entries: []Entry) ![]const usize {
    var column_max = std.ArrayList(usize).init(allocator);

    for (entries) |e| {
        for (states, 0..) |state, i| {
            const size = switch (state) {
                .name => |s| s.calculate(e),
            };

            if (column_max.items.len <= i) {
                try column_max.append(size);
                continue;
            }

            const col_size = column_max.items[i];

            if (col_size < size) {
                column_max.items[i] = size;
            }
        }
    }

    return column_max.toOwnedSlice();
}

pub fn print(writer: anytype, states: []const States.State, entries: []Entry, widths: []const usize) !void {
    for (entries) |e| {
        for (states, widths) |state, w| switch (state) {
            .name => |s| {
                try s.print(e, writer);
                try writer.print("{}\n", .{w});
            },
        };
    }
}

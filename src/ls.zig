const std = @import("std");
const os = std.os;
const fs = std.fs;
const Allocator = std.mem.Allocator;

const States = @import("states.zig");

const Types = @import("types.zig");
const SpyContext = Types.SpyContext;
const Entry = Types.Entry;
const Config = Types.Config;

// run: main entry point for ls. `Stat` can be passed in to avoid re-calling `stat`.
// under the hood, it uses a modular system of states. that way printing can be semi plug and play.
//
// I literally spent **a year** tinkering with this.
pub fn run(allocator: Allocator, path: []const u8, stat: os.Stat, writer: anytype, config: Config, states: []const States.State) !void {
    var entries = try spy(allocator, path, states, config, stat);

    const max_widths = try calculate(allocator, states, entries);
    defer allocator.free(max_widths);

    try print(writer, states, entries, max_widths);

    for (entries) |*e| {
        e.deinit();
    }
}

// spy: dir walk + populate entry array. Returned list of entries is owned by caller
pub fn spy(allocator: Allocator, path: []const u8, states: []const States.State, config: Config, parent_stat: os.Stat) ![]Entry {
    var entries = std.ArrayList(Entry).init(allocator);

    const d = try fs.cwd().openIterableDir(path, .{}); //openFile works like fstatat in terms of relativicity
    var iterator = d.iterate();

    if (config.ShowSelf) {
        var e = Entry{ .allocator = allocator };
        var context = .{ .allocator = allocator, .parent_path = path, .name = ".", .stat = parent_stat };
        try fill_entry(&context, states, &e);
        try entries.append(e);
    }

    if (config.ShowParent) {
        var e = Entry{ .allocator = allocator };
        var context = .{ .allocator = allocator, .parent_path = path, .name = ".." };
        try fill_entry(&context, states, &e);
        try entries.append(e);
    }

    while (try iterator.next()) |dir_entry| {
        if (!config.ShowHidden and dir_entry.name[0] == '.') {
            continue;
        }

        var e = Entry{ .allocator = allocator };

        var context = .{ .allocator = allocator, .parent_path = path, .name = dir_entry.name };
        try fill_entry(&context, states, &e);
        try entries.append(e);
    }

    return entries.toOwnedSlice();
}

// fill_entry: fill an entry with data from the states
fn fill_entry(context: *SpyContext, states: []const States.State, entry: *Entry) !void {
    for (states) |state| switch (state) {
        .name => |s| {
            try s.spy(context.*, entry);
        },
        .strmode => |s| {
            try s.spy(context, entry);
        },
        .size => |s| {
            try s.spy(context, entry);
        },
        .end => break,
    };
}

// calculate: calculate the max length of each column
pub fn calculate(allocator: Allocator, states: []const States.State, entries: []Entry) ![]const usize {
    var column_max = std.ArrayList(usize).init(allocator);

    for (entries) |e| {
        for (states, 0..) |state, i| {
            if (state == States.State.end) {
                break;
            }
            const size = get_entry_size(state, e);

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

fn get_entry_size(state: States.State, entry: Entry) usize {
    return switch (state) {
        .name => |s| s.calculate(entry),
        .strmode => |s| s.calculate(),
        .size => |s| s.calculate(entry),
        .end => unreachable,
    };
}

pub fn print(writer: anytype, states: []const States.State, entries: []Entry, widths: []const usize) !void {
    for (entries) |e| {
        for (states, 0..) |state, i| {
            switch (state) {
                .name => |s| {
                    try s.print(e, writer);
                    const len = get_entry_size(state, e);
                    try printN(writer, widths[i] - len, " ");
                },
                .strmode => |s| {
                    try s.print(e, writer);
                },
                .size => |s| {
                    const len = get_entry_size(state, e);
                    try printN(writer, widths[i] - len, " ");
                    try s.print(e, writer);
                },
                .end => break,
            }
            try writer.print(" ", .{});
        }
        try writer.print("\n", .{});
    }
}

fn printN(writer: anytype, times: usize, token: []const u8) !void {
    for (0..times) |_| {
        try writer.print("{s}", .{token});
    }
}

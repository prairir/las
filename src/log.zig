const std = @import("std");
const io = std.io;

pub var outBufWriter = std.io.bufferedWriter(std.io.getStdOut().writer());

pub const errWriter = io.getStdErr().writer();

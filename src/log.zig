const std = @import("std");
const io = std.io;

const outWriter = io.getStdOut().writer();

pub const outBufWriter = io.bufferedWriter(outWriter).writer();

pub const errWriter = io.getStdErr().writer();

const std = @import("std");
const os = std.os;
const fs = std.fs;
const File = fs.File;
const Dir = fs.Dir;

const Allocator = std.mem.Allocator;
const heap = std.heap;

const fmt = std.fmt;

const off_t = os.linux.off_t;

const log = @import("log.zig");

const cmd = @import("cmd.zig");

const id = @import("id.zig");
const UIDFileMap = id.IDMap;

const MAX_PATH_SIZE = 512;
const MAX_USER_SIZE = 32;
const MAX_GROUP_SIZE = 32;

const SPACE_WIDTH = 1;

const STR_LEN_64U = 21; // len of str of `2^64`

const MAX_LINE_SIZE: usize = MAX_PATH_SIZE + 10 + STR_LEN_64U + MAX_USER_SIZE + MAX_GROUP_SIZE + @sizeOf(usize) + @sizeOf(u8) + MAX_PATH_SIZE + (SPACE_WIDTH * 5);

pub fn run(allocator: Allocator, outWriter: anytype, errWriter: anytype, files: [][]const u8, args: anytype) anyerror!void {
    const userFile = "/etc/passwd";
    const groupFile = "/etc/group";
    var uid = try UIDFileMap.init(allocator, userFile, groupFile);
    defer uid.deinit() catch {};

    //TODO: think of multiple groups printing
    //var maxLen: usize = undefined;
    //for (files) |path| {

    //}
    for (files) |path| {
        var absPath: []u8 = try std.fs.path.resolve(allocator, (&[_][]const u8{path})[0..]);

        var result = cmd.dirOrFile(absPath) catch |err| {
            if (err == Dir.OpenError.FileNotFound) {
                try errWriter.print("\"{s}\": not found\n", .{path});
                return;
            }
            return err;
        };
        switch (result) {
            .dir => {
                var buf: [MAX_PATH_SIZE]u8 = undefined;
                var fixAlloc = heap.FixedBufferAllocator.init(&buf);
                var fixAllocator = fixAlloc.allocator();
                var iter = result.dir.iterate();
                while (try iter.next()) |entry| {
                    if (!args.all and entry.name[0] == '.') continue;
                    var entryPath = try fs.path.join(fixAllocator, (&[_][]const u8{ path, entry.name }));
                    var file = try os.open(entryPath, os.O.RDONLY, 777);
                    var stat = try os.fstat(file);

                    const user = uid.findUName(stat.uid) orelse return error.UIDNotFound;
                    const group = uid.findGName(stat.gid) orelse return error.GIDNotFound;
                    const strMode = strmode(stat.mode);
                    const size: off_t = @intCast(off_t, stat.size);

                    const maxSize = try strLenInt(size);

                    const maxLink = try strLenInt(stat.nlink);
                    const lineArgs = statLine{
                        .maxUserLen = user.len,
                        .maxGroupLen = group.len,
                        .maxSizeLen = maxSize,
                        .maxLinkLen = maxLink,
                        .modeStr = strMode[0..],
                        .hardLinkCount = stat.nlink,
                        .ownerU = user,
                        .ownerG = group,
                        .lastModified = 5,
                        .path = entry.name,
                        .size = size,
                    };

                    var line = try constructLine(lineArgs);
                    try outWriter.print("{s}\n", .{line});

                    //try print(outWriter, entry.name, stat);

                    fixAllocator.free(entryPath); //free so its only using 1 buffer
                }
            },
            .file => {
                var stat = try os.fstat(@as(os.fd_t, result.file.handle));
                //var maxUserLen
                //maxUserLen: usize,
                //maxGroupLen: usize,
                //maxSizeLen: usize,
                //try print(outWriter, path, stat);
                //log.errWriter.print("{*}\n", .{&uid.map}) catch {};
                const user = uid.findUName(stat.uid) orelse return error.UIDNotFound;
                const group = uid.findGName(stat.gid) orelse return error.GIDNotFound;
                const strMode = strmode(stat.mode);
                const size: off_t = @intCast(off_t, stat.size);

                const maxSize = try strLenInt(size);

                const maxLink = try strLenInt(stat.nlink);
                //user = std.process.getUserInfo(name: []const u8)

                const lineArgs = statLine{
                    .maxUserLen = user.len,
                    .maxGroupLen = group.len,
                    .maxSizeLen = maxSize,
                    .maxLinkLen = maxLink,
                    .modeStr = strMode[0..],
                    .hardLinkCount = stat.nlink,
                    .ownerU = user,
                    .ownerG = group,
                    .lastModified = 5,
                    .path = path,
                    .size = size,
                };
                const line = constructLine(lineArgs);
                try outWriter.print("{s}\n", .{line});
            },
        }
    }
}

const statLine = struct {
    maxUserLen: usize,
    maxGroupLen: usize,
    maxSizeLen: usize,
    maxLinkLen: usize,
    modeStr: []const u8,
    ownerU: []const u8,
    ownerG: []const u8,
    lastModified: u8,
    path: []const u8,
    hardLinkCount: u64,
    size: off_t,
};

fn print(outWriter: anytype, name: []const u8, stats: anytype) anyerror!void {
    if (stats) {
        const user = "ryana"[0..];
        const group = "bruh"[0..];
        const strMode = strmode(stats.mode);
        const size = @intCast(off_t, stats.size);
        //user = std.process.getUserInfo(name: []const u8)
        const lineArgs = statLine{
            .maxUserLen = 5,
            .maxGroupLen = 4,
            .maxSizeLen = 5,
            .maxLinkLen = 1,
            .modeStr = strMode[0..],
            .hardLinkCount = stats.nlink,
            .ownerU = user,
            .ownerG = group,
            .lastModified = 5,
            .path = name,
            .size = size,
        };
        const line = constructLine(lineArgs);
        try outWriter.print("{s}\n", .{line});
        //try outWriter.print("name:          {s}\n", .{name});
        //try outWriter.print("full stat str: {s}\n", .{strMode});
        //try outWriter.print("full stat:     {s}\n", .{line});
        //try outWriter.print("full stat:     {o}\n", .{stats.mode});
        //try outWriter.print("full bin stat: {b}\n", .{stats.mode});
        //try outWriter.print("file stat:     {o}\n", .{stats.mode % 0o1000});
        //try outWriter.print("file bin stat: {b}\n", .{stats.mode % 0o1000});
        //try outWriter.print("type stat:     {o}\n", .{stats.mode >> 9});
        //try outWriter.print("type bin stat: {b}\n", .{stats.mode >> 9});
        //try outWriter.print("construct:     {b}\n", .{((stats.mode >> 9) << 9) + (stats.mode % 0o1000)});
        //try outWriter.print("\n", .{});
    } else |err| {
        return err;
    }
}

// TODO: look into `lastModified` timestamp format
fn constructLine(stats: statLine) anyerror![]u8 {
    if (stats.modeStr.len > 10) {
        unreachable;
    }
    if (stats.ownerU.len > MAX_USER_SIZE) {
        unreachable;
    }
    if (stats.ownerG.len > MAX_GROUP_SIZE) {
        unreachable;
    }
    //var line: [MAX_LINE_SIZE]u8 = [_]u8{' '} ** MAX_LINE_SIZE; // max size of path on linux
    //var line = [_]u8{0} ** MAX_LINE_SIZE;
    var line: [MAX_LINE_SIZE]u8 = undefined;

    var stream = std.io.fixedBufferStream(&line);
    var streamWriter = stream.writer();

    // mode string
    _ = try streamWriter.write(stats.modeStr);
    //line[0..modeStr.len] = modeStr;
    //var index = modeStr.len;

    _ = try streamWriter.write(" " ** SPACE_WIDTH);
    //line[(index + 1)..(index + SPACE_WIDTH)] = "    "; // 4 spaces
    //index += 1 + SPACE_WIDTH;

    // hard link count
    try streamWriter.print("{d}", .{stats.hardLinkCount});
    var pos = try stream.getPos();
    const linkLen = try strLenInt(stats.hardLinkCount);
    bufFill(pos, (pos + (stats.maxLinkLen - linkLen)), &line, ' ');
    _ = try streamWriter.write(" " ** SPACE_WIDTH);
    //var b = std.fmt.bufPrint(line[index..], "{d}", .{hardLinkCount});
    //line[index..] = b;
    //index += 1 + b.len;

    // owner
    _ = try streamWriter.write(stats.ownerU);
    //line[index..] = ownerU;
    //index += 1 + ownerU.len;

    pos = try stream.getPos();
    bufFill(pos, (pos + (stats.maxUserLen - stats.ownerU.len)), &line, ' ');
    //bufFill(index, (index + (maxUserLen - ownerU.len)), line, ' ');
    //index += maxUserLength - ownerU.len;

    try stream.seekTo(pos + (stats.maxUserLen - stats.ownerU.len));
    _ = try streamWriter.write(" " ** SPACE_WIDTH);

    // group
    _ = try streamWriter.write(stats.ownerG);
    //line[index..] = ownerG;
    //index += 1 + ownerG.len;

    pos = try stream.getPos();
    bufFill(pos, (pos + stats.maxGroupLen - stats.ownerG.len), &line, ' ');
    try stream.seekTo(pos + stats.maxGroupLen - stats.ownerG.len);
    _ = try streamWriter.write(" " ** SPACE_WIDTH);
    //bufFill(index, (index + (maxGroupLen - ownerG.len)), line, ' ');
    //index += maxGroupLen - ownerG.len;

    // file size
    try streamWriter.print("{d}", .{stats.size});

    const sizeLen = if (stats.size < 1) 0 else @floatToInt(u64, std.math.floor(std.math.log10(@intToFloat(f64, stats.size)))) + 1;

    pos = try stream.getPos();
    bufFill(pos, (pos + stats.maxSizeLen - sizeLen), &line, ' ');
    try stream.seekTo(pos + stats.maxSizeLen - sizeLen);
    //try streamWriter.print("{d}", .{size / 8});
    _ = try streamWriter.write(" " ** SPACE_WIDTH);
    //b = std.fmt.bufPrint(line[index..], "{d} bytes", .{fSize});
    //line[index..] = b;
    //index += 1 + b.len;

    // time
    // TODO: make actual nice timestamps
    try streamWriter.print("{d}", .{stats.lastModified});
    _ = try streamWriter.write(" " ** SPACE_WIDTH);
    //b = std.fmt.bufPrint(line[index..], "{d}", .{lastModified});
    //line[index..] = b;
    //index += 1 + b.len;

    //path
    _ = try streamWriter.write(stats.path);
    //line[index..(index + 1 + path.len)] = path;
    //index += 1 + path.len;

    return stream.getWritten();
    //return line[0..index];
}

// fill provided `buf` between `startIndex` and `endIndex` with `fill`
fn bufFill(startIndex: usize, endIndex: usize, buf: []u8, fill: u8) void {
    // TODO: got an integer overflow at this position with the command `./zig-out/bin/las -l ARCHITECTURE.md gyro.zzz ../../../rpmk11`. Find out why and fix. I suspect its because bad math in `line`
    var i = endIndex - startIndex;
    while (i > 0) {
        buf[startIndex + i] = fill;
        i -= 1;
    }
}

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

// convert inode status information into a symbolic string
// essentially the same as strmode(3) in libbsd
fn strmode(mode: u64) [10]u8 {
    var str = [_]u8{'-'} ** 10;

    inline for (permsArr) |perm, i| {
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

    return str;
}

var strLenBuf: [STR_LEN_64U]u8 = undefined;
var strLenStream = std.io.fixedBufferStream(&strLenBuf);
var strLenWriter = strLenStream.writer();
// give the length of the string representation of a number
fn strLenInt(val: anytype) anyerror!usize {
    try strLenWriter.print("{d}", .{val});
    defer strLenStream.seekTo(0) catch {};
    return try strLenStream.getPos();
}

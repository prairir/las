const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;

const log = @import("log.zig");

var IDBuf: [10]u8 = undefined; // reused with uid and gid

const GetUsernameFromUIDError = error{
    UsernameNotFound,
} || anyerror;

pub const IDMap = struct {
    uidMap: std.AutoArrayHashMap(u32, []const u8),
    gidMap: std.AutoArrayHashMap(u32, []const u8),
    allocator: Allocator,

    const Self = @This();

    // uidFile must be absolute path
    pub fn init(allocator: Allocator, uidFile: []const u8, gidFile: []const u8) anyerror!Self {
        var uidMap = std.AutoArrayHashMap(u32, []const u8).init(allocator);
        var gidMap = std.AutoArrayHashMap(u32, []const u8).init(allocator);

        var self = Self{
            .allocator = allocator,
            .uidMap = uidMap,
            .gidMap = gidMap,
        };

        try self.loadMap(allocator, &self.uidMap, uidFile);
        try self.loadMap(allocator, &self.gidMap, gidFile);

        return self;
    }

    // does not clear memory in allocator, that needs to be handled by user
    pub fn deinit(self: *Self) anyerror!void {
        self.* = undefined;
    }

    // currently supports /etc/passwd and /etc/group
    // allocates the "id" names on the allocator as to save memory to only allocate whats needed
    // modifies map
    fn loadMap(_: Self, allocator: Allocator, map: *std.AutoArrayHashMap(u32, []const u8), fileName: []const u8) anyerror!void {
        var file = try fs.openFileAbsolute(fileName, .{ .mode = fs.File.OpenMode.read_only });
        defer file.close();

        var GetNameFromIDBuf: [2048]u8 = undefined; // buffer is 2KB, I could probably do some big math to figure it out but 2kb is plenty IMO

        var n: usize = undefined;

        var fileBuf: [2048]u8 = undefined; // buffer is 2KB, I could probably do some big math to figure it out but 2kb is plenty IMO
        var fileReader = std.io.bufferedReader(file.reader());
        var fileBufReader = fileReader.reader();
        while (try fileBufReader.readUntilDelimiterOrEof(&fileBuf, '\n')) |line| {
            n = line.len;

            var splat = std.mem.split(u8, fileBuf[0..n], ":");
            var name: []const u8 = undefined;
            var i: u8 = 0;
            while (splat.next()) |val| {
                i += 1;
                if (i == 1) {
                    name = val;
                } else if (i == 3) {
                    var id = try std.fmt.parseInt(u32, val, 10);
                    var nameCopy = try allocator.dupe(u8, name);
                    try map.put(id, nameCopy);
                    break;
                }
            }
            if (n < GetNameFromIDBuf[0..n].len) { // n < buf.len is true when read hits EOF
                break;
            }
        }
    }

    pub fn findUName(self: *Self, uid: u32) ?[]const u8 {
        return self.uidMap.get(uid);
    }

    pub fn findGName(self: *Self, gid: u32) ?[]const u8 {
        return self.gidMap.get(gid);
    }
};

//pub fn uidFileMap(allocator: Allocator, uidFile: []const u8) anyerror!UIDFileMap {
//    var file = try fs.openFileAbsolute(uidFile, .{ .mode = fs.File.OpenMode.read_only });
//    defer file.close();
//
//    var map = std.AutoArrayHashMap(u32, []const u8).init(allocator);
//
//    var n: usize = undefined;
//
//    var self = UIDFileMap{ .map = map };
//
//    var fileBuf: [2048]u8 = undefined; // buffer is 2KB, I could probably do some big math to figure it out but 2kb is plenty IMO
//    var fileReader = std.io.bufferedReader(file.reader());
//    var fileBufReader = fileReader.reader();
//    while (try fileBufReader.readUntilDelimiterOrEof(&fileBuf, '\n')) |line| {
//        n = line.len;
//
//        var splat = std.mem.split(u8, fileBuf[0..n], ":");
//        var userEndIndex: usize = 0;
//        var i: u8 = 0;
//        while (splat.next()) |val| {
//            i += 1;
//            if (i == 1) {
//                userEndIndex = val.len;
//            } else if (i == 3) {
//                var uid = try std.fmt.parseInt(u32, val, 10);
//                if (fileBuf[0] == 'r' and fileBuf[1] == 'y') {
//                    try log.errWriter.print("{}\n", .{std.fmt.fmtSliceHexUpper(fileBuf[0..userEndIndex])});
//                }
//                try self.map.put(uid, fileBuf[0..userEndIndex]);
//                if (fileBuf[0] == 'r' and fileBuf[1] == 'y') {
//                    const bruh = self.map.get(uid);
//                    log.errWriter.print("{}\n", .{std.fmt.fmtSliceHexUpper(bruh.?)}) catch {};
//                }
//                break;
//            }
//        }
//        if (n < GetUsernameFromUIDBuf[0..n].len) { // n < buf.len is true when read hits EOF
//            break;
//        }
//    }
//    log.errWriter.print("{*}\n", .{&self}) catch {};
//    log.errWriter.print("{*}\n", .{&self.map}) catch {};
//    return self;
//}

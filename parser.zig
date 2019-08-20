const std = @import("std");
const warn = std.debug.warn;

const ZigParser = @import("zig/zig_parser.zig").Parser;
const ZigNode = @import("zig/zig_parser.zig").Node;

usingnamespace @import("errors.zig");

pub fn main() !void {
    var allocator = std.heap.c_allocator;

    var args = std.process.args();
    if(!args.skip()) return;

    const filename = if(args.next(allocator)) |arg1| try arg1 else "example.zig"[0..];

    var file = try std.fs.File.openRead(filename);
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = std.os.mmap(
        null,
        file_size,
        std.os.PROT_READ,
        std.os.MAP_SHARED,
        file.handle,
        0,
    ) catch return error.OutOfMemory;
    defer std.os.munmap(buffer);

    var parser = try ZigParser.init(std.heap.c_allocator);
    defer parser.deinit();

    const ms_begin = std.time.milliTimestamp();
    _ = try parser.run(buffer[0..file_size]);
    const ms_end = std.time.milliTimestamp();

    var eit = parser.engine.errors.iterator(0);
    while(eit.next()) |err| {
        warn("{}:{}-{} {}\n", err.line, err.start, err.end, parseErrorToString(err.info));
    }
    else {
        warn("No errors\n");
    }
    warn("Duration: {}ms\n", ms_end-ms_begin);
}

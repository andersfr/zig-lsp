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

    var stream = file.inStream();
    const buffer = try stream.stream.readAllAlloc(allocator, 0x1000000);

    var parser = try ZigParser.init(std.heap.c_allocator);
    defer parser.deinit();

    if(try parser.run(buffer)) {
        var eit = parser.engine.errors.iterator(0);
        while(eit.next()) |err| {
            warn("{}:{}-{} {}\n", err.line, err.start, err.end, parseErrorToString(err.info));
        }
    }
}

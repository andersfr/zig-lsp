const std = @import("std");
const warn = std.debug.warn;

const ZigParser = @import("zig/zig_parser.zig").Parser;
const ZigNode = @import("zig/zig_parser.zig").Node;
const ZigToken = @import("zig/zig_grammar.tokens.zig").Token;

const ZigIr = struct {
    const Instruction = struct {
        id: Id,

        pub const Id = enum {
            Import,
            Scope,
            Name,
            Assign,
            Jump,
            Branch,
        };

        pub fn cast(base: *Node, comptime T: type) ?*T {
            if (base.id == comptime typeToId(T)) {
                return @fieldParentPtr(T, "base", base);
            }
            return null;
        }

        pub fn unsafe_cast(base: *Node, comptime T: type) *T {
            return @fieldParentPtr(T, "base", base);
        }

        pub fn iterate(base: *Node, index: usize) ?*Node {
            comptime var i = 0;
            inline while (i < @memberCount(Id)) : (i += 1) {
                if (base.id == @field(Id, @memberName(Id, i))) {
                    const T = @field(Node, @memberName(Id, i));
                    return @fieldParentPtr(T, "base", base).iterate(index);
                }
            }
            unreachable;
        }

        pub fn typeToId(comptime T: type) Id {
            comptime var i = 0;
            inline while (i < @memberCount(Id)) : (i += 1) {
                if (T == @field(Node, @memberName(Id, i))) {
                    return @field(Id, @memberName(Id, i));
                }
            }
            unreachable;
        }
    };

    const Scope = struct {
        allocator: *std.mem.Allocator, 
        parent: ?*Scope = null,
        label: ?*ZigToken = null,
        entry: *Block,
        exit: *Block,

        pub fn init(allocator: *std.mem.Allocator) !Scope {
            const entry = try allocator.create(Block);
            entry.* = Block.init(allocator);
            return Scope{ .allocator = allocator, .entry = entry, .exit = entry };
        }
    };

    const Block = struct {
        instructions: std.ArrayList(*Instruction),

        pub fn init(allocator: *std.mem.Allocator) Block {
            return Block{ .instructions = std.ArrayList(*Instruction).init(allocator) };
        }
    };
};

usingnamespace @import("errors.zig");

pub fn main() !void {
    var allocator = std.heap.c_allocator;

    var args = std.process.args();
    if(!args.skip()) return;

    const filename = if(args.next(allocator)) |arg1| try arg1 else "simple.zig"[0..];

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
    if(parser.root) |root| {
        root.base.dump(0);
    }
}

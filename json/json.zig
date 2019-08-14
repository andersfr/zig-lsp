const std = @import("std");
const warn = std.debug.warn;

const idToString = @import("json_grammar.debug.zig").idToString;
const Lexer = @import("json_lexer.zig").Lexer;
const Types = @import("json_grammar.types.zig");
const Tokens = @import("json_grammar.tokens.zig");
const Actions = @import("json_grammar.actions.zig");
const Transitions = @import("json_grammar.tables.zig");

usingnamespace Tokens;
usingnamespace Actions;
usingnamespace Transitions;

pub usingnamespace Types;

const Parser = struct {
    state: i16 = 0,
    stack: Stack,
    source: []const u8,
    arena_allocator: *std.mem.Allocator,

    pub fn init(allocator: *std.mem.Allocator, arena: *std.mem.Allocator, source: []const u8) Self {
        return Self{ .stack = Stack.init(allocator), .source = source, .arena_allocator = arena };
    }

    pub fn deinit(self: *Self) void {
        self.stack.deinit();
    }

    fn printStack(self: *const Self) void {
        var it = self.stack.iterator();
        while(it.next()) |item| {
            switch(item.value) {
                .Token => |id| { warn("{} ", idToString(id)); },
                .Terminal => |id| { if(item.item != 0) { warn("{} ", terminalIdToString(id)); } },
            }
        }
    }

    pub const Self = @This();

    pub const Stack = std.ArrayList(StackItem);

    pub fn createVariant(self: *Self, comptime T: type) !*T {
        const variant = try self.arena_allocator.create(T);
        variant.base.id = Variant.typeToId(T);
        return variant;
    }

    pub fn createVariantList(self: *Self, comptime T: type) !*T {
        const list = try self.arena_allocator.create(T);
        list.* = T.init(self.arena_allocator);
        return list;
    }

    pub fn tokenString(self: *const Self, token: *Token) []const u8 {
        return self.source[token.start..token.end];
    }

    pub fn unescapeTokenString(self: *const Self, token: *Token) ![]u8 {
        const slice = self.source[token.start..token.end];
        var size = slice.len;
        var i: usize = 0;
        while(i < slice.len) : (i += 1) {
            if(slice[i] == '\\') {
                size -= 1;
                i += 1;
            }
        }
        const result = try self.arena_allocator.alloc(u8, size);
        i = 0;
        var j: usize = 0;
        while(j < slice.len) : (j += 1) {
            if(slice[j] == '\\' or slice[j] == '\"') {
                j += 1;
                result[i] = switch(slice[j]) {
                    't' => '\t',
                    'r' => '\r',
                    'n' => '\n',
                    else => slice[j],
                };
            }
            else {
                result[i] = slice[j];
            }
            i += 1;
        }

        return result;
    }

    pub fn action(self: *Self, token_id: Id, token: *Token) !bool {
        const id = @intCast(i16, @enumToInt(token_id));

        action_loop: while (true) {
            var state: usize = @bitCast(u16, self.state);

            // Shifts
            if (shift_table[state].len > 0) {
                var shift: i16 = 0;
                // Full table
                if (shift_table[state][0] == -1) {
                    shift = shift_table[state][@bitCast(u16, id)];
                }
                // Key-Value pairs
                else {
                    var i: usize = 0;
                    while (i < shift_table[state].len) : (i += 2) {
                        if (shift_table[state][i] == id) {
                            shift = shift_table[state][i + 1];
                            break;
                        }
                    }
                }
                if (shift > 0) {
                    // warn("{} ", idToString(token.id));
                    try self.stack.append(StackItem{ .item = @ptrToInt(token), .state = self.state, .value = StackValue{ .Token = token_id } });
                    self.state = shift;
                    return true;
                }
            }
            // Reduces
            if (reduce_table[state].len > 0) {
                var reduce: i16 = 0;
                // Key-Value pairs and default reduce
                {
                    var i: usize = 0;
                    while (i < reduce_table[state].len) : (i += 2) {
                        if (reduce_table[state][i] == id or reduce_table[state][i] == -1) {
                            reduce = reduce_table[state][i + 1];
                            break;
                        }
                    }
                }
                if (reduce > 0) {
                    const consumes = consumes_table[@bitCast(u16, reduce)];
                    const produces = @enumToInt(try reduce_actions(Self, self, reduce, self.state));
                    state = @bitCast(u16, self.state);

                    // Gotos
                    const goto: i16 = goto_table[goto_index[state]][produces];
                    if (goto > 0) {
                        // if(consumes > 0) {
                        //     warn("\n");
                        //     self.printStack();
                        // }
                        self.state = goto;
                        continue :action_loop;
                    }
                }
            }
            break :action_loop;
        }
        if(self.stack.len == 1 and token_id == .Eof) {
            switch(self.stack.at(0).value) {
                .Terminal => |terminal_id| {
                    if(terminal_id == .Object)
                        return true;
                },
                else => {}
            }
        }

        return false;
    }
};

pub const Json = struct {
    arena: *std.heap.ArenaAllocator,
    allocator: *std.mem.Allocator,
    root: Element = Element{},

    pub const Element = struct {
        value: ?*Variant = null,

        pub fn dump(self: *const Element) void {
            const none = Element{};
            const vv = self.value orelse return;
            vv.dump(0);
        }

        pub fn v(self: *const Element, key: []const u8) Element {
            const none = Element{};
            const vv = self.value orelse return none;
            const vo = vv.cast(Variant.Object) orelse return none;
            const kv = vo.fields.find(key) orelse return none;
            return Element{ .value = kv.value };
        }

        pub fn a(self: *const Element) []*Variant {
            const none = [0]*Variant{};
            const vv = self.value orelse return none;
            const va = vv.cast(Variant.Array) orelse return none;
            return va.elements.items[0..va.elements.len];
        }

        pub fn at(self: *const Element, index: usize) Element {
            const none = Element{};
            const vv = self.value orelse return none;
            const va = vv.cast(Variant.Array) orelse return none;
            return if(va.elements.len > index) Element{ .value = va.elements.items[index] } else none;
        }

        pub fn s(self: *const Element, default: ?[]const u8) ?[]const u8 {
            const vv = self.value orelse return default;
            const vs = vv.cast(Variant.StringLiteral) orelse return default;
            return vs.value;
        }

        pub fn i(self: *const Element, default: ?i64) ?i64 {
            const vv = self.value orelse return default;
            const vi = vv.cast(Variant.IntegerLiteral) orelse return default;
            return vi.value;
        }

        pub fn u(self: *const Element, default: ?u64) ?u64 {
            const vu = self.i(null);
            if(vu) |vv|
                return @bitCast(u64, vv);
            return default;
        }

        pub fn b(self: *const Element, default: ?bool) ?bool {
            const vv = self.value orelse return default;
            const vb = vv.cast(Variant.BoolLiteral) orelse return default;
            return vb.value;
        }

        pub fn isNull(self: *const Element) bool {
            const vv = self.value orelse return false;
            const vn = vv.cast(Variant.NullLiteral) orelse return false;
            return true;
        }
    };

    pub fn init(allocator: *std.mem.Allocator) !Json {
        var arena = try allocator.create(std.heap.ArenaAllocator);
        arena.* = std.heap.ArenaAllocator.init(allocator);
        return Json{ .arena = arena, .allocator = allocator };
    }

    pub fn initWithString(allocator: *std.mem.Allocator, str: []const u8) !?Json {
        var arena = try allocator.create(std.heap.ArenaAllocator);
        arena.* = std.heap.ArenaAllocator.init(allocator);
        errdefer { arena.deinit(); allocator.destroy(arena); }

        const maybe_root = try parse(allocator, &arena.allocator, str);
        if(maybe_root) |root| {
            return Json{ .arena = arena, .allocator = allocator, .root = Element{ .value = &root.base } };
        }
        arena.deinit();
        allocator.destroy(arena);
        return null;
    }

    pub fn deinit(self: *Json) void {
        self.arena.deinit();
        self.allocator.destroy(self.arena);
    }

    fn parse(allocator: *std.mem.Allocator, arena_allocator: *std.mem.Allocator, str: []const u8) !?*Variant.Object {
        var lexer = Lexer.init(str);
        var parser = Parser.init(allocator, arena_allocator, str);
        defer parser.deinit();

        var tokens = std.ArrayList(Token).init(allocator);
        defer tokens.deinit();
        while (true) {
            var token = lexer.next();
            try tokens.append(token);
            if(token.id == .Eof)
                break;
        }
        var i: usize = 0;
        while(i < tokens.len) : (i += 1) {
            const token = &tokens.items[i];

            if(!try parser.action(token.id, token)) {
                // std.debug.warn("\nerror => {}\n", token.id);
                return null;
            }
        }
        if(parser.stack.len == 0)
            return null;

        const root = @intToPtr(?*Variant, parser.stack.at(0).item) orelse return null;

        return root.cast(Variant.Object) orelse null;
    }
};


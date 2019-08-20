const std = @import("std");
const warn = std.debug.warn;

const stack_trace_enabled = false;

fn stack_trace_none(fmt: []const u8, va_args: ...) void {}
const stack_trace = comptime if (stack_trace_enabled) std.debug.warn else stack_trace_none;

const idToString = @import("zig_grammar.debug.zig").idToString;
const Lexer = @import("zig_lexer.zig").Lexer;
const Types = @import("zig_grammar.types.zig");
const Errors = @import("zig_grammar.errors.zig");
const Tokens = @import("zig_grammar.tokens.zig");
const Actions = @import("zig_grammar.actions.zig");
const Transitions = @import("zig_grammar.tables.zig");

const DirectArena = @import("direct_arena.zig").DirectArena;

pub usingnamespace Types;

usingnamespace Errors;
usingnamespace Tokens;
usingnamespace Actions;
usingnamespace Transitions;

const Engine = struct {
    state: i16 = 0,
    stack: Stack,
    allocator: *std.mem.Allocator,
    errors: ErrorList,

    pub fn init(allocator: *std.mem.Allocator, arena_allocator: *std.mem.Allocator) Self {
        return Self{ .stack = Stack.init(allocator), .errors = ErrorList.init(allocator), .allocator = arena_allocator };
    }

    pub fn deinit(self: *Self) void {
        self.errors.deinit();
        self.stack.deinit();
    }

    fn printStack(self: *const Self) void {
        if (stack_trace_enabled) {
            var it = self.stack.iterator();
            while (it.next()) |item| {
                switch (item.value) {
                    .Token => |id| {
                        stack_trace("{} ", idToString(id));
                    },
                    .Terminal => |id| {
                        if (item.item != 0) {
                            stack_trace("{} ", terminalIdToString(id));
                        }
                    },
                }
            }
        }
    }

    const ActionResult = enum {
        Ok,
        Fail,
        IncompleteLine,
    };

    pub const Self = @This();

    pub const Stack = std.ArrayList(StackItem);
    pub const ErrorInfo = struct {
        info: ParseError,
        line: usize,
        start: usize,
        end: usize,
    };
    pub const ErrorList = std.SegmentedList(ErrorInfo, 4);

    pub fn createNode(self: *Self, comptime T: type) !*T {
        const node = try self.allocator.create(T);
        // Allocator memsets to 0xaa but we rely on structs being zero-initialized
        @memset(@ptrCast([*]align(@alignOf(T)) u8, node), 0, @sizeOf(T));
        node.base.id = Node.typeToId(T);
        return node;
    }

    pub fn createRecoveryNode(self: *Self, token: *Token) !*Node {
        const node = try self.allocator.create(Node.Recovery);
        // Allocator memsets to 0xaa but we rely on structs being zero-initialized
        @memset(@ptrCast([*]align(@alignOf(Node.Recovery)) u8, node), 0, @sizeOf(Node.Recovery));
        node.base.id = Node.typeToId(Node.Recovery);
        node.token = token;
        return &node.base;
    }

    pub fn createRecoveryToken(self: *Self, token: *Token) !*Token {
        const recovery_token = try self.allocator.create(Token);
        recovery_token.* = token.*;
        recovery_token.id = .Recovery;
        return recovery_token;
    }

    pub fn createTemporary(self: *Self, comptime T: type) !*T {
        const node = try self.allocator.create(T);
        // Allocator memsets to 0xaa but we rely on structs being zero-initialized
        @memset(@ptrCast([*]align(@alignOf(T)) u8, node), 0, @sizeOf(T));
        return node;
    }

    pub fn createListWithNode(self: *Self, comptime T: type, node: *Node) !*T {
        const list = try self.allocator.create(T);
        list.* = T.init(self.allocator);
        try list.append(node);
        return list;
    }

    pub fn createListWithToken(self: *Self, comptime T: type, token: *Token) !*T {
        const list = try self.allocator.create(T);
        list.* = T.init(self.allocator);
        try list.append(token);
        return list;
    }

    fn earlyDetectUnmatched(self: *Self, open_token_id: Id, close_token_id: Id, token: *Token) bool {
        var ptr = @ptrCast([*]Token, token) + 1;
        var cnt: usize = 1;
        // Check if it gets matched on same line
        while (ptr[0].id != .Eof and ptr[0].id != .Newline and cnt > 0) : (ptr += 1) {
            if (ptr[0].id == open_token_id) cnt += 1;
            if (ptr[0].id == close_token_id) cnt -= 1;
        }
        // Still unmatched
        if (cnt > 0) {
            // Check that more tokens are available
            if (ptr[0].id == .Newline) {
                // Tokens on next line
                if (ptr[1].id != .Newline and ptr[1].id != .Eof) {
                    // If not a closing } assume the line is valid
                    if (ptr[1].id != .RBrace)
                        return false;
                    // Check if under-indented
                    const next_line_offset = ptr[1].start - ptr[0].end;
                    const own_line = @ptrCast([*]Token, token.line);
                    const own_line_offset = own_line[1].start - own_line[0].end;
                    return own_line_offset > next_line_offset;
                }
                // Continue on to line with tokens
                ptr += 1;
                while (ptr[0].id != .Eof and ptr[0].id != .Newline) : (ptr += 1) {}
                // If we reached the end it must be unmatched
                if (ptr[0].id == .Eof)
                    return true;

                // Look at indentation and make a guess
                const next_line_offset = ptr[1].start - ptr[0].end;
                const own_line = @ptrCast([*]Token, token.line);
                const own_line_offset = own_line[1].start - own_line[0].end;
                if (own_line_offset > next_line_offset) {
                    // Indentation must be larger
                    return true;
                }
                if (own_line_offset == next_line_offset) {
                    // Only allow } on same indentation
                    return ptr[1].id != .RBrace;
                }
            }
            return true;
        }
        return false;
    }

    pub fn reportError(self: *Self, parse_error: ParseError, token: *Token) !void {
        const line = token.line.?.start;
        const start_offset = token.start - token.line.?.end + 1;
        const end_offset = token.end - token.line.?.end;
        try self.errors.push(ErrorInfo{ .info = parse_error, .line = line, .start = start_offset, .end = end_offset });
    }

    pub fn reportErrorBackupToken(self: *Self, parse_error: ParseError, token: *Token) !void {
        var ptr = @ptrCast([*]Token, token) - 1;
        while (ptr[0].id == .Newline or ptr[0].id == .LineComment or ptr[0].id == .DocComment) : (ptr -= 1) {}
        try self.reportError(parse_error, &ptr[0]);
    }

    pub fn action(self: *Self, token_id: Id, token: *Token) !ActionResult {
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
                    // Unmatched {, [, ( must be detected early
                    switch (token.id) {
                        .LCurly, .LBrace => {
                            if (self.earlyDetectUnmatched(Id.LBrace, Id.RBrace, token)) {
                                try self.reportError(ParseError.UnmatchedBrace, token);
                                return ActionResult.IncompleteLine;
                            }
                        },
                        .LParen => {
                            if (self.earlyDetectUnmatched(Id.LParen, Id.RParen, token)) {
                                try self.reportError(ParseError.UnmatchedParen, token);
                                return ActionResult.IncompleteLine;
                            }
                        },
                        .LBracket => {
                            if (self.earlyDetectUnmatched(Id.LBracket, Id.RBracket, token)) {
                                try self.reportError(ParseError.UnmatchedBracket, token);
                                return ActionResult.IncompleteLine;
                            }
                        },
                        else => {},
                    }
                    stack_trace("{} ", idToString(token.id));
                    try self.stack.append(StackItem{ .item = @ptrToInt(token), .state = self.state, .value = StackValue{ .Token = token_id } });
                    self.state = shift;
                    return ActionResult.Ok;
                }
            }
            // Reduces
            // if (reduce_table[state].len > 0)
            {
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
                        if (consumes > 0) {
                            stack_trace("\n");
                            self.printStack();
                        }
                        self.state = goto;
                        continue :action_loop;
                    }
                }
            }
            break :action_loop;
        }
        if (self.stack.len == 1 and token_id == .Eof) {
            switch (self.stack.at(0).value) {
                .Terminal => |terminal_id| {
                    if (terminal_id == .Root)
                        return ActionResult.Ok;
                },
                else => {},
            }
        }

        return ActionResult.Fail;
    }

    fn recovery(self: *Self, token_id: Id, token: *Token, index: *usize) !ActionResult {
        const top = self.stack.len - 1;
        const items = self.stack.items;

        switch (items[top].value) {
            .Terminal => |id| {
                // Missing function return type (body block is in return type)
                if (id == .FnProto) {
                    if (@intToPtr(*Node, items[top].item).cast(Node.FnProto)) |proto| {
                        switch (proto.return_type) {
                            .Explicit => |return_type| {
                                if (return_type.id == .Block) {
                                    const lbrace = return_type.unsafe_cast(Node.Block).lbrace;
                                    try self.reportError(ParseError.MissingReturnType, lbrace);
                                    proto.body_node = return_type;
                                    proto.return_type.Explicit = try self.createRecoveryNode(lbrace);
                                    index.* -= 1;
                                    return try self.action(Id.Semicolon, token);
                                }
                            },
                            else => {},
                        }
                    }
                }
                // Missing function return type (no body block)
                else if (id == .MaybeLinkSection and token_id == .Semicolon) {
                    try self.reportError(ParseError.MissingReturnType, token);
                    const recovery_token = try self.createRecoveryToken(token);
                    index.* -= 1;
                    return try self.action(Id.Recovery, recovery_token);
                }
                // Missing semicolon after var decl or a comma
                else if (id == .MaybeEqualExpr) {
                    if (token_id != .Comma) {
                        index.* -= 1;
                    }
                    try self.reportErrorBackupToken(ParseError.MissingSemicolon, token);
                    return try self.action(Id.Semicolon, token);
                }
                // Semicolon after statement
                else if (id == .Statements and token_id == .Semicolon) {
                    try self.reportError(ParseError.SemicolonAfterStatement, token);
                    return ActionResult.Ok;
                }
                // Missing semicolon after AssignExpr
                else if (id == .AssignExpr and token_id != .Semicolon) {
                    if (token_id == .Comma) {
                        try self.reportError(ParseError.CommaExpectedSemicolon, token);
                    } else {
                        try self.reportErrorBackupToken(ParseError.MissingSemicolon, token);
                        index.* -= 1;
                    }
                    return try self.action(Id.Semicolon, token);
                }
                // Missing comma after ContainerField
                else if (id == .ContainerField and token_id == .RBrace) {
                    // try self.reportError(ParseError.MissingComma, token);
                    index.* -= 1;
                    return try self.action(Id.Comma, token);
                }
                // Curly vs Brace confusion
                else if ((id == .IfPrefix or id == .WhilePrefix or id == .ForPrefix) and token_id == .LCurly) {
                    try self.reportError(ParseError.LCurlyExpectedLBrace, token);
                    return try self.action(Id.LBrace, token);
                }
            },
            .Token => |id| {
                if (id == .RParen and self.stack.len >= 4) {
                    switch (items[top - 3].value) {
                        .Terminal => |terminal_id| {},
                        .Token => |loop_id| {
                            // Missing PtrIndexPayload in for loop
                            if (loop_id == .Keyword_for) {
                                try self.reportError(ParseError.MissingPayload, token);
                                const recovery_node = try self.createRecoveryNode(token);
                                try self.stack.append(StackItem{ .item = @ptrToInt(recovery_node), .state = self.state, .value = StackValue{ .Terminal = .PtrIndexPayload } });
                                self.state = goto_table[goto_index[@bitCast(u16, self.state)]][@enumToInt(TerminalId.PtrIndexPayload)];
                                index.* -= 1;
                                return ActionResult.Ok;
                            }
                        },
                    }
                }
            },
        }
        if (token_id == .Semicolon) {
            switch (items[top].value) {
                .Terminal => |id| {
                    // Recovers a{expr; ...} and error{expr; ...}
                    if (id == .MaybeComma) {
                        try self.reportError(ParseError.SemicolonExpectedComma, token);
                        const state = @bitCast(u16, items[top - 1].state);
                        const produces = @enumToInt(items[top - 1].value.Terminal);
                        self.state = goto_table[goto_index[state]][produces];
                        self.stack.len -= 1;
                        return try self.action(Id.Comma, token);
                    }
                    // Recovers after ContainerField;
                    else if (id == .ContainerField) {
                        try self.reportError(ParseError.SemicolonExpectedComma, token);
                        return try self.action(Id.Comma, token);
                    }
                },
                else => {},
            }
        }
        // else if(token_id == .Comma) {
        //     try self.reportError(ParseError.CommaExpectedSemicolon, token);
        //     return try self.action(Id.Semicolon, token);
        // }

        return ActionResult.Fail;
    }

    pub fn resync(self: *Self, token: *Token) bool {
        while (self.stack.popOrNull()) |top| {
            switch (top.value) {
                .Token => |id| {
                    if (id == .LBrace) {
                        // Protect against parse stack corruption
                        if (@intToPtr(*Token, top.item).line.? == token.line.?)
                            return false;
                        self.stack.items[self.stack.len] = top;
                        self.stack.len += 1;
                        return true;
                    }
                },
                .Terminal => |id| {
                    if (id == .Statements or id == .ContainerMembers) {
                        self.stack.items[self.stack.len] = top;
                        self.stack.len += 1;
                        return true;
                    }
                },
            }
            self.state = top.state;
        }
        return false;
    }
};

pub const Parser = struct {
    allocator: *std.mem.Allocator,
    arena: *DirectArena,
    engine: Engine = undefined,
    tokens: std.ArrayList(Token) = undefined,

    pub fn init(allocator: *std.mem.Allocator) !Parser {
        var arena = try DirectArena.init();
        errdefer arena.deinit();

        return Parser{ .allocator = allocator, .arena = arena };
    }

    pub fn deinit(self: *Parser) void {
        self.arena.deinit();
    }

    pub fn run(self: *Parser, buffer: []const u8) !bool {
        self.engine = Engine.init(self.allocator, &self.arena.allocator);
        self.tokens = std.ArrayList(Token).init(self.allocator);

        try self.tokens.ensureCapacity((buffer.len*10)/8);

        var lexer = Lexer.init(buffer);

        try self.tokens.append(Token{ .start = 1, .end = 0, .id = .Newline });
        while (true) {
            var token = lexer.next();
            try self.tokens.append(token);
            if (token.id == .Eof)
                break;
        }
        const shebang = if (self.tokens.items[1].id == .ShebangLine) usize(1) else usize(0);
        var i: usize = shebang + 1;
        // If file starts with a DocComment this is considered a RootComment
        while (i < self.tokens.len) : (i += 1) {
            self.tokens.items[i].id = if (self.tokens.items[i].id == .DocComment) .RootDocComment else break;
        }
        i = shebang+1;
        var line: usize = 1;
        var last_newline = &self.tokens.items[0];
        var resync_progress: usize = 0;
        parser_loop: while (i < self.tokens.len) : (i += 1) {
            const token = &self.tokens.items[i];

            token.line = last_newline;
            if (token.id == .Newline) {
                line += 1;
                token.start = line;
                last_newline = token;
                continue;
            }
            if (token.id == .LineComment) continue;
            if (token.id == .Invalid) {
                try self.engine.reportError(ParseError.InvalidCharacter, token);
                continue;
            }

            var result = try self.engine.action(token.id, token);
            if (result == .Ok)
                continue;

            if (result == .Fail) {
                result = try self.engine.recovery(token.id, token, &i);
                if (result == .Ok)
                    continue;
            }

            // Incomplete line
            stack_trace("\n");
            if (self.engine.resync(token)) {
                // Unmatched already produced a more descriptive error
                if (result == .Fail)
                    try self.engine.reportError(ParseError.DiscardedLine, &self.tokens.items[i]);

                self.engine.printStack();
                while (i < self.tokens.len and self.tokens.items[i].id != .Newline) : (i += 1) {}
                if (resync_progress < i - 1) {
                    i -= 1;
                }
                resync_progress = i;
                continue :parser_loop;
            }

            // Abort parse
            try self.engine.reportError(ParseError.AbortedParse, token);
            break :parser_loop;
        }
        stack_trace("\n");
        if (self.engine.stack.len > 0) {
            const Root = @intToPtr(?*Node.Root, self.engine.stack.at(0).item) orelse return false;
            if(shebang != 0)
                Root.shebang_token = &self.tokens.items[1];
            Root.eof_token = &self.tokens.items[self.tokens.len - 1];
            return true;
        }
        if(self.engine.errors.len > 0 and self.engine.errors.at(self.engine.errors.len-1).info == .AbortedParse)
            return false;

        try self.engine.reportError(ParseError.AbortedParse, &self.tokens.items[i]);
        return false;
    }
};

pub const Token = @import("json_grammar.tokens.zig").Token;
pub const Id = @import("json_grammar.tokens.zig").Id;

pub const Lexer = struct {
    first: usize,
    index: usize,
    source: []const u8,
    char: i32,
    peek: i32,

    const Self = @This();

    pub fn init(source: []const u8) Lexer {
        var peek: i32 = -1;
        if (source.len > 0) {
            peek = source[0];
        }
        return Lexer{
            .first = 0,
            .index = 0,
            .source = source,
            .char = 0,
            .peek = peek,
        };
    }

    // Deal with lookahead and EOF
    fn getc(self: *Self) i32 {
        self.char = self.peek;
        self.index += 1;
        if (self.index < self.source.len) {
            self.peek = self.source[self.index];
        } else {
            self.peek = -1;
        }
        return self.char;
    }

    fn getString(self: *Self) Token {
        _ = self.getc();
        while (true) {
            switch (self.peek) {
                '\n', -1 => {
                    return Token{ .id = .Invalid, .start = self.first+1, .end = self.index-1 };
                },
                '\\' => {
                    _ = self.getc();
                },
                '"' => {
                    _ = self.getc();
                    return Token{ .id = .StringLiteral, .start = self.first+1, .end = self.index-1 };
                },
                else => {},
            }
            _ = self.getc();
        }
    }

    fn getInteger(self: *Self) Token {
        _ = self.getc();
        while (true) {
            switch (self.peek) {
                '0'...'9' => {
                    _ = self.getc();
                },
                else => {
                    return Token{ .id = .IntegerLiteral, .start = self.first, .end = self.index };
                },
            }
        }
    }

    // Get the next token in parse; always ends with Token.Id.Eof
    pub fn next(self: *Self) Token {
        self.first = self.index;

        // Keep parsing until EOF
        while (self.peek != -1) {
            switch(self.peek) {
                '"' => return self.getString(),
                '0'...'9' => return self.getInteger(),
                '-' => {
                    _ = self.getc();
                    if(self.peek >= '1' and self.peek <= '9')
                        return self.getInteger();
                    return Token{ .id = .Invalid, .start = self.first, .end = self.index };
                },
                ' ','\t','\r','\n' => _ = self.getc(),
                '{' => {
                    _ = self.getc();
                    return Token{ .id = .LBrace, .start = self.first, .end = self.index };
                },
                '}' => {
                    _ = self.getc();
                    return Token{ .id = .RBrace, .start = self.first, .end = self.index };
                },
                '[' => {
                    _ = self.getc();
                    return Token{ .id = .LBracket, .start = self.first, .end = self.index };
                },
                ']' => {
                    _ = self.getc();
                    return Token{ .id = .RBracket, .start = self.first, .end = self.index };
                },
                ':' => {
                    _ = self.getc();
                    return Token{ .id = .Colon, .start = self.first, .end = self.index };
                },
                ',' => {
                    _ = self.getc();
                    return Token{ .id = .Comma, .start = self.first, .end = self.index };
                },
                'n' => {
                    _ = self.getc();
                    if('u' != self.getc()) return Token{ .id = .Invalid, .start = self.first, .end = self.index };
                    if('l' != self.getc()) return Token{ .id = .Invalid, .start = self.first, .end = self.index };
                    if('l' != self.getc()) return Token{ .id = .Invalid, .start = self.first, .end = self.index };
                    return Token{ .id = .Keyword_null, .start = self.first, .end = self.index };
                },
                't' => {
                    _ = self.getc();
                    if('r' != self.getc()) return Token{ .id = .Invalid, .start = self.first, .end = self.index };
                    if('u' != self.getc()) return Token{ .id = .Invalid, .start = self.first, .end = self.index };
                    if('e' != self.getc()) return Token{ .id = .Invalid, .start = self.first, .end = self.index };
                    return Token{ .id = .Keyword_true, .start = self.first, .end = self.index };
                },
                'f' => {
                    _ = self.getc();
                    if('a' != self.getc()) return Token{ .id = .Invalid, .start = self.first, .end = self.index };
                    if('l' != self.getc()) return Token{ .id = .Invalid, .start = self.first, .end = self.index };
                    if('s' != self.getc()) return Token{ .id = .Invalid, .start = self.first, .end = self.index };
                    if('e' != self.getc()) return Token{ .id = .Invalid, .start = self.first, .end = self.index };
                    return Token{ .id = .Keyword_false, .start = self.first, .end = self.index };
                },
                else => { 
                    _ = self.getc(); return Token{ .id = .Invalid, .start = self.first, .end = self.index };
                }
            }
        }
        // No more input; return Eof
        return Token{ .id = .Eof, .start = self.first, .end = self.index };
    }
};


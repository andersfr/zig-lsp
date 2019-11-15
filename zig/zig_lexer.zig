const std = @import("std");
const warn = std.debug.warn;

pub usingnamespace @import("zig_grammar.tokens.zig");

const identifier_state = [128]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0 };

pub const Lexer = struct {
    source: []const u8,
    index: usize = 0,
    first: usize = 0,
    peek: i32 = -1,

    pub fn init(source: []const u8) Lexer {
        return Lexer{
            .source = source,
            .peek = if (source.len == 0) @as(i32, -1) else @intCast(i32, source[0]),
        };
    }

    fn getc(self: *Lexer) void {
        self.index += 1;
        self.peek = if (self.index < self.source.len) @intCast(i32, self.source[self.index]) else @as(i32, -1);
    }

    fn getcx(self: *Lexer) i32 {
        @inlineCall(self.getc);
        return self.peek;
    }

    fn identifier(self: *Lexer) Id {
        while (true) {
            const peek: i8 = if (self.peek >= 0) @truncate(i8, self.peek) else return Id.Identifier;
            if (peek < 0 or identifier_state[@bitCast(u8, peek)] == 0) return Id.Identifier;
            self.getc();
        }
    }

    fn identifierOr(self: *Lexer, default: Id) Id {
        const peek: i8 = if (self.peek >= 0) @truncate(i8, self.peek) else return default;
        if (peek < 0 or identifier_state[@bitCast(u8, peek)] == 0) return default;
        self.getc();

        return self.identifier();
    }

    fn comment(self: *Lexer) Id {
        const id = blk: {
            if (self.peek == '/') {
                if (self.getcx() == '/')
                    break :blk Id.LineComment;
                break :blk Id.DocComment;
            }
            break :blk Id.LineComment;
        };
        while (true) {
            switch (self.peek) {
                '\n', -1 => return id,
                else => {},
            }
            self.getc();
        }
    }

    fn hex(self: *Lexer) Id {
        var id = Id.Invalid;
        self.getc();
        while (true) {
            switch (self.peek) {
                '0'...'9', 'a'...'f', 'A'...'F' => {
                    id = Id.IntegerLiteral;
                },
                '.' => {
                    return if (id == Id.Invalid) id else self.float_digits(true);
                },
                else => return id,
            }
            self.getc();
        }
    }

    fn octal(self: *Lexer) Id {
        var id = Id.Invalid;
        self.getc();
        while (true) {
            switch (self.peek) {
                '0'...'7' => {
                    id = Id.IntegerLiteral;
                },
                else => return id,
            }
            self.getc();
        }
    }

    fn binary(self: *Lexer) Id {
        var id = Id.Invalid;
        self.getc();
        while (true) {
            switch (self.peek) {
                '0'...'1' => {
                    id = Id.IntegerLiteral;
                },
                else => return id,
            }
            self.getc();
        }
    }

    fn digits(self: *Lexer) Id {
        while (true) {
            switch (self.peek) {
                '0'...'9' => {},
                '.', 'e' => return self.float_digits(false),
                else => return Id.IntegerLiteral,
            }
            self.getc();
        }
    }

    fn float_digits(self: *Lexer, allow_hex: bool) Id {
        self.getc();
        if (self.peek == '.') {
            self.index -= 1;
            return Id.IntegerLiteral;
        }
        while (true) {
            switch (self.peek) {
                '0'...'9' => {},
                'a'...'f', 'A'...'F' => {
                    if (!allow_hex) return Id.FloatLiteral;
                },
                else => return Id.FloatLiteral,
            }
            self.getc();
        }
    }

    fn linestring(self: *Lexer, id: Id) Id {
        while (true) {
            switch (self.peek) {
                '\n', -1 => return id,
                else => {},
            }
            self.getc();
        }
    }

    fn string(self: *Lexer) Id {
        while (true) {
            switch (self.peek) {
                '\n', -1 => {
                    // TODO: error
                    return Id.StringLiteral;
                },
                '\\' => {
                    _ = self.getc();
                },
                '"' => {
                    _ = self.getc();
                    return Id.StringLiteral;
                },
                else => {},
            }
            _ = self.getc();
        }
    }

    pub fn next(self: *Lexer) Token {
        while (true) {
            self.first = self.index;

            const peek: i8 = if (self.peek >= 0) @truncate(i8, self.peek) else return Token{ .start = self.first, .end = self.index, .id = Id.Eof };
            if (peek < 0) {
                self.getc();
                return Token{ .start = self.first, .end = self.index, .id = Id.Invalid };
            }

            const id = self.nextId(peek);
            if (id != .Ignore)
                return Token{ .start = self.first, .end = self.index, .id = id };
        }
    }

    fn nextId(self: *Lexer, peek: i8) Id {
        _ = self.getc();
        switch (peek) {
            '\n' => {
                return Id.Newline;
            },
            ' ' => {
                while (self.peek == ' ') self.getc();
                return Id.Ignore;
            },
            '!' => {
                if (self.peek == '=') {
                    self.getc();
                    return Id.BangEqual;
                }
                return Id.Bang;
            },
            '"' => {
                return self.string();
            },
            '#' => {
                if (self.index == 1 and self.peek == '!') {
                    while (self.peek != '\n' and self.peek != -1) self.getc();
                    return Id.ShebangLine;
                }
                return Id.Invalid;
            },
            '%' => {
                if (self.peek == '=') {
                    self.getc();
                    return Id.PercentEqual;
                }
                return Id.Percent;
            },
            '&' => {
                if (self.peek == '=') {
                    self.getc();
                    return Id.AmpersandEqual;
                }
                if (self.peek == '&') {
                    self.getc();
                    return Id.AmpersandAmpersand;
                }
                return Id.Ampersand;
            },
            '\'' => {
                while (true) {
                    switch (self.peek) {
                        '\n', -1 => return Id.Invalid,
                        '\\' => {
                            const escape = self.getcx();
                            if (escape == '\n' or escape == -1)
                            // TODO: error
                                return Id.Identifier;
                        },
                        '\'' => {
                            self.getc();
                            return Id.CharLiteral;
                        },
                        else => {},
                    }
                    self.getc();
                }
            },
            '(' => {
                return Id.LParen;
            },
            ')' => {
                return Id.RParen;
            },
            '*' => {
                if (self.peek == '=') {
                    self.getc();
                    return Id.AsteriskEqual;
                }
                if (self.peek == '%') {
                    self.getc();
                    if (self.peek == '=') {
                        self.getc();
                        return Id.AsteriskPercentEqual;
                    }
                    return Id.AsteriskPercent;
                }
                if (self.peek == '*') {
                    self.getc();
                    return Id.AsteriskAsterisk;
                }
                return Id.Asterisk;
            },
            '+' => {
                if (self.peek == '=') {
                    self.getc();
                    return Id.PlusEqual;
                }
                if (self.peek == '%') {
                    self.getc();
                    if (self.peek == '=') {
                        self.getc();
                        return Id.PlusPercentEqual;
                    }
                    return Id.PlusPercent;
                }
                if (self.peek == '+') {
                    self.getc();
                    return Id.PlusPlus;
                }
                return Id.Plus;
            },
            ',' => {
                return Id.Comma;
            },
            '-' => {
                if (self.peek == '=') {
                    self.getc();
                    return Id.MinusEqual;
                }
                if (self.peek == '%') {
                    self.getc();
                    if (self.peek == '=') {
                        self.getc();
                        return Id.MinusPercentEqual;
                    }
                    return Id.MinusPercent;
                }
                if (self.peek == '>') {
                    self.getc();
                    return Id.MinusAngleBracketRight;
                }
                return Id.Minus;
            },
            '.' => {
                if (self.peek == '.') {
                    self.getc();
                    if (self.peek == '.') {
                        self.getc();
                        return Id.Ellipsis3;
                    }
                    return Id.Ellipsis2;
                }
                if (self.peek == '?') {
                    self.getc();
                    return Id.PeriodQuestionMark;
                }
                if (self.peek == '*') {
                    self.getc();
                    return Id.PeriodAsterisk;
                }
                return Id.Period;
            },
            '/' => {
                if (self.peek == '/') {
                    self.getc();
                    return self.comment();
                }
                if (self.peek == '=') {
                    self.getc();
                    return Id.SlashEqual;
                }
                return Id.Slash;
            },
            ':' => {
                return Id.Colon;
            },
            ';' => {
                return Id.Semicolon;
            },
            '<' => {
                if (self.peek == '=') {
                    self.getc();
                    return Id.AngleBracketLeftEqual;
                }
                if (self.peek == '<') {
                    self.getc();
                    if (self.peek == '=') {
                        self.getc();
                        return Id.AngleBracketAngleBracketLeftEqual;
                    }
                    return Id.AngleBracketAngleBracketLeft;
                }
                return Id.AngleBracketLeft;
            },
            '=' => {
                if (self.peek == '=') {
                    self.getc();
                    return Id.EqualEqual;
                }
                if (self.peek == '>') {
                    self.getc();
                    return Id.EqualAngleBracketRight;
                }
                return Id.Equal;
            },
            '>' => {
                if (self.peek == '=') {
                    self.getc();
                    return Id.AngleBracketRightEqual;
                }
                if (self.peek == '>') {
                    self.getc();
                    if (self.peek == '=') {
                        self.getc();
                        return Id.AngleBracketAngleBracketRightEqual;
                    }
                    return Id.AngleBracketAngleBracketRight;
                }
                return Id.AngleBracketRight;
            },
            '?' => {
                return Id.QuestionMark;
            },
            '@' => {
                if (self.peek == '"') {
                    while (true) {
                        switch (self.getcx()) {
                            '\n', -1 => {
                                // TODO: error
                                return Id.Identifier;
                            },
                            '\\' => {
                                const escape = self.getcx();
                                if (escape == '\n' or escape == -1)
                                // TODO: error
                                    return Id.Identifier;
                            },
                            '"' => {
                                self.getc();
                                return Id.Identifier;
                            },
                            else => {},
                        }
                    }
                }
                _ = self.identifier();
                if (self.first + 1 < self.index)
                    return Id.Builtin;
                return Id.Invalid;
            },
            '[' => {
                if (self.peek == '*') {
                    self.getc();
                    if (self.peek == 'c') {
                        self.getc();
                        if (self.peek == ']') {
                            self.getc();
                            return Id.BracketStarCBracket;
                        }
                        self.index -= 2;
                        return Id.LBracket;
                    }
                    if (self.peek == ']') {
                        self.getc();
                        return Id.BracketStarBracket;
                    }
                    self.index -= 1;
                }
                return Id.LBracket;
            },
            '\\' => {
                if (self.peek == '\\') {
                    self.getc();
                    return self.linestring(Id.LineString);
                }
                return Id.Invalid;
            },
            ']' => {
                return Id.RBracket;
            },
            '^' => {
                if (self.peek == '=') {
                    self.getc();
                    return Id.CaretEqual;
                }
                return Id.Caret;
            },
            'a' => {
                //Keyword_and
                if (self.peek == 'n') {
                    if (self.getcx() != 'd') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_and);
                }
                if (self.peek == 's') {
                    self.getc();
                    //Keyword_async
                    if (self.peek == 'y') {
                        if (self.getcx() != 'n') return self.identifier();
                        if (self.getcx() != 'c') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_async);
                    }
                    //Keyword_asm
                    if (self.peek == 'm') {
                        self.getc();
                        return self.identifierOr(Id.Keyword_asm);
                    }
                    return self.identifier();
                }
                if (self.peek == 'l') {
                    self.getc();
                    //Keyword_align
                    if (self.peek == 'i') {
                        if (self.getcx() != 'g') return self.identifier();
                        if (self.getcx() != 'n') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_align);
                    }
                    //Keyword_allowzero
                    if (self.peek == 'l') {
                        if (self.getcx() != 'o') return self.identifier();
                        if (self.getcx() != 'w') return self.identifier();
                        if (self.getcx() != 'z') return self.identifier();
                        if (self.getcx() != 'e') return self.identifier();
                        if (self.getcx() != 'r') return self.identifier();
                        if (self.getcx() != 'o') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_allowzero);
                    }
                    return self.identifier();
                }
                //Keyword_await
                if (self.peek == 'w') {
                    if (self.getcx() != 'a') return self.identifier();
                    if (self.getcx() != 'i') return self.identifier();
                    if (self.getcx() != 't') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_await);
                }
                return self.identifier();
            },
            'b' => {
                //Keyword_break
                if (self.peek != 'r') return self.identifier();
                if (self.getcx() != 'e') return self.identifier();
                if (self.getcx() != 'a') return self.identifier();
                if (self.getcx() != 'k') return self.identifier();
                self.getc();
                return self.identifierOr(Id.Keyword_break);
            },
            'c' => {
                if (self.peek == 'o') {
                    self.getc();
                    if (self.peek == 'n') {
                        self.getc();
                        //Keyword_const
                        if (self.peek == 's') {
                            if (self.getcx() != 't') return self.identifier();
                            self.getc();
                            return self.identifierOr(Id.Keyword_const);
                        }
                        //Keyword_continue
                        if (self.peek == 't') {
                            if (self.getcx() != 'i') return self.identifier();
                            if (self.getcx() != 'n') return self.identifier();
                            if (self.getcx() != 'u') return self.identifier();
                            if (self.getcx() != 'e') return self.identifier();
                            self.getc();
                            return self.identifierOr(Id.Keyword_continue);
                        }
                        return self.identifier();
                    }
                    //Keyword_comptime
                    if (self.peek == 'm') {
                        if (self.getcx() != 'p') return self.identifier();
                        if (self.getcx() != 't') return self.identifier();
                        if (self.getcx() != 'i') return self.identifier();
                        if (self.getcx() != 'm') return self.identifier();
                        if (self.getcx() != 'e') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_comptime);
                    }
                    return self.identifier();
                }
                if (self.peek == 'a') {
                    self.getc();
                    //Keyword_catch
                    if (self.peek == 't') {
                        if (self.getcx() != 'c') return self.identifier();
                        if (self.getcx() != 'h') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_catch);
                    }
                    //Keyword_cancel
                    if (self.peek == 'n') {
                        if (self.getcx() != 'c') return self.identifier();
                        if (self.getcx() != 'e') return self.identifier();
                        if (self.getcx() != 'l') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_cancel);
                    }
                    return self.identifier();
                }
                // CString
                if (self.peek == '"') {
                    self.getc();
                    return self.string();
                }
                // LineCString
                if (self.peek == '\\') {
                    if (self.getcx() != '\\') return Id.Invalid;
                    return self.linestring(Id.LineCString);
                }
                return self.identifier();
            },
            'd' => {
                //Keyword_defer
                if (self.peek != 'e') return self.identifier();
                if (self.getcx() != 'f') return self.identifier();
                if (self.getcx() != 'e') return self.identifier();
                if (self.getcx() != 'r') return self.identifier();
                self.getc();
                return self.identifierOr(Id.Keyword_defer);
            },
            'e' => {
                //Keyword_else
                if (self.peek == 'l') {
                    if (self.getcx() != 's') return self.identifier();
                    if (self.getcx() != 'e') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_else);
                }
                if (self.peek == 'r') {
                    if (self.getcx() != 'r') return self.identifier();
                    self.getc();
                    //Keyword_errdefer
                    if (self.peek == 'd') {
                        if (self.getcx() != 'e') return self.identifier();
                        if (self.getcx() != 'f') return self.identifier();
                        if (self.getcx() != 'e') return self.identifier();
                        if (self.getcx() != 'r') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_errdefer);
                    }
                    //Keyword_error
                    if (self.peek == 'o') {
                        if (self.getcx() != 'r') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_error);
                    }
                    return self.identifier();
                }
                //Keyword_enum
                if (self.peek == 'n') {
                    if (self.getcx() != 'u') return self.identifier();
                    if (self.getcx() != 'm') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_enum);
                }
                if (self.peek == 'x') {
                    self.getc();
                    //Keyword_extern
                    if (self.peek == 't') {
                        if (self.getcx() != 'e') return self.identifier();
                        if (self.getcx() != 'r') return self.identifier();
                        if (self.getcx() != 'n') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_extern);
                    }
                    //Keyword_export
                    if (self.peek == 'p') {
                        if (self.getcx() != 'o') return self.identifier();
                        if (self.getcx() != 'r') return self.identifier();
                        if (self.getcx() != 't') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_export);
                    }
                    return self.identifier();
                }
                return self.identifier();
            },
            'f' => {
                //Keyword_fn
                if (self.peek == 'n') {
                    self.getc();
                    return self.identifierOr(Id.Keyword_fn);
                }
                //Keyword_for
                if (self.peek == 'o') {
                    if (self.getcx() != 'r') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_for);
                }
                //Keyword_false
                if (self.peek == 'a') {
                    if (self.getcx() != 'l') return self.identifier();
                    if (self.getcx() != 's') return self.identifier();
                    if (self.getcx() != 'e') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_false);
                }
                return self.identifier();
            },
            'i' => {
                //Keyword_if
                if (self.peek == 'f') {
                    self.getc();
                    return self.identifierOr(Id.Keyword_if);
                }
                //Keyword_inline
                if (self.peek == 'n') {
                    if (self.getcx() != 'l') return self.identifier();
                    if (self.getcx() != 'i') return self.identifier();
                    if (self.getcx() != 'n') return self.identifier();
                    if (self.getcx() != 'e') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_inline);
                }
                return self.identifier();
            },
            'l' => {
                //Keyword_linksection
                if (self.peek != 'i') return self.identifier();
                if (self.getcx() != 'n') return self.identifier();
                if (self.getcx() != 'k') return self.identifier();
                if (self.getcx() != 's') return self.identifier();
                if (self.getcx() != 'e') return self.identifier();
                if (self.getcx() != 'c') return self.identifier();
                if (self.getcx() != 't') return self.identifier();
                if (self.getcx() != 'i') return self.identifier();
                if (self.getcx() != 'o') return self.identifier();
                if (self.getcx() != 'n') return self.identifier();
                self.getc();
                return self.identifierOr(Id.Keyword_linksection);
            },
            'n' => {
                //Keyword_null
                if (self.peek == 'u') {
                    if (self.getcx() != 'l') return self.identifier();
                    if (self.getcx() != 'l') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_null);
                }
                //Keyword_noalias
                if (self.peek == 'o') {
                    if (self.getcx() != 'a') return self.identifier();
                    if (self.getcx() != 'l') return self.identifier();
                    if (self.getcx() != 'i') return self.identifier();
                    if (self.getcx() != 'a') return self.identifier();
                    if (self.getcx() != 's') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_noalias);
                }
                //Keyword_nakedcc
                if (self.peek == 'a') {
                    if (self.getcx() != 'k') return self.identifier();
                    if (self.getcx() != 'e') return self.identifier();
                    if (self.getcx() != 'd') return self.identifier();
                    if (self.getcx() != 'c') return self.identifier();
                    if (self.getcx() != 'c') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_nakedcc);
                }
                return self.identifier();
            },
            'o' => {
                if (self.peek != 'r') return self.identifier();
                //Keyword_or
                if (self.getcx() != 'e') return self.identifierOr(Id.Keyword_or);
                //Keyword_orelse
                if (self.getcx() != 'l') return self.identifier();
                if (self.getcx() != 's') return self.identifier();
                if (self.getcx() != 'e') return self.identifier();
                self.getc();
                return self.identifierOr(Id.Keyword_orelse);
            },
            'p' => {
                //Keyword_pub
                if (self.peek == 'u') {
                    if (self.getcx() != 'b') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_pub);
                }
                //Keyword_packed
                if (self.peek == 'a') {
                    if (self.getcx() != 'c') return self.identifier();
                    if (self.getcx() != 'k') return self.identifier();
                    if (self.getcx() != 'e') return self.identifier();
                    if (self.getcx() != 'd') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_packed);
                }
                //Keyword_promise
                if (self.peek == 'r') {
                    if (self.getcx() != 'o') return self.identifier();
                    if (self.getcx() != 'm') return self.identifier();
                    if (self.getcx() != 'i') return self.identifier();
                    if (self.getcx() != 's') return self.identifier();
                    if (self.getcx() != 'e') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_promise);
                }
                return self.identifier();
            },
            'r' => {
                if (self.peek != 'e') return self.identifier();
                self.getc();
                //Keyword_return
                if (self.peek == 't') {
                    if (self.getcx() != 'u') return self.identifier();
                    if (self.getcx() != 'r') return self.identifier();
                    if (self.getcx() != 'n') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_return);
                }
                //Keyword_resume
                if (self.peek == 's') {
                    if (self.getcx() != 'u') return self.identifier();
                    if (self.getcx() != 'm') return self.identifier();
                    if (self.getcx() != 'e') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_resume);
                }
                return self.identifier();
            },
            's' => {
                if (self.peek == 't') {
                    self.getc();
                    //Keyword_struct
                    if (self.peek == 'r') {
                        if (self.getcx() != 'u') return self.identifier();
                        if (self.getcx() != 'c') return self.identifier();
                        if (self.getcx() != 't') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_struct);
                    }
                    //Keyword_stdcallcc
                    if (self.peek == 'd') {
                        if (self.getcx() != 'c') return self.identifier();
                        if (self.getcx() != 'a') return self.identifier();
                        if (self.getcx() != 'l') return self.identifier();
                        if (self.getcx() != 'l') return self.identifier();
                        if (self.getcx() != 'c') return self.identifier();
                        if (self.getcx() != 'c') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_stdcallcc);
                    }
                    return self.identifier();
                }
                //Keyword_switch
                if (self.peek == 'w') {
                    if (self.getcx() != 'i') return self.identifier();
                    if (self.getcx() != 't') return self.identifier();
                    if (self.getcx() != 'c') return self.identifier();
                    if (self.getcx() != 'h') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_switch);
                }
                //Keyword_suspend
                if (self.peek == 'u') {
                    if (self.getcx() != 's') return self.identifier();
                    if (self.getcx() != 'p') return self.identifier();
                    if (self.getcx() != 'e') return self.identifier();
                    if (self.getcx() != 'n') return self.identifier();
                    if (self.getcx() != 'd') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_suspend);
                }
                return self.identifier();
            },
            't' => {
                if (self.peek == 'r') {
                    self.getc();
                    //Keyword_try
                    if (self.peek == 'y') {
                        self.getc();
                        return self.identifierOr(Id.Keyword_try);
                    }
                    //Keyword_true
                    if (self.peek == 'u') {
                        if (self.getcx() != 'e') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_true);
                    }
                    return self.identifier();
                }
                //Keyword_test
                if (self.peek == 'e') {
                    if (self.getcx() != 's') return self.identifier();
                    if (self.getcx() != 't') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_test);
                }
                //Keyword_threadlocal
                if (self.peek == 'h') {
                    if (self.getcx() != 'r') return self.identifier();
                    if (self.getcx() != 'e') return self.identifier();
                    if (self.getcx() != 'a') return self.identifier();
                    if (self.getcx() != 'd') return self.identifier();
                    if (self.getcx() != 'l') return self.identifier();
                    if (self.getcx() != 'o') return self.identifier();
                    if (self.getcx() != 'c') return self.identifier();
                    if (self.getcx() != 'a') return self.identifier();
                    if (self.getcx() != 'l') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_threadlocal);
                }
                return self.identifier();
            },
            'u' => {
                if (self.peek == 's') {
                    self.getc();
                    //Keyword_use
                    if (self.peek == 'e') {
                        self.getc();
                        return self.identifierOr(Id.Keyword_use);
                    }
                    //Keyword_usingnamespace
                    if (self.peek != 'i') return self.identifier();
                    if (self.getcx() != 'n') return self.identifier();
                    if (self.getcx() != 'g') return self.identifier();
                    if (self.getcx() != 'n') return self.identifier();
                    if (self.getcx() != 'a') return self.identifier();
                    if (self.getcx() != 'm') return self.identifier();
                    if (self.getcx() != 'e') return self.identifier();
                    if (self.getcx() != 's') return self.identifier();
                    if (self.getcx() != 'p') return self.identifier();
                    if (self.getcx() != 'a') return self.identifier();
                    if (self.getcx() != 'c') return self.identifier();
                    if (self.getcx() != 'e') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_usingnamespace);
                }
                if (self.peek == 'n') {
                    self.getc();
                    //Keyword_union
                    if (self.peek == 'i') {
                        if (self.getcx() != 'o') return self.identifier();
                        if (self.getcx() != 'n') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_union);
                    }
                    //Keyword_undefined
                    if (self.peek == 'd') {
                        if (self.getcx() != 'e') return self.identifier();
                        if (self.getcx() != 'f') return self.identifier();
                        if (self.getcx() != 'i') return self.identifier();
                        if (self.getcx() != 'n') return self.identifier();
                        if (self.getcx() != 'e') return self.identifier();
                        if (self.getcx() != 'd') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_undefined);
                    }
                    //Keyword_unreachable
                    if (self.peek == 'r') {
                        if (self.getcx() != 'e') return self.identifier();
                        if (self.getcx() != 'a') return self.identifier();
                        if (self.getcx() != 'c') return self.identifier();
                        if (self.getcx() != 'h') return self.identifier();
                        if (self.getcx() != 'a') return self.identifier();
                        if (self.getcx() != 'b') return self.identifier();
                        if (self.getcx() != 'l') return self.identifier();
                        if (self.getcx() != 'e') return self.identifier();
                        self.getc();
                        return self.identifierOr(Id.Keyword_unreachable);
                    }
                }
            },
            'v' => {
                //Keyword_var
                if (self.peek == 'a') {
                    if (self.getcx() != 'r') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_var);
                }
                //Keyword_volatile
                if (self.peek == 'o') {
                    if (self.getcx() != 'l') return self.identifier();
                    if (self.getcx() != 'a') return self.identifier();
                    if (self.getcx() != 't') return self.identifier();
                    if (self.getcx() != 'i') return self.identifier();
                    if (self.getcx() != 'l') return self.identifier();
                    if (self.getcx() != 'e') return self.identifier();
                    self.getc();
                    return self.identifierOr(Id.Keyword_volatile);
                }
                return self.identifier();
            },
            'w' => {
                //Keyword_while
                if (self.peek != 'h') return self.identifier();
                if (self.getcx() != 'i') return self.identifier();
                if (self.getcx() != 'l') return self.identifier();
                if (self.getcx() != 'e') return self.identifier();
                self.getc();
                return self.identifierOr(Id.Keyword_while);
            },
            '{' => {
                if (self.index == 1)
                    return Id.LBrace;

                switch (self.source[self.index - 2]) {
                    '(', ':', ' ', '\t', '\r', '\n' => return Id.LBrace,
                    else => return Id.LCurly,
                }
            },
            '|' => {
                if (self.peek == '=') {
                    self.getc();
                    return Id.PipeEqual;
                }
                if (self.peek == '|') {
                    self.getc();
                    return Id.PipePipe;
                }
                return Id.Pipe;
            },
            '}' => {
                return Id.RBrace;
            },
            '~' => {
                return Id.Tilde;
            },
            '0' => {
                if (self.peek == 'x') return self.hex();
                if (self.peek == 'o') return self.octal();
                if (self.peek == 'b') return self.binary();
                return self.digits();
            },
            '1'...'9' => {
                return self.digits();
            },
            else => {},
        }
        if (identifier_state[@bitCast(u8, peek)] == 1)
            return self.identifier();
        return Id.Invalid;
    }
};

pub fn main() void {
    var lexer = Lexer.init("while(true) { var @vv; volatile; }");
    while (true) {
        const token = lexer.next();
        warn("{}\n", token);
        if (token.id == .Eof)
            break;
    }
}

test "zig_lexer.zig" {
    _ = @import("zig_lexer.test.zig");
}

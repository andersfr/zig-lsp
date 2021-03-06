// AutoGenerated file

pub const Token = struct {
    id: Id,
    start: usize,
    end: usize,
    line: ?*@This() = null,
};

pub const Id = enum(u8) {
    Invalid = 0,
    Eof = 1,
    IntegerLiteral = 12,
    StringLiteral = 4,
    RBrace = 3,
    RBracket = 8,
    Keyword_null = 9,
    Keyword_false = 11,
    Colon = 5,
    LBrace = 2,
    Keyword_true = 10,
    LBracket = 7,
    Comma = 6,
    ShebangLine = 13,
    LineComment = 14,
    Newline = 15,
    Ignore = 16,
};

pub const TerminalId = enum(u8) {
    Accept = 0,
    Object = 1,
    MaybeFields = 2,
    Array = 4,
    MaybeElements = 5,
    Fields = 3,
    Element = 7,
    Elements = 6,
};

pub fn terminalIdToString(id: TerminalId) []const u8 {
    switch (id) {
        .Accept => return "$accept",
        .Object => return "Object",
        .MaybeFields => return "Fields?",
        .Array => return "Array",
        .MaybeElements => return "Elements?",
        .Fields => return "Fields",
        .Element => return "Element",
        .Elements => return "Elements",
    }
}

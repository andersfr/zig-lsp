usingnamespace @import("zig/zig_grammar.errors.zig");

pub fn parseErrorToString(err: ParseError) []const u8 {
    return switch(err) {
        .InvalidCharacter => "Invalid character",
        .MissingReturnType => "Missing return type for function",
        .MissingSemicolon => "Missing semicolon",
        .MissingComma => "Missing comma",
        .MissingPayload => "For statement must have a |payload|",
        .SemicolonAfterStatement => "Semicolon not allowed after this statement",
        .SemicolonExpectedComma => "Expected , found ;",
        .ColonExpectedEqual => "Expected = found :",
        .CommaExpectedSemicolon => "Expected , found ;",
        .UnmatchedBrace => "Unmatched {",
        .UnmatchedBracket => "Unmatched [",
        .UnmatchedParen => "Unmatched (",
        .DiscardedLine => "Line discarded from parse (unrecoverable error)",
        .LCurlyExpectedLBrace => "Expected block found curly suffix initializer",
        .DetachedAsync => "Async not attached to function call",
        .AbortedParse => "Parse aborted due to previous errors",
    };
}

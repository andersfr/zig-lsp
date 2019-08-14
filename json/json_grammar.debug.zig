const Id = @import("json_grammar.tokens.zig").Id;

pub fn idToString(id: Id) []const u8 {
    switch(id) {
        .Comma                              => return ",",
        .Colon                              => return ":",
        .LBrace                             => return "{",
        .LBracket                           => return "[",
        .RBrace                             => return "}",
        .RBracket                           => return "]",
        .Keyword_false                      => return "false",
        .Keyword_true                       => return "true",
        .Keyword_null                       => return "null",

        .Invalid                            => return "$invalid",
        .Eof                                => return "$eof",
        .Newline                            => return "$newline",
        .Ignore                             => return "$ignore",
        .ShebangLine                        => return "#!",
        .LineComment                        => return "//",
        .StringLiteral                      => return "StringLiteral",
        .IntegerLiteral                     => return "IntegerLiteral",
    }
}

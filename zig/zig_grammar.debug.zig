const Id = @import("zig_grammar.tokens.zig").Id;

pub fn idToString(id: Id) []const u8 {
    switch(id) {
        .Builtin                            => return "@builtin",
        .Ampersand                          => return "&",
        .AmpersandEqual                     => return "&=",
        .Asterisk                           => return "*",
        .AsteriskAsterisk                   => return "**",
        .AsteriskEqual                      => return "*=",
        .AsteriskPercent                    => return "*%",
        .AsteriskPercentEqual               => return "*%=",
        .Caret                              => return "^",
        .CaretEqual                         => return "^=",
        .Colon                              => return ":",
        .Comma                              => return ",",
        .Period                             => return ".",
        .PeriodAsterisk                     => return ".*",
        .PeriodQuestionMark                 => return ".?",
        .Ellipsis2                          => return "..",
        .Ellipsis3                          => return "...",
        .Equal                              => return "=",
        .EqualEqual                         => return "==",
        .EqualAngleBracketRight             => return "=>",
        .Bang                               => return "!",
        .BangEqual                          => return "!=",
        .AngleBracketLeft                   => return "<",
        .AngleBracketAngleBracketLeft       => return "<<",
        .AngleBracketAngleBracketLeftEqual  => return "<<=",
        .AngleBracketLeftEqual              => return "<=",
        .LCurly                             => return "{",
        .LBrace                             => return "{",
        .LBracket                           => return "[",
        .LParen                             => return "(",
        .Minus                              => return "-",
        .MinusEqual                         => return "-=",
        .MinusAngleBracketRight             => return "->",
        .MinusPercent                       => return "-%",
        .MinusPercentEqual                  => return "-%=",
        .Percent                            => return "%",
        .PercentEqual                       => return "%=",
        .Pipe                               => return "|",
        .PipePipe                           => return "||",
        .PipeEqual                          => return "|=",
        .Plus                               => return "+",
        .PlusPlus                           => return "++",
        .PlusEqual                          => return "+=",
        .PlusPercent                        => return "+%",
        .PlusPercentEqual                   => return "+%=",
        .BracketStarCBracket                => return "[*c]",
        .BracketStarBracket                 => return "[*]",
        .QuestionMark                       => return "?",
        .AngleBracketRight                  => return ">",
        .AngleBracketAngleBracketRight      => return ">>",
        .AngleBracketAngleBracketRightEqual => return ">>=",
        .AngleBracketRightEqual             => return ">=",
        .RBrace                             => return "}",
        .RBracket                           => return "]",
        .RParen                             => return ")",
        .Semicolon                          => return ";",
        .Slash                              => return "/",
        .SlashEqual                         => return "/=",
        .Tilde                              => return "~",
        .Keyword_align                      => return "align",
        .Keyword_allowzero                  => return "allowzero",
        .Keyword_and                        => return "and",
        .Keyword_asm                        => return "asm",
        .Keyword_async                      => return "async",
        .Keyword_await                      => return "await",
        .Keyword_break                      => return "break",
        .Keyword_catch                      => return "catch",
        .Keyword_cancel                     => return "cancel",
        .Keyword_comptime                   => return "comptime",
        .Keyword_const                      => return "const",
        .Keyword_continue                   => return "continue",
        .Keyword_defer                      => return "defer",
        .Keyword_else                       => return "else",
        .Keyword_enum                       => return "enum",
        .Keyword_errdefer                   => return "errdefer",
        .Keyword_error                      => return "error",
        .Keyword_export                     => return "export",
        .Keyword_extern                     => return "extern",
        .Keyword_false                      => return "false",
        .Keyword_fn                         => return "fn",
        .Keyword_for                        => return "for",
        .Keyword_if                         => return "if",
        .Keyword_inline                     => return "inline",
        .Keyword_nakedcc                    => return "nakedcc",
        .Keyword_noalias                    => return "noalias",
        .Keyword_null                       => return "null",
        .Keyword_or                         => return "or",
        .Keyword_orelse                     => return "orelse",
        .Keyword_packed                     => return "packed",
        .Keyword_promise                    => return "promise",
        .Keyword_pub                        => return "pub",
        .Keyword_resume                     => return "resume",
        .Keyword_return                     => return "return",
        .Keyword_linksection                => return "linksection",
        .Keyword_stdcallcc                  => return "stdcallcc",
        .Keyword_struct                     => return "struct",
        .Keyword_suspend                    => return "suspend",
        .Keyword_switch                     => return "switch",
        .Keyword_test                       => return "test",
        .Keyword_threadlocal                => return "threadlocal",
        .Keyword_true                       => return "true",
        .Keyword_try                        => return "try",
        .Keyword_undefined                  => return "undefined",
        .Keyword_union                      => return "union",
        .Keyword_unreachable                => return "unreachable",
        .Keyword_use                        => return "use",
        .Keyword_usingnamespace             => return "usingnamespace",
        .Keyword_var                        => return "var",
        .Keyword_volatile                   => return "volatile",
        .Keyword_while                      => return "while",

        .Invalid                            => return "$invalid",
        .Eof                                => return "$eof",
        .Newline                            => return "$newline",
        .Ignore                             => return "$ignore",
        .ShebangLine                        => return "#!",
        .LineComment                        => return "//",
        .DocComment                         => return "///",
        .RootDocComment                     => return "///",
        .LineString                         => return "\\",
        .LineCString                        => return "c\\",

        .Identifier                         => return "Identifier",
        .CharLiteral                        => return "CharLiteral",
        .StringLiteral                      => return "StringLiteral",
        .IntegerLiteral                     => return "IntegerLiteral",
        .FloatLiteral                       => return "FloatLiteral",

        .Recovery                           => return "$error",
        //else => unreachable,
    }
}
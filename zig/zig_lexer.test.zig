const std = @import("std");
const testing = std.testing;

const lexer = @import("zig_lexer.zig");
const Token = lexer.Token;
const Lexer = lexer.Lexer;
const Id = lexer.Id;

test "\\n" {
    testToken("\n", .Newline);
}
test "&" {
    testToken("&", .Ampersand);
}
test "&=" {
    testToken("&=", .AmpersandEqual);
}
test "*" {
    testToken("*", .Asterisk);
}
test "**" {
    testToken("**", .AsteriskAsterisk);
}
test "*=" {
    testToken("*=", .AsteriskEqual);
}
test "*%" {
    testToken("*%", .AsteriskPercent);
}
test "*%=" {
    testToken("*%=", .AsteriskPercentEqual);
}
test "^" {
    testToken("^", .Caret);
}
test "^=" {
    testToken("^=", .CaretEqual);
}
test ":" {
    testToken(":", .Colon);
}
test "," {
    testToken(",", .Comma);
}
test "." {
    testToken(".", .Period);
}
test ".." {
    testToken("..", .Ellipsis2);
}
test "..." {
    testToken("...", .Ellipsis3);
}
test "=" {
    testToken("=", .Equal);
}
test "==" {
    testToken("==", .EqualEqual);
}
test "=>" {
    testToken("=>", .EqualAngleBracketRight);
}
test "!" {
    testToken("!", .Bang);
}
test "!=" {
    testToken("!=", .BangEqual);
}
test "<" {
    testToken("<", .AngleBracketLeft);
}
test "<<" {
    testToken("<<", .AngleBracketAngleBracketLeft);
}
test "<<=" {
    testToken("<<=", .AngleBracketAngleBracketLeftEqual);
}
test "<=" {
    testToken("<=", .AngleBracketLeftEqual);
}
test "{" {
    testToken("{", .LBrace);
}
test "[" {
    testToken("[", .LBracket);
}
test "(" {
    testToken("(", .LParen);
}
test "-" {
    testToken("-", .Minus);
}
test "-=" {
    testToken("-=", .MinusEqual);
}
test "->" {
    testToken("->", .MinusAngleBracketRight);
}
test "-%" {
    testToken("-%", .MinusPercent);
}
test "-%=" {
    testToken("-%=", .MinusPercentEqual);
}
test "%" {
    testToken("%", .Percent);
}
test "%=" {
    testToken("%=", .PercentEqual);
}
test "|" {
    testToken("|", .Pipe);
}
test "||" {
    testToken("||", .PipePipe);
}
test "|=" {
    testToken("|=", .PipeEqual);
}
test "+" {
    testToken("+", .Plus);
}
test "++" {
    testToken("++", .PlusPlus);
}
test "+=" {
    testToken("+=", .PlusEqual);
}
test "+%" {
    testToken("+%", .PlusPercent);
}
test "+%=" {
    testToken("+%=", .PlusPercentEqual);
}
test "[*c]" {
    testToken("[*c]", .BracketStarCBracket);
}
test "[*]" {
    testToken("[*]", .BracketStarBracket);
}
test "?" {
    testToken("?", .QuestionMark);
}
test ">" {
    testToken(">", .AngleBracketRight);
}
test ">>" {
    testToken(">>", .AngleBracketAngleBracketRight);
}
test ">>=" {
    testToken(">>=", .AngleBracketAngleBracketRightEqual);
}
test ">=" {
    testToken(">=", .AngleBracketRightEqual);
}
test "}" {
    testToken("}", .RBrace);
}
test "]" {
    testToken("]", .RBracket);
}
test ")" {
    testToken(")", .RParen);
}
test ";" {
    testToken(";", .Semicolon);
}
test "/" {
    testToken("/", .Slash);
}
test "/=" {
    testToken("/=", .SlashEqual);
}
test "~" {
    testToken("~", .Tilde);
}
test "align" {
    testToken("align", .Keyword_align);
}
test "allowzero" {
    testToken("allowzero", .Keyword_allowzero);
}
test "and" {
    testToken("and", .Keyword_and);
}
test "asm" {
    testToken("asm", .Keyword_asm);
}
test "async" {
    testToken("async", .Keyword_async);
}
test "await" {
    testToken("await", .Keyword_await);
}
test "break" {
    testToken("break", .Keyword_break);
}
test "catch" {
    testToken("catch", .Keyword_catch);
}
test "cancel" {
    testToken("cancel", .Keyword_cancel);
}
test "comptime" {
    testToken("comptime", .Keyword_comptime);
}
test "const" {
    testToken("const", .Keyword_const);
}
test "continue" {
    testToken("continue", .Keyword_continue);
}
test "defer" {
    testToken("defer", .Keyword_defer);
}
test "else" {
    testToken("else", .Keyword_else);
}
test "enum" {
    testToken("enum", .Keyword_enum);
}
test "errdefer" {
    testToken("errdefer", .Keyword_errdefer);
}
test "error" {
    testToken("error", .Keyword_error);
}
test "export" {
    testToken("export", .Keyword_export);
}
test "extern" {
    testToken("extern", .Keyword_extern);
}
test "false" {
    testToken("false", .Keyword_false);
}
test "fn" {
    testToken("fn", .Keyword_fn);
}
test "for" {
    testToken("for", .Keyword_for);
}
test "if" {
    testToken("if", .Keyword_if);
}
test "inline" {
    testToken("inline", .Keyword_inline);
}
test "nakedcc" {
    testToken("nakedcc", .Keyword_nakedcc);
}
test "noalias" {
    testToken("noalias", .Keyword_noalias);
}
test "null" {
    testToken("null", .Keyword_null);
}
test "or" {
    testToken("or", .Keyword_or);
}
test "orelse" {
    testToken("orelse", .Keyword_orelse);
}
test "packed" {
    testToken("packed", .Keyword_packed);
}
test "promise" {
    testToken("promise", .Keyword_promise);
}
test "pub" {
    testToken("pub", .Keyword_pub);
}
test "resume" {
    testToken("resume", .Keyword_resume);
}
test "return" {
    testToken("return", .Keyword_return);
}
test "linksection" {
    testToken("linksection", .Keyword_linksection);
}
test "stdcallcc" {
    testToken("stdcallcc", .Keyword_stdcallcc);
}
test "struct" {
    testToken("struct", .Keyword_struct);
}
test "suspend" {
    testToken("suspend", .Keyword_suspend);
}
test "switch" {
    testToken("switch", .Keyword_switch);
}
test "test" {
    testToken("test", .Keyword_test);
}
test "threadlocal" {
    testToken("threadlocal", .Keyword_threadlocal);
}
test "true" {
    testToken("true", .Keyword_true);
}
test "try" {
    testToken("try", .Keyword_try);
}
test "undefined" {
    testToken("undefined", .Keyword_undefined);
}
test "union" {
    testToken("union", .Keyword_union);
}
test "unreachable" {
    testToken("unreachable", .Keyword_unreachable);
}
test "use" {
    testToken("use", .Keyword_use);
}
test "var" {
    testToken("var", .Keyword_var);
}
test "volatile" {
    testToken("volatile", .Keyword_volatile);
}
test "while" {
    testToken("while", .Keyword_while);
}
test "//" {
    testToken("//", .LineComment);
}
test "///" {
    testToken("///", .DocComment);
}
test "////" {
    testToken("////", .LineComment);
}
test "@builtin" {
    testTokens("@builtin", [_]Id{.Builtin, .Identifier});
}
test "@\"identifier\"" {
    testToken("@\"identifier\"", .Identifier);
}
test "#!/usr/bin/env zig" {
    testToken("#!/usr/bin/env zig", .ShebangLine);
}
test "#0" {
    testTokens("#0", [_]Id{ .Invalid, .IntegerLiteral });
}
test "+++" {
    testTokens("+++", [_]Id{ .PlusPlus, .Plus });
}
test "0b2" {
    testTokens("0b2", [_]Id{ .IntegerLiteral, .Identifier });
}
test "0o8" {
    testTokens("0o8", [_]Id{ .IntegerLiteral, .Identifier });
}
test "[0..]" {
    testTokens("[0..]", [_]Id{ .LBracket, .IntegerLiteral, .Ellipsis2, .RBracket });
}

fn testToken(buffer: []const u8, id: Id) void {
    var lex = Lexer.init(buffer);
    var token = lex.next();
    testing.expectEqual(id, token.id);
    token = lex.next();
    testing.expectEqual(Id.Eof, token.id);
}

fn testTokens(buffer: []const u8, ids: []const Id) void {
    var lex = Lexer.init(buffer);
    var token = lex.next();
    for (ids) |id| {
        testing.expectEqual(id, token.id);
        token = lex.next();
    }
    testing.expectEqual(Id.Eof, token.id);
}

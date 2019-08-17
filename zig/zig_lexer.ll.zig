// %missing Ignore
// %missing ShebangLine
// %missing Eof

// %token Newline                            %dfa \n

// %token Ampersand                          %dfa &
// %token AmpersandAmpersand                 %dfa &&
// %token AmpersandEqual                     %dfa &=
// %token Asterisk                           %dfa \*
// %token AsteriskAsterisk                   %dfa \*\*
// %token AsteriskEqual                      %dfa \*=
// %token AsteriskPercent                    %dfa \*%
// %token AsteriskPercentEqual               %dfa \*%=
// %token Caret                              %dfa ^
// %token CaretEqual                         %dfa ^=
// %token Colon                              %dfa :
// %token Comma                              %dfa ,
// %token Period                             %dfa \.
// %token PeriodAsterisk                     %dfa \.\*
// %token PeriodQuestionMark                 %dfa \.\?
// %token Ellipsis2                          %dfa \.\.
// %token Ellipsis3                          %dfa \.\.\.
// %token Equal                              %dfa =
// %token EqualEqual                         %dfa ==
// %token EqualAngleBracketRight             %dfa =>
// %token Bang                               %dfa !
// %token BangEqual                          %dfa !=
// %token AngleBracketLeft                   %dfa <
// %token AngleBracketAngleBracketLeft       %dfa <<
// %token AngleBracketAngleBracketLeftEqual  %dfa <<=
// %token AngleBracketLeftEqual              %dfa <=
// %token LBracket                           %dfa \[
// %token LParen                             %dfa \(
// %token Minus                              %dfa -
// %token MinusEqual                         %dfa -=
// %token MinusAngleBracketRight             %dfa ->
// %token MinusPercent                       %dfa -%
// %token MinusPercentEqual                  %dfa -%=
// %token Percent                            %dfa %
// %token PercentEqual                       %dfa %=
// %token Pipe                               %dfa \|
// %token PipePipe                           %dfa \|\|
// %token PipeEqual                          %dfa \|=
// %token Plus                               %dfa \+
// %token PlusPlus                           %dfa \+\+
// %token PlusEqual                          %dfa \+=
// %token PlusPercent                        %dfa \+%
// %token PlusPercentEqual                   %dfa \+%=
// %token BracketStarCBracket                %dfa \[\*c\]
// %token BracketStarBracket                 %dfa \[\*\]
// %token QuestionMark                       %dfa \?
// %token AngleBracketRight                  %dfa >
// %token AngleBracketAngleBracketRight      %dfa >>
// %token AngleBracketAngleBracketRightEqual %dfa >>=
// %token AngleBracketRightEqual             %dfa >=
// %token RBrace                             %dfa }
// %token RBracket                           %dfa \]
// %token RParen                             %dfa \)
// %token Semicolon                          %dfa ;
// %token Slash                              %dfa /
// %token SlashEqual                         %dfa /=
// %token Tilde                              %dfa ~

// %token Keyword_align                      %dfa align
// %token Keyword_allowzero                  %dfa allowzero
// %token Keyword_and                        %dfa and
// %token Keyword_asm                        %dfa asm
// %token Keyword_async                      %dfa async
// %token Keyword_await                      %dfa await
// %token Keyword_break                      %dfa break
// %token Keyword_catch                      %dfa catch
// %token Keyword_cancel                     %dfa cancel
// %token Keyword_comptime                   %dfa comptime
// %token Keyword_const                      %dfa const
// %token Keyword_continue                   %dfa continue
// %token Keyword_defer                      %dfa defer
// %token Keyword_else                       %dfa else
// %token Keyword_enum                       %dfa enum
// %token Keyword_errdefer                   %dfa errdefer
// %token Keyword_error                      %dfa error
// %token Keyword_export                     %dfa export
// %token Keyword_extern                     %dfa extern
// %token Keyword_false                      %dfa false
// %token Keyword_fn                         %dfa fn
// %token Keyword_for                        %dfa for
// %token Keyword_if                         %dfa if
// %token Keyword_inline                     %dfa inline
// %token Keyword_nakedcc                    %dfa nakedcc
// %token Keyword_noalias                    %dfa noalias
// %token Keyword_null                       %dfa null
// %token Keyword_or                         %dfa or
// %token Keyword_orelse                     %dfa orelse
// %token Keyword_packed                     %dfa packed
// %token Keyword_promise                    %dfa promise
// %token Keyword_pub                        %dfa pub
// %token Keyword_resume                     %dfa resume
// %token Keyword_return                     %dfa return
// %token Keyword_linksection                %dfa linksection
// %token Keyword_stdcallcc                  %dfa stdcallcc
// %token Keyword_struct                     %dfa struct
// %token Keyword_suspend                    %dfa suspend
// %token Keyword_switch                     %dfa switch
// %token Keyword_test                       %dfa test
// %token Keyword_threadlocal                %dfa threadlocal
// %token Keyword_true                       %dfa true
// %token Keyword_try                        %dfa try
// %token Keyword_undefined                  %dfa undefined
// %token Keyword_union                      %dfa union
// %token Keyword_unreachable                %dfa unreachable
// %token Keyword_use                        %dfa use
// %token Keyword_usingnamespace             %dfa usingnamespace
// %token Keyword_var                        %dfa var
// %token Keyword_volatile                   %dfa volatile
// %token Keyword_while                      %dfa while

// %missing LBrace
// %missing LCurly
// %missing LineComment
// %missing DocComment
// %missing MultilineStringLiteral
// %missing CharLiteral
// %missing StringLiteral

// %token IntegerLiteral                     %dfa ([0-9][0-9]*)|(0b[01]+)|(0o[0-7]+)|(0x[0-9A-Fa-f]+)
// %token FloatLiteral                       %dfa 0x([0-9A-Fa-f]+)\.([0-9A-Fa-f]+)([pP][-+]?[0-9A-Fa-f]+)?
// %token FloatLiteral                       %dfa [0-9]+\.([0-9]+)([pP][-+]?[0-9]+)?
// %token FloatLiteral                       %dfa 0x([0-9A-Fa-f]+)\.?[pP][-+]?[0-9A-Fa-f]+
// %token FloatLiteral                       %dfa [0-9]+\.?[pP][-+]?[0-9]+
// %token Identifier                         %dfa [A-Za-z_]([A-Za-z0-9_]*)
// %token Identifier                         %dfa @"[A-Za-z_]([A-Za-z0-9_]*)"
// %token Builtin                            %dfa @[A-Za-z_]([A-Za-z0-9_]*)

// LBrace
// %dfa {
{
    if(self.index == 1) return Id.LBrace;
    switch(self.source[self.index-2]) {
        ':', ' ', '\t', '\r', '\n' =>  return Id.LBrace,
        else => return Id.LCurly,
    }
}
// %end

// Space
// %dfa ( )+
{
    return Id.Ignore;
}
// %end

// Comments
// %dfa //
{
    var comment_id = Id.LineComment;

    if (self.peek == '/') {
        _ = self.getc();
        if (self.peek != '/') {
            comment_id = Id.DocComment;
        }
    }

    while (true) {
        switch (self.peek) {
            '\n', -1 => return comment_id,
            else => {},
        }
        _ = self.getc();
    }
}
// %end

// LineString
// %dfa \\\\
{
    while (true) {
        switch (self.peek) {
            '\n', -1 => return Id.LineString,
            else => {},
        }
        _ = self.getc();
    }
}
// %end

// LineCString
// %dfa c\\\\
{
    while (true) {
        switch (self.peek) {
            '\n', -1 => return Id.LineCString,
            else => {},
        }
        _ = self.getc();
    }
}
// %end

// CharLiteral
// %dfa '
{
    while (true) {
        switch (self.peek) {
            '\n', -1 => return Id.Invalid,
            '\\' => {
                _ = self.getc();
            },
            '\'' => {
                _ = self.getc();
                return Id.CharLiteral;
            },
            else => {},
        }
        _ = self.getc();
    }
}
// %end

// StringLiteral
// %dfa "
{
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
// %end

// StringLiteral
// %dfa c"[^"]
{
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
// %end

// ShebangLine
// %dfa #!
{
    if (self.index != 2)
        return Id.Invalid;

    while (true) {
        switch (self.peek) {
            '\n', -1 => return Id.ShebangLine,
            else => {},
        }
        _ = self.getc();
    }
}
// %end

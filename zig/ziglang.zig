pub extern "LALR" const zig_grammar = struct {
    const Precedence = struct {
        right: enum {
            Precedence_enumlit,
        },
        left: enum {
            // AssignOp
            Equal,
            AsteriskEqual,
            SlashEqual,
            PercentEqual,
            PlusEqual,
            MinusEqual,
            AngleBracketAngleBracketLeftEqual,
            AngleBracketAngleBracketRightEqual,
            AmpersandEqual,
            CaretEqual,
            PipeEqual,
            AsteriskPercentEqual,
            PlusPercentEqual,
            MinusPercentEqual,
        },
        right: enum {
            Keyword_break,
            Keyword_return,
            Keyword_continue,
            Keyword_resume,
            Keyword_cancel,
            Keyword_comptime,
            Keyword_promise,
        },
        left: enum {
            Keyword_or,
        },
        left: enum {
            Keyword_and,
            AmpersandAmpersand,
        },
        left: enum {
            // CompareOp
            EqualEqual,
            BangEqual,
            AngleBracketLeft,
            AngleBracketRight,
            AngleBracketLeftEqual,
            AngleBracketRightEqual,
        },
        left: enum {
            Keyword_orelse,
            Keyword_catch,
        },
        left: enum {
            // Bitwise OR
            Pipe,
        },
        left: enum {
            // Bitwise XOR
            Caret,
        },
        left: enum {
            // Bitwise AND
            Ampersand,
        },
        left: enum {
            AngleBracketAngleBracketLeft,
            AngleBracketAngleBracketRight,
        },
        left: enum {
            Plus,
            Minus,
            PlusPlus,
            PlusPercent,
            MinusPercent,
        },
        left: enum {
            Asterisk,
            Slash,
            Percent,
            AsteriskAsterisk,
            AsteriskPercent,
            PipePipe,
        },
        right: enum {
            Keyword_try,
            Keyword_await,

            Precedence_not,
            Precedence_neg,
            Tilde,
            Precedence_ref,
            QuestionMark,
        },
        right: enum {
            // x{} initializer
            LCurly,
            LBrace,
            // x.* x.?
            PeriodAsterisk,
            PeriodQuestionMark,
        },
        left: enum {
            // a!b
            Bang,
        },
        left: enum {
            LParen,
            LBracket,
            Period,
        },
        left: enum {
            Precedence_async,
        },
    };

    fn Root(MaybeRootDocComment: ?*Node.DocComment, MaybeContainerMembers: ?*NodeList) *Node {
        const node = try parser.createNode(Node.Root);
        node.doc_comments = arg1;
        node.decls = if (arg2) |p| p.* else NodeList.init(parser.allocator);
        result = &node.base;
    }

    // DocComments
    fn MaybeDocComment() ?*Node.DocComment;
    fn MaybeDocComment(DocCommentLines: *TokenList) ?*Node.DocComment {
        const node = try parser.createNode(Node.DocComment);
        node.lines = arg1.*;
        result = node;
    }
    fn DocCommentLines(DocCommentLines: *TokenList, DocComment: *Token) *TokenList {
        result = arg1;
        try arg1.append(arg2);
    }
    fn DocCommentLines(DocComment: *Token) *TokenList {
        result = try parser.createListWithToken(TokenList, arg1);
    }
    fn MaybeRootDocComment() ?*Node.DocComment;
    fn MaybeRootDocComment(RootDocCommentLines: *TokenList) ?*Node.DocComment {
        const node = try parser.createNode(Node.DocComment);
        node.lines = arg1.*;
        result = node;
    }
    fn RootDocCommentLines(RootDocCommentLines: *TokenList, RootDocComment: *Token) *TokenList {
        result = arg1;
        try arg1.append(arg2);
    }
    fn RootDocCommentLines(RootDocComment: *Token) *TokenList {
        result = try parser.createListWithToken(TokenList, arg1);
    }

    // Containers
    fn MaybeContainerMembers() ?*NodeList;
    fn MaybeContainerMembers(ContainerMembers: *NodeList) ?*NodeList;

    fn ContainerMembers(ContainerMembers: *NodeList, ContainerMember: *Node) *NodeList {
        result = arg1;
        try arg1.append(arg2);
    }
    fn ContainerMembers(ContainerMember: *Node) *NodeList {
        result = try parser.createListWithNode(NodeList, arg1);
    }

    fn ContainerMember(MaybeDocComment: ?*Node.DocComment, TestDecl: *Node.TestDecl) *Node {
        result = &arg2.base;
        arg2.doc_comments = arg1;
    }
    fn ContainerMember(MaybeDocComment: ?*Node.DocComment, TopLevelComptime: *Node.Comptime) *Node {
        result = &arg2.base;
        arg2.doc_comments = arg1;
    }
    fn ContainerMember(MaybeDocComment: ?*Node.DocComment, MaybePub: ?*Token, TopLevelDecl: *Node) *Node {
        result = arg3;
        if (arg3.cast(Node.VarDecl)) |node| {
            node.doc_comments = arg1;
            node.visib_token = arg2;
        } else if (arg3.cast(Node.FnProto)) |node| {
            node.doc_comments = arg1;
            node.visib_token = arg2;
        } else {
            const node = arg3.unsafe_cast(Node.Use);
            node.doc_comments = arg1;
            node.visib_token = arg2;
        }
    }
    fn ContainerMember(MaybeDocComment: ?*Node.DocComment, MaybePub: ?*Token, ContainerField: *Node, Comma: *Token) *Node {
        result = arg3;
        const node = arg3.unsafe_cast(Node.ContainerField);
        node.doc_comments = arg1;
        node.visib_token = arg2;
    }

    // Test
    fn TestDecl(Keyword_test: *Token, StringLiteral: *Token, Block: *Node.Block) *Node.TestDecl {
        const name = try parser.createNode(Node.StringLiteral);
        name.token = arg2;
        const node = try parser.createNode(Node.TestDecl);
        node.test_token = arg1;
        node.name = &name.base;
        node.body_node = &arg3.base;
        result = node;
    }

    // Comptime
    fn TopLevelComptime(Keyword_comptime: *Token, BlockExpr: *Node) *Node.Comptime {
        const node = try parser.createNode(Node.Comptime);
        node.comptime_token = arg1;
        node.expr = arg2;
        result = node;
    }

    // TopLevel declarations
    fn TopLevelDecl(FnProto: *Node.FnProto, Semicolon: *Token) *Node {
        result = &arg1.base;
    }
    fn TopLevelDecl(FnProto: *Node.FnProto, Block: *Node.Block) *Node {
        arg1.body_node = &arg2.base;
        result = &arg1.base;
    }
    fn TopLevelDecl(Keyword_extern: *Token, StringLiteral: *Token, FnProto: *Node.FnProto, Semicolon: *Token) *Node {
        result = &arg3.base;
        const lib_name = try parser.createNode(Node.StringLiteral);
        lib_name.token = arg2;
        arg3.extern_export_inline_token = arg1;
        arg3.lib_name = &lib_name.base;
    }
    fn TopLevelDecl(Keyword_extern: *Token, StringLiteral: *Token, FnProto: *Node.FnProto, Block: *Node.Block) *Node {
        result = &arg3.base;
        const lib_name = try parser.createNode(Node.StringLiteral);
        lib_name.token = arg2;
        arg3.extern_export_inline_token = arg1;
        arg3.lib_name = &lib_name.base;
        arg3.body_node = &arg4.base;
    }
    fn TopLevelDecl(Keyword_export: *Token, FnProto: *Node.FnProto, Semicolon: *Token) *Node {
        result = &arg2.base;
        arg2.extern_export_inline_token = arg1;
    }
    fn TopLevelDecl(Keyword_inline: *Token, FnProto: *Node.FnProto, Semicolon: *Token) *Node {
        result = &arg2.base;
        arg2.extern_export_inline_token = arg1;
    }
    fn TopLevelDecl(Keyword_export: *Token, FnProto: *Node.FnProto, Block: *Node.Block) *Node {
        result = &arg2.base;
        arg2.extern_export_inline_token = arg1;
        arg2.body_node = &arg3.base;
    }
    fn TopLevelDecl(Keyword_inline: *Token, FnProto: *Node.FnProto, Block: *Node.Block) *Node {
        result = &arg2.base;
        arg2.extern_export_inline_token = arg1;
        arg2.body_node = &arg3.base;
    }
    fn TopLevelDecl(MaybeThreadlocal: ?*Token, VarDecl: *Node) *Node {
        result = arg2;
        const node = arg2.unsafe_cast(Node.VarDecl);
        node.thread_local_token = arg1;
    }
    fn TopLevelDecl(Keyword_extern: *Token, StringLiteral: *Token, MaybeThreadlocal: ?*Token, VarDecl: *Node) *Node {
        result = arg4;
        const lib_name = try parser.createNode(Node.StringLiteral);
        lib_name.token = arg2;
        const node = arg4.unsafe_cast(Node.VarDecl);
        node.extern_export_token = arg1;
        node.lib_name = &lib_name.base;
        node.thread_local_token = arg3;
    }
    fn TopLevelDecl(Keyword_export: *Token, MaybeThreadlocal: ?*Token, VarDecl: *Node) *Node {
        result = arg3;
        const node = arg3.unsafe_cast(Node.VarDecl);
        node.extern_export_token = arg1;
        node.thread_local_token = arg2;
    }
    fn TopLevelDecl(Keyword_extern: *Token, MaybeThreadlocal: ?*Token, VarDecl: *Node) *Node {
        result = arg3;
        const node = arg3.unsafe_cast(Node.VarDecl);
        node.extern_export_token = arg1;
        node.thread_local_token = arg2;
    }
    fn TopLevelDecl(Keyword_usingnamespace: *Token, Expr: *Node, Semicolon: *Token) *Node {
        const node = try parser.createNode(Node.Use);
        node.use_token = arg1;
        node.expr = arg2;
        node.semicolon_token = arg3;
        result = &node.base;
    }
    fn TopLevelDecl(Keyword_use: *Token, Expr: *Node, Semicolon: *Token) *Node {
        const node = try parser.createNode(Node.Use);
        node.use_token = arg1;
        node.expr = arg2;
        node.semicolon_token = arg3;
        result = &node.base;
    }

    fn MaybeThreadlocal() ?*Token;
    fn MaybeThreadlocal(Keyword_threadlocal: *Token) ?*Token;

    // Functions
    fn FnProto(MaybeFnCC: ?*Token, Keyword_fn: *Token, MaybeIdentifier: ?*Token, LParen: Precedence_none(*Token), MaybeParamDeclList: ?*NodeList, RParen: *Token, MaybeByteAlign: ?*Node, MaybeLinkSection: ?*Node, Expr: *Node) *Node.FnProto {
        const node = try parser.createNode(Node.FnProto);
        node.cc_token = arg1;
        node.fn_token = arg2;
        node.name_token = arg3;
        node.params = if (arg5) |p| p.* else NodeList.init(parser.allocator);
        node.align_expr = arg7;
        node.section_expr = arg8;
        node.return_type = Node.FnProto.ReturnType{ .Explicit = arg9 };
        result = node;
    }
    fn FnProto(MaybeFnCC: ?*Token, Keyword_fn: *Token, MaybeIdentifier: ?*Token, LParen: Precedence_none(*Token), MaybeParamDeclList: ?*NodeList, RParen: *Token, MaybeByteAlign: ?*Node, MaybeLinkSection: ?*Node, Bang: Precedence_none(*Token), Expr: *Node) *Node.FnProto {
        const node = try parser.createNode(Node.FnProto);
        node.cc_token = arg1;
        node.fn_token = arg2;
        node.name_token = arg3;
        node.params = if (arg5) |p| p.* else NodeList.init(parser.allocator);
        node.align_expr = arg7;
        node.section_expr = arg8;
        node.return_type = Node.FnProto.ReturnType{ .InferErrorSet = arg10 };
        result = node;
    }
    fn FnProto(MaybeFnCC: ?*Token, Keyword_fn: *Token, MaybeIdentifier: ?*Token, LParen: Precedence_none(*Token), MaybeParamDeclList: ?*NodeList, RParen: *Token, MaybeByteAlign: ?*Node, MaybeLinkSection: ?*Node, Keyword_var: *Token) *Node.FnProto {
        const vnode = try parser.createNode(Node.VarType);
        vnode.token = arg9;
        const node = try parser.createNode(Node.FnProto);
        node.cc_token = arg1;
        node.fn_token = arg2;
        node.name_token = arg3;
        node.params = if (arg5) |p| p.* else NodeList.init(parser.allocator);
        node.align_expr = arg7;
        node.section_expr = arg8;
        node.return_type = Node.FnProto.ReturnType{ .Explicit = &vnode.base };
        result = node;
    }
    fn FnProto(MaybeFnCC: ?*Token, Keyword_fn: *Token, MaybeIdentifier: ?*Token, LParen: Precedence_none(*Token), MaybeParamDeclList: ?*NodeList, RParen: *Token, MaybeByteAlign: ?*Node, MaybeLinkSection: ?*Node, Bang: Precedence_none(*Token), Keyword_var: *Token) *Node.FnProto {
        const vnode = try parser.createNode(Node.VarType);
        vnode.token = arg10;
        const node = try parser.createNode(Node.FnProto);
        node.cc_token = arg1;
        node.fn_token = arg2;
        node.name_token = arg3;
        node.params = if (arg5) |p| p.* else NodeList.init(parser.allocator);
        node.align_expr = arg7;
        node.section_expr = arg8;
        node.return_type = Node.FnProto.ReturnType{ .InferErrorSet = &vnode.base };
        result = node;
    }

    // Variables
    fn VarDecl(Keyword_const: *Token, Identifier: *Token, MaybeColonTypeExpr: ?*Node, MaybeByteAlign: ?*Node, MaybeLinkSection: ?*Node, MaybeEqualExpr: ?*Node, Semicolon: *Token) *Node {
        const node = try parser.createNode(Node.VarDecl);
        node.mut_token = arg1;
        node.name_token = arg2;
        node.type_node = arg3;
        node.align_node = arg4;
        node.section_node = arg5;
        node.init_node = arg6;
        node.semicolon_token = arg7;
        result = &node.base;
    }
    fn VarDecl(Keyword_var: *Token, Identifier: *Token, MaybeColonTypeExpr: ?*Node, MaybeByteAlign: ?*Node, MaybeLinkSection: ?*Node, MaybeEqualExpr: ?*Node, Semicolon: *Token) *Node {
        const node = try parser.createNode(Node.VarDecl);
        node.mut_token = arg1;
        node.name_token = arg2;
        node.type_node = arg3;
        node.align_node = arg4;
        node.section_node = arg5;
        node.init_node = arg6;
        node.semicolon_token = arg7;
        result = &node.base;
    }

    // Container field
    fn ContainerField(Identifier: *Token, MaybeColonTypeExpr: ?*Node, MaybeEqualExpr: ?*Node) *Node {
        const node = try parser.createNode(Node.ContainerField);
        node.name_token = arg1;
        node.type_expr = arg2;
        node.value_expr = arg3;
        result = &node.base;
    }

    // Statements
    fn MaybeStatements() ?*NodeList;
    fn MaybeStatements(Statements: *NodeList) ?*NodeList;

    fn Statements(Statement: *Node) *NodeList {
        result = try parser.createListWithNode(NodeList, arg1);
    }
    fn Statements(Statements: *NodeList, Statement: *Node) *NodeList {
        result = arg1;
        try arg1.append(arg2);
    }

    fn Statement(Keyword_comptime: *Token, VarDecl: *Node) *Node {
        const node = try parser.createNode(Node.Comptime);
        node.comptime_token = arg1;
        node.expr = arg2;
        result = &node.base;
    }
    fn Statement(VarDecl: *Node) *Node;
    fn Statement(Keyword_comptime: *Token, BlockExpr: *Node) *Node {
        const node = try parser.createNode(Node.Comptime);
        node.comptime_token = arg1;
        node.expr = arg2;
        result = &node.base;
    }
    fn Statement(Keyword_suspend: *Token, Semicolon: *Token) *Node {
        const node = try parser.createNode(Node.Suspend);
        node.suspend_token = arg1;
        result = &node.base;
    }
    fn Statement(Keyword_suspend: *Token, BlockExprStatement: *Node) *Node {
        const node = try parser.createNode(Node.Suspend);
        node.suspend_token = arg1;
        node.body = arg2;
        result = &node.base;
    }
    fn Statement(Keyword_defer: *Token, BlockExprStatement: *Node) *Node {
        const node = try parser.createNode(Node.Defer);
        node.defer_token = arg1;
        node.expr = arg2;
        result = &node.base;
    }
    fn Statement(Keyword_errdefer: *Token, BlockExprStatement: *Node) *Node {
        const node = try parser.createNode(Node.Defer);
        node.defer_token = arg1;
        node.expr = arg2;
        result = &node.base;
    }
    fn Statement(IfStatement: *Node) *Node;
    fn Statement(MaybeInline: ?*Token, ForStatement: *Node.For) *Node {
        result = &arg2.base;
        arg2.inline_token = arg1;
    }
    fn Statement(MaybeInline: ?*Token, WhileStatement: *Node.While) *Node {
        result = &arg2.base;
        arg2.inline_token = arg1;
    }
    fn Statement(LabeledStatement: *Node) *Node;
    fn Statement(SwitchExpr: *Node) *Node;
    fn Statement(AssignExpr: *Node, Semicolon: *Token) *Node {
        result = arg1;
    }

    fn IfStatement(IfPrefix: *Node.If, BlockExpr: *Node) *Node {
        result = &arg1.base;
        arg1.body = arg2;
    }
    fn IfStatement(IfPrefix: *Node.If, BlockExpr: *Node, ElseStatement: *Node.Else) *Node {
        result = &arg1.base;
        arg1.body = arg2;
        arg1.@"else" = arg3;
    }
    fn IfStatement(IfPrefix: *Node.If, AssignExpr: *Node, Semicolon: *Token) *Node {
        result = &arg1.base;
        arg1.body = arg2;
    }
    fn IfStatement(IfPrefix: *Node.If, AssignExpr: *Node, ElseStatement: *Node.Else) *Node {
        result = &arg1.base;
        arg1.body = arg2;
        arg1.@"else" = arg3;
    }
    fn ElseStatement(Keyword_else: *Token, MaybePayload: ?*Node, Statement: *Node) *Node.Else {
        const node = try parser.createNode(Node.Else);
        node.else_token = arg1;
        node.payload = arg2;
        node.body = arg3;
        result = node;
    }

    fn LabeledStatement(BlockLabel: *Token, MaybeInline: ?*Token, ForStatement: *Node.For) *Node {
        result = &arg3.base;
        arg3.label = arg1;
        arg3.inline_token = arg2;
    }
    fn LabeledStatement(BlockLabel: *Token, MaybeInline: ?*Token, WhileStatement: *Node.While) *Node {
        result = &arg3.base;
        arg3.label = arg1;
        arg3.inline_token = arg2;
    }
    fn LabeledStatement(BlockExpr: *Node) *Node;

    fn ForStatement(ForPrefix: *Node.For, BlockExpr: *Node) *Node.For {
        result = arg1;
        arg1.body = arg2;
    }
    fn ForStatement(ForPrefix: *Node.For, BlockExpr: *Node, ElseNoPayloadStatement: *Node.Else) *Node.For {
        result = arg1;
        arg1.body = arg2;
        arg1.@"else" = arg3;
    }
    fn ForStatement(ForPrefix: *Node.For, AssignExpr: *Node, Semicolon: *Token) *Node.For {
        result = arg1;
        arg1.body = arg2;
    }
    fn ForStatement(ForPrefix: *Node.For, AssignExpr: *Node, ElseNoPayloadStatement: *Node.Else) *Node.For {
        result = arg1;
        arg1.body = arg2;
        arg1.@"else" = arg3;
    }
    fn ElseNoPayloadStatement(Keyword_else: *Token, Statement: *Node) *Node.Else {
        const node = try parser.createNode(Node.Else);
        node.else_token = arg1;
        node.body = arg2;
        result = node;
    }

    fn WhileStatement(WhilePrefix: *Node.While, BlockExpr: *Node) *Node.While {
        result = arg1;
        arg1.body = arg2;
    }
    fn WhileStatement(WhilePrefix: *Node.While, BlockExpr: *Node, ElseStatement: *Node.Else) *Node.While {
        result = arg1;
        arg1.body = arg2;
        arg1.@"else" = arg3;
    }
    fn WhileStatement(WhilePrefix: *Node.While, AssignExpr: *Node, Semicolon: *Token) *Node.While {
        result = arg1;
        arg1.body = arg2;
    }
    fn WhileStatement(WhilePrefix: *Node.While, AssignExpr: *Node, ElseStatement: *Node.Else) *Node.While {
        result = arg1;
        arg1.body = arg2;
        arg1.@"else" = arg3;
    }

    fn BlockExprStatement(BlockExpr: *Node) *Node;
    fn BlockExprStatement(AssignExpr: *Node, Semicolon: *Token) *Node {
        result = arg1;
    }

    // Expression level
    fn AssignExpr(Expr: *Node, AsteriskEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .AssignTimes;
        node.rhs = arg3;
        result = &node.base;
    }
    fn AssignExpr(Expr: *Node, SlashEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .AssignDiv;
        node.rhs = arg3;
        result = &node.base;
    }
    fn AssignExpr(Expr: *Node, PercentEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .AssignMod;
        node.rhs = arg3;
        result = &node.base;
    }
    fn AssignExpr(Expr: *Node, PlusEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .AssignPlus;
        node.rhs = arg3;
        result = &node.base;
    }
    fn AssignExpr(Expr: *Node, MinusEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .AssignMinus;
        node.rhs = arg3;
        result = &node.base;
    }
    fn AssignExpr(Expr: *Node, AngleBracketAngleBracketLeftEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .AssignBitShiftLeft;
        node.rhs = arg3;
        result = &node.base;
    }
    fn AssignExpr(Expr: *Node, AngleBracketAngleBracketRightEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .AssignBitShiftRight;
        node.rhs = arg3;
        result = &node.base;
    }
    fn AssignExpr(Expr: *Node, AmpersandEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .AssignBitAnd;
        node.rhs = arg3;
        result = &node.base;
    }
    fn AssignExpr(Expr: *Node, CaretEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .AssignBitXor;
        node.rhs = arg3;
        result = &node.base;
    }
    fn AssignExpr(Expr: *Node, PipeEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .AssignBitOr;
        node.rhs = arg3;
        result = &node.base;
    }
    fn AssignExpr(Expr: *Node, AsteriskPercentEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .AssignTimesWrap;
        node.rhs = arg3;
        result = &node.base;
    }
    fn AssignExpr(Expr: *Node, PlusPercentEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .AssignPlusWrap;
        node.rhs = arg3;
        result = &node.base;
    }
    fn AssignExpr(Expr: *Node, MinusPercentEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .AssignMinusWrap;
        node.rhs = arg3;
        result = &node.base;
    }
    fn AssignExpr(Expr: *Node, Equal: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .Assign;
        node.rhs = arg3;
        result = &node.base;
    }
    fn AssignExpr(Expr: *Node) *Node;

    fn MaybeEqualExpr() ?*Node;
    fn MaybeEqualExpr(Equal: *Token, Expr: *Node) ?*Node {
        result = arg2;
    }

    // Recovery
    fn Expr(Recovery: *Token) *Node {
        const node = try parser.createNode(Node.Recovery);
        node.token = arg1;
        result = &node.base;
    }

    // Grouped
    fn Expr(LParen: *Token, Expr: *Node, RParen: *Token) *Node {
        if (arg2.id != .GroupedExpression) {
            const node = try parser.createNode(Node.GroupedExpression);
            node.lparen = arg1;
            node.expr = arg2;
            node.rparen = arg3;
            result = &node.base;
        } else result = arg2;
    }

    // Infix
    fn Expr(Expr: *Node, Keyword_orelse: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .UnwrapOptional;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, Keyword_catch: *Token, MaybePayload: ?*Node, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = Node.InfixOp.Op{ .Catch = arg3 };
        node.rhs = arg4;
        result = &node.base;
    }
    fn Expr(Expr: *Node, Keyword_or: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .BoolOr;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, AmpersandAmpersand: *Token, Expr: *Node) *Node {
        try parser.reportError(ParseError.AmpersandAmpersand, arg2);
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .BoolAnd;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, Keyword_and: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .BoolAnd;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, EqualEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .EqualEqual;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, BangEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .BangEqual;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, AngleBracketLeft: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .LessThan;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, AngleBracketRight: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .GreaterThan;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, AngleBracketLeftEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .LessOrEqual;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, AngleBracketRightEqual: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .GreaterOrEqual;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, Pipe: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .BitOr;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, Caret: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .BitXor;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, Ampersand: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .BitAnd;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, AngleBracketAngleBracketLeft: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .BitShiftLeft;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, AngleBracketAngleBracketRight: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .BitShiftRight;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, Plus: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .Add;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, Minus: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .Sub;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, PlusPlus: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .ArrayCat;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, PlusPercent: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .AddWrap;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, MinusPercent: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .SubWrap;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, Asterisk: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .Div;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, Slash: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .Div;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, Percent: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .Mod;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, AsteriskAsterisk: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .ArrayMult;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, AsteriskPercent: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .MultWrap;
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Expr: *Node, PipePipe: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .ErrorUnion;
        node.rhs = arg3;
        result = &node.base;
    }

    // Prefix
    fn Expr(Bang: Precedence_not(*Token), Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = .BoolNot;
        node.rhs = arg2;
        result = &node.base;
    }
    fn Expr(Minus: Precedence_neg(*Token), Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = .Negation;
        node.rhs = arg2;
        result = &node.base;
    }
    fn Expr(MinusPercent: Precedence_neg(*Token), Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = .NegationWrap;
        node.rhs = arg2;
        result = &node.base;
    }
    fn Expr(Tilde: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = .BitNot;
        node.rhs = arg2;
        result = &node.base;
    }
    fn Expr(Ampersand: Precedence_ref(*Token), Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = .AddressOf;
        node.rhs = arg2;
        result = &node.base;
    }
    fn Expr(Keyword_async: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = .Async;
        node.rhs = arg2;
        result = &node.base;
    }
    fn Expr(Keyword_try: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = .Try;
        node.rhs = arg2;
        result = &node.base;
    }
    fn Expr(Keyword_await: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = .Await;
        node.rhs = arg2;
        result = &node.base;
    }
    fn Expr(Keyword_comptime: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.Comptime);
        node.comptime_token = arg1;
        node.expr = arg2;
        result = &node.base;
    }

    // Primary
    fn Expr(AsmExpr: *Node) *Node;
    fn Expr(Keyword_resume: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = .Resume;
        node.rhs = arg2;
        result = &node.base;
    }
    fn Expr(Keyword_cancel: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = .Cancel;
        node.rhs = arg2;
        result = &node.base;
    }
    fn Expr(Keyword_break: *Token) *Node {
        const node = try parser.createNode(Node.ControlFlowExpression);
        node.ltoken = arg1;
        node.kind = Node.ControlFlowExpression.Kind{ .Break = null };
        result = &node.base;
    }
    fn Expr(Keyword_break: *Token, BreakLabel: *Node) *Node {
        const node = try parser.createNode(Node.ControlFlowExpression);
        node.ltoken = arg1;
        node.kind = Node.ControlFlowExpression.Kind{ .Break = arg2 };
        result = &node.base;
    }
    fn Expr(Keyword_break: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.ControlFlowExpression);
        node.ltoken = arg1;
        node.kind = Node.ControlFlowExpression.Kind{ .Break = null };
        node.rhs = arg2;
        result = &node.base;
    }
    fn Expr(Keyword_break: *Token, BreakLabel: *Node, Expr: *Node) *Node {
        const node = try parser.createNode(Node.ControlFlowExpression);
        node.ltoken = arg1;
        node.kind = Node.ControlFlowExpression.Kind{ .Break = arg2 };
        node.rhs = arg3;
        result = &node.base;
    }
    fn Expr(Keyword_continue: *Token) *Node {
        const node = try parser.createNode(Node.ControlFlowExpression);
        node.ltoken = arg1;
        node.kind = Node.ControlFlowExpression.Kind{ .Continue = null };
        result = &node.base;
    }
    fn Expr(Keyword_continue: *Token, BreakLabel: *Node) *Node {
        const node = try parser.createNode(Node.ControlFlowExpression);
        node.ltoken = arg1;
        node.kind = Node.ControlFlowExpression.Kind{ .Continue = arg2 };
        result = &node.base;
    }
    fn Expr(Keyword_return: *Token) *Node {
        const node = try parser.createNode(Node.ControlFlowExpression);
        node.ltoken = arg1;
        node.kind = .Return;
        result = &node.base;
    }
    fn Expr(Keyword_return: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.ControlFlowExpression);
        node.ltoken = arg1;
        node.kind = .Return;
        node.rhs = arg2;
        result = &node.base;
    }

    // Initializer list
    fn Expr(Expr: *Node, LCurly: *Token, RBrace: *Token) *Node {
        const node = try parser.createNode(Node.SuffixOp);
        node.lhs = arg1;
        node.op = Node.SuffixOp.Op{ .ArrayInitializer = NodeList.init(parser.allocator) };
        node.rtoken = arg3;
        result = &node.base;
    }

    fn Expr(Expr: *Node, LCurly: *Token, InitList: *NodeList, MaybeComma: ?*Token, RBrace: *Token) *Node {
        const node = try parser.createNode(Node.SuffixOp);
        node.lhs = arg1;
        node.op = init: {
            if (arg3.at(0).cast(Node.InfixOp)) |infix| {
                switch (infix.op) {
                    // StructInitializer
                    .Assign => break :init Node.SuffixOp.Op{ .StructInitializer = arg3.* },
                    else => {},
                }
            }
            // ArrayInitializer
            break :init Node.SuffixOp.Op{ .ArrayInitializer = arg3.* };
        };
        node.rtoken = arg5;
        result = &node.base;
    }

    // Prefix
    fn Expr(QuestionMark: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = .OptionalType;
        node.rhs = arg2;
        result = &node.base;
    }
    fn Expr(Keyword_promise: *Token) *Node {
        const node = try parser.createNode(Node.PromiseType);
        node.promise_token = arg1;
        result = &node.base;
    }
    fn Expr(Keyword_promise: *Token, MinusAngleBracketRight: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.PromiseType);
        node.promise_token = arg1;
        node.result = Node.PromiseType.Result{ .arrow_token = arg2, .return_type = arg3 };
        result = &node.base;
    }
    // ArrayType
    fn Expr(LBracket: *Token, Expr: *Node, RBracket: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = Node.PrefixOp.Op{ .ArrayType = arg2 };
        node.rhs = arg4;
        result = &node.base;
    }
    // SliceType
    fn Expr(LBracket: *Token, RBracket: *Token, MaybeAllowzero: ?*Token, MaybeAlign: ?*Node.PrefixOp.PtrInfo.Align, MaybeConst: ?*Token, MaybeVolatile: ?*Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = Node.PrefixOp.Op{ .SliceType = Node.PrefixOp.PtrInfo{ .allowzero_token = arg3, .align_info = if (arg4) |p| p.* else null, .const_token = arg5, .volatile_token = arg6 } };
        node.rhs = arg7;
        result = &node.base;
    }
    // PtrType
    fn Expr(Asterisk: Precedence_none(*Token), MaybeAllowzero: ?*Token, MaybeAlign: ?*Node.PrefixOp.PtrInfo.Align, MaybeConst: ?*Token, MaybeVolatile: ?*Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = Node.PrefixOp.Op{ .PtrType = Node.PrefixOp.PtrInfo{ .allowzero_token = arg2, .align_info = if (arg3) |p| p.* else null, .const_token = arg4, .volatile_token = arg5 } };
        node.rhs = arg6;
        result = &node.base;
    }
    fn Expr(AsteriskAsterisk: Precedence_none(*Token), MaybeAllowzero: ?*Token, MaybeAlign: ?*Node.PrefixOp.PtrInfo.Align, MaybeConst: ?*Token, MaybeVolatile: ?*Token, Expr: *Node) *Node {
        arg1.id = .Asterisk;
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = Node.PrefixOp.Op{ .PtrType = Node.PrefixOp.PtrInfo{ .allowzero_token = arg2, .align_info = if (arg3) |p| p.* else null, .const_token = arg4, .volatile_token = arg5 } };
        node.rhs = arg6;
        const outer = try parser.createNode(Node.PrefixOp);
        outer.op_token = arg1;
        outer.op = Node.PrefixOp.Op{ .PtrType = Node.PrefixOp.PtrInfo{ .allowzero_token = null, .align_info = null, .const_token = null, .volatile_token = null } };
        outer.rhs = &node.base;
        result = &outer.base;
    }
    fn Expr(BracketStarBracket: *Token, MaybeAllowzero: ?*Token, MaybeAlign: ?*Node.PrefixOp.PtrInfo.Align, MaybeConst: ?*Token, MaybeVolatile: ?*Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = Node.PrefixOp.Op{ .PtrType = Node.PrefixOp.PtrInfo{ .allowzero_token = arg2, .align_info = if (arg3) |p| p.* else null, .const_token = arg4, .volatile_token = arg5 } };
        node.rhs = arg6;
        result = &node.base;
    }
    fn Expr(BracketStarCBracket: *Token, MaybeAllowzero: ?*Token, MaybeAlign: ?*Node.PrefixOp.PtrInfo.Align, MaybeConst: ?*Token, MaybeVolatile: ?*Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.PrefixOp);
        node.op_token = arg1;
        node.op = Node.PrefixOp.Op{ .PtrType = Node.PrefixOp.PtrInfo{ .allowzero_token = arg2, .align_info = if (arg3) |p| p.* else null, .const_token = arg4, .volatile_token = arg5 } };
        node.rhs = arg6;
        result = &node.base;
    }

    // Block
    fn Expr(BlockExpr: Shadow(*Node)) *Node;
    fn BlockExpr(Block: *Node.Block) *Node {
        result = &arg1.base;
    }
    fn BlockExpr(BlockLabel: *Token, Block: *Node.Block) *Node {
        result = &arg2.base;
        arg2.label = arg1;
    }
    fn Block(LBrace: *Token, MaybeStatements: ?*NodeList, RBrace: *Token) *Node.Block {
        const node = try parser.createNode(Node.Block);
        node.lbrace = arg1;
        node.statements = if (arg2) |p| p.* else NodeList.init(parser.allocator);
        node.rbrace = arg3;
        result = node;
    }
    fn BlockLabel(Identifier: *Token, Colon: *Token) *Token {
        result = arg1;
    }

    // ErrorType
    fn Expr(Expr: *Node, Bang: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .ErrorUnion;
        node.rhs = arg3;
        result = &node.base;
    }

    // Literals
    fn Expr(Identifier: *Token) *Node {
        const node = try parser.createNode(Node.Identifier);
        node.token = arg1;
        result = &node.base;
    }
    fn Expr(CharLiteral: *Token) *Node {
        const node = try parser.createNode(Node.CharLiteral);
        node.token = arg1;
        result = &node.base;
    }
    fn Expr(FloatLiteral: *Token) *Node {
        const node = try parser.createNode(Node.FloatLiteral);
        node.token = arg1;
        result = &node.base;
    }
    fn Expr(IntegerLiteral: *Token) *Node {
        const node = try parser.createNode(Node.IntegerLiteral);
        node.token = arg1;
        result = &node.base;
    }
    fn Expr(StringLiteral: *Token) *Node {
        const node = try parser.createNode(Node.StringLiteral);
        node.token = arg1;
        result = &node.base;
    }
    fn Expr(MultilineStringLiteral: *TokenList) *Node {
        const node = try parser.createNode(Node.MultilineStringLiteral);
        node.lines = arg1.*;
        result = &node.base;
    }
    fn Expr(MultilineCStringLiteral: *TokenList) *Node {
        const node = try parser.createNode(Node.MultilineStringLiteral);
        node.lines = arg1.*;
        result = &node.base;
    }
    fn Expr(Period: Precedence_enumlit(*Token), Identifier: *Token) *Node {
        const node = try parser.createNode(Node.EnumLiteral);
        node.dot = arg1;
        node.name = arg2;
        result = &node.base;
    }

    // Simple types
    fn Expr(Keyword_error: *Token, Period: *Token, Identifier: *Token) *Node {
        const err = try parser.createNode(Node.ErrorType);
        err.token = arg1;
        const name = try parser.createNode(Node.Identifier);
        name.token = arg3;
        const infix = try parser.createNode(Node.InfixOp);
        infix.lhs = &err.base;
        infix.op_token = arg2;
        infix.op = .Period;
        infix.rhs = &name.base;
        result = &infix.base;
    }
    fn Expr(Keyword_error: *Token, LCurly: Precedence_none(*Token), RBrace: *Token) *Node {
        const error_set = try parser.createNode(Node.ErrorSetDecl);
        error_set.error_token = arg1;
        error_set.decls = NodeList.init(parser.allocator);
        error_set.rbrace_token = arg3;
        result = &error_set.base;
    }
    fn Expr(Keyword_error: *Token, LCurly: Precedence_none(*Token), ErrorTagList: *NodeList, MaybeComma: ?*Token, RBrace: *Token) *Node {
        const error_set = try parser.createNode(Node.ErrorSetDecl);
        error_set.error_token = arg1;
        error_set.decls = arg3.*;
        error_set.rbrace_token = arg5;
        result = &error_set.base;
    }
    fn Expr(Keyword_false: *Token) *Node {
        const node = try parser.createNode(Node.BoolLiteral);
        node.token = arg1;
        result = &node.base;
    }
    fn Expr(Keyword_true: *Token) *Node {
        const node = try parser.createNode(Node.BoolLiteral);
        node.token = arg1;
        result = &node.base;
    }
    fn Expr(Keyword_null: *Token) *Node {
        const node = try parser.createNode(Node.NullLiteral);
        node.token = arg1;
        result = &node.base;
    }
    fn Expr(Keyword_undefined: *Token) *Node {
        const node = try parser.createNode(Node.UndefinedLiteral);
        node.token = arg1;
        result = &node.base;
    }
    fn Expr(Keyword_unreachable: *Token) *Node {
        const node = try parser.createNode(Node.Unreachable);
        node.token = arg1;
        result = &node.base;
    }

    // Flow types
    fn Expr(SwitchExpr: Shadow(*Node)) *Node;

    // IfExpr
    fn Expr(IfPrefix: *Node.If, Expr: *Node) *Node {
        result = &arg1.base;
        arg1.body = arg2;
    }
    fn Expr(IfPrefix: *Node.If, Expr: *Node, Keyword_else: *Token, MaybePayload: ?*Node, Expr: *Node) *Node {
        result = &arg1.base;
        const node = try parser.createNode(Node.Else);
        node.else_token = arg3;
        node.payload = arg4;
        node.body = arg5;
        arg1.body = arg2;
        arg1.@"else" = node;
    }

    // Builtin calls
    fn Expr(Builtin: *Token, LParen: *Token, MaybeExprList: ?*NodeList, RParen: *Token) *Node {
        const node = try parser.createNode(Node.BuiltinCall);
        node.builtin_token = arg1;
        node.params = if (arg3) |p| p.* else NodeList.init(parser.allocator);
        node.rparen_token = arg4;
        result = &node.base;
    }

    // FunctionType
    fn Expr(FnProto: *Node.FnProto) *Node {
        result = &arg1.base;
    }

    // a[]
    fn Expr(Expr: *Node, LBracket: *Token, Expr: *Node, RBracket: *Token) *Node {
        const node = try parser.createNode(Node.SuffixOp);
        node.lhs = arg1;
        node.op = Node.SuffixOp.Op{ .ArrayAccess = arg3 };
        node.rtoken = arg4;
        result = &node.base;
    }
    fn Expr(Expr: *Node, LBracket: *Token, Expr: *Node, Ellipsis2: *Token, RBracket: *Token) *Node {
        const node = try parser.createNode(Node.SuffixOp);
        node.lhs = arg1;
        node.op = Node.SuffixOp.Op{ .Slice = Node.SuffixOp.Op.Slice{ .start = arg3, .end = null } };
        node.rtoken = arg5;
        result = &node.base;
    }
    fn Expr(Expr: *Node, LBracket: *Token, Expr: *Node, Ellipsis2: *Token, Expr: *Node, RBracket: *Token) *Node {
        const node = try parser.createNode(Node.SuffixOp);
        node.lhs = arg1;
        node.op = Node.SuffixOp.Op{ .Slice = Node.SuffixOp.Op.Slice{ .start = arg3, .end = arg5 } };
        node.rtoken = arg6;
        result = &node.base;
    }
    // a.b
    fn Expr(Expr: *Node, Period: *Token, Identifier: *Token) *Node {
        const name = try parser.createNode(Node.Identifier);
        name.token = arg3;
        const infix = try parser.createNode(Node.InfixOp);
        infix.lhs = arg1;
        infix.op_token = arg2;
        infix.op = .Period;
        infix.rhs = &name.base;
        result = &infix.base;
    }
    // a.*
    fn Expr(Expr: *Node, PeriodAsterisk: *Token) *Node {
        const node = try parser.createNode(Node.SuffixOp);
        node.lhs = arg1;
        node.op = .Deref;
        node.rtoken = arg2;
        result = &node.base;
    }
    // a.?
    fn Expr(Expr: *Node, PeriodQuestionMark: *Token) *Node {
        const node = try parser.createNode(Node.SuffixOp);
        node.lhs = arg1;
        node.op = .UnwrapOptional;
        node.rtoken = arg2;
        result = &node.base;
    }
    // a()
    fn Expr(Expr: *Node, LParen: *Token, MaybeExprList: ?*NodeList, RParen: *Token) *Node {
        const node = try parser.createNode(Node.SuffixOp);
        node.lhs = arg1;
        node.op = Node.SuffixOp.Op{ .Call = Node.SuffixOp.Op.Call{ .params = if (arg3) |p| p.* else NodeList.init(parser.allocator) } };
        node.rtoken = arg4;
        result = &node.base;
    }

    // Containers (struct/enum/union)
    fn Expr(ContainerDecl: *Node) *Node;
    fn ContainerDecl(MaybeExternPacked: ?*Token, ContainerDeclOp: *Token, LBrace: *Token, MaybeContainerMembers: ?*NodeList, RBrace: *Token) *Node {
        const node = try parser.createNode(Node.ContainerDecl);
        node.layout_token = arg1;
        node.kind_token = arg2;
        node.init_arg_expr = .None;
        node.lbrace_token = arg3;
        node.fields_and_decls = if (arg4) |p| p.* else NodeList.init(parser.allocator);
        node.rbrace_token = arg5;
        result = &node.base;
    }
    fn ContainerDecl(MaybeExternPacked: ?*Token, Keyword_enum: *Token, ContainerDeclTypeType: *Node, LBrace: *Token, MaybeContainerMembers: ?*NodeList, RBrace: *Token) *Node {
        const node = try parser.createNode(Node.ContainerDecl);
        node.layout_token = arg1;
        node.kind_token = arg2;
        node.init_arg_expr = Node.ContainerDecl.InitArg{ .Type = arg3 };
        node.lbrace_token = arg4;
        node.fields_and_decls = if (arg5) |p| p.* else NodeList.init(parser.allocator);
        node.rbrace_token = arg6;
        result = &node.base;
    }
    fn ContainerDecl(MaybeExternPacked: ?*Token, Keyword_union: *Token, ContainerDeclTypeType: *Node, LBrace: *Token, MaybeContainerMembers: ?*NodeList, RBrace: *Token) *Node {
        const node = try parser.createNode(Node.ContainerDecl);
        node.layout_token = arg1;
        node.kind_token = arg2;
        node.init_arg_expr = Node.ContainerDecl.InitArg{ .Type = arg3 };
        node.lbrace_token = arg4;
        node.fields_and_decls = if (arg5) |p| p.* else NodeList.init(parser.allocator);
        node.rbrace_token = arg6;
        result = &node.base;
    }
    fn ContainerDecl(MaybeExternPacked: ?*Token, Keyword_union: *Token, ContainerDeclTypeEnum: ?*Node, LBrace: *Token, MaybeContainerMembers: ?*NodeList, RBrace: *Token) *Node {
        const node = try parser.createNode(Node.ContainerDecl);
        node.layout_token = arg1;
        node.kind_token = arg2;
        node.init_arg_expr = Node.ContainerDecl.InitArg{ .Enum = arg3 };
        node.lbrace_token = arg4;
        node.fields_and_decls = if (arg5) |p| p.* else NodeList.init(parser.allocator);
        node.rbrace_token = arg6;
        result = &node.base;
    }

    // ContainerDecl helper
    fn MaybeExternPacked() ?*Token;
    fn MaybeExternPacked(Keyword_extern: *Token) ?*Token;
    fn MaybeExternPacked(Keyword_packed: *Token) ?*Token;

    fn SwitchExpr(Keyword_switch: *Token, LParen: *Token, Expr: *Node, RParen: *Token, LBrace: *Token, SwitchProngList: *NodeList, MaybeComma: ?*Token, RBrace: *Token) *Node {
        const node = try parser.createNode(Node.Switch);
        node.switch_token = arg1;
        node.expr = arg3;
        node.cases = arg6.*;
        node.rbrace = arg8;
        result = &node.base;
    }

    // Assembly
    fn String(StringLiteral: *Token) *Node {
        const node = try parser.createNode(Node.StringLiteral);
        node.token = arg1;
        result = &node.base;
    }
    fn String(MultilineStringLiteral: *TokenList) *Node {
        const node = try parser.createNode(Node.MultilineStringLiteral);
        node.lines = arg1.*;
        result = &node.base;
    }
    fn String(MultilineCStringLiteral: *TokenList) *Node {
        const node = try parser.createNode(Node.MultilineStringLiteral);
        node.lines = arg1.*;
        result = &node.base;
    }
    fn AsmExpr(Keyword_asm: *Token, MaybeVolatile: ?*Token, LParen: *Token, String: *Node, RParen: *Token) *Node {
        const node = try parser.createNode(Node.Asm);
        node.asm_token = arg1;
        node.volatile_token = arg2;
        node.template = arg4;
        node.outputs = NodeList.init(parser.allocator);
        node.inputs = NodeList.init(parser.allocator);
        node.clobbers = NodeList.init(parser.allocator);
        node.rparen = arg5;
        result = &node.base;
    }
    fn AsmExpr(Keyword_asm: *Token, MaybeVolatile: ?*Token, LParen: *Token, String: *Node, AsmOutput: ?*NodeList, RParen: *Token) *Node {
        const node = try parser.createNode(Node.Asm);
        node.asm_token = arg1;
        node.volatile_token = arg2;
        node.template = arg4;
        node.outputs = if (arg5) |p| p.* else NodeList.init(parser.allocator);
        node.inputs = NodeList.init(parser.allocator);
        node.clobbers = NodeList.init(parser.allocator);
        node.rparen = arg6;
        result = &node.base;
    }
    fn AsmExpr(Keyword_asm: *Token, MaybeVolatile: ?*Token, LParen: *Token, String: *Node, AsmOutput: ?*NodeList, AsmInput: ?*NodeList, RParen: *Token) *Node {
        const node = try parser.createNode(Node.Asm);
        node.asm_token = arg1;
        node.volatile_token = arg2;
        node.template = arg4;
        node.outputs = if (arg5) |p| p.* else NodeList.init(parser.allocator);
        node.inputs = if (arg6) |p| p.* else NodeList.init(parser.allocator);
        node.clobbers = NodeList.init(parser.allocator);
        node.rparen = arg7;
        result = &node.base;
    }
    fn AsmExpr(Keyword_asm: *Token, MaybeVolatile: ?*Token, LParen: *Token, String: *Node, AsmOutput: ?*NodeList, AsmInput: ?*NodeList, AsmClobber: ?*NodeList, RParen: *Token) *Node {
        const node = try parser.createNode(Node.Asm);
        node.asm_token = arg1;
        node.volatile_token = arg2;
        node.template = arg4;
        node.outputs = if (arg5) |p| p.* else NodeList.init(parser.allocator);
        node.inputs = if (arg6) |p| p.* else NodeList.init(parser.allocator);
        node.clobbers = if (arg7) |p| p.* else NodeList.init(parser.allocator);
        node.rparen = arg8;
        result = &node.base;
    }

    fn AsmOutput(Colon: *Token) ?*NodeList {
        result = null;
    }
    fn AsmOutput(Colon: *Token, AsmOutputList: *NodeList) ?*NodeList {
        result = arg2;
    }
    fn AsmOutputItem(LBracket: *Token, Identifier: *Token, RBracket: *Token, String: *Node, LParen: *Token, Identifier: *Token, RParen: *Token) *Node {
        const name = try parser.createNode(Node.Identifier);
        name.token = arg2;
        const variable = try parser.createNode(Node.Identifier);
        variable.token = arg6;
        const node = try parser.createNode(Node.AsmOutput);
        node.lbracket = arg1;
        node.symbolic_name = &name.base;
        node.constraint = arg4;
        node.kind = Node.AsmOutput.Kind{ .Variable = variable };
        node.rparen = arg7;
        result = &node.base;
    }
    fn AsmOutputItem(LBracket: *Token, Identifier: *Token, RBracket: *Token, String: *Node, LParen: *Token, MinusAngleBracketRight: *Token, Expr: *Node, RParen: *Token) *Node {
        const name = try parser.createNode(Node.Identifier);
        name.token = arg2;
        const node = try parser.createNode(Node.AsmOutput);
        node.lbracket = arg1;
        node.symbolic_name = &name.base;
        node.constraint = arg4;
        node.kind = Node.AsmOutput.Kind{ .Return = arg7 };
        node.rparen = arg8;
        result = &node.base;
    }

    fn AsmInput(Colon: *Token) ?*NodeList {
        result = null;
    }
    fn AsmInput(Colon: *Token, AsmInputList: *NodeList) ?*NodeList {
        result = arg2;
    }

    fn AsmInputItem(LBracket: *Token, Identifier: *Token, RBracket: *Token, String: *Node, LParen: *Token, Expr: *Node, RParen: *Token) *Node {
        const name = try parser.createNode(Node.Identifier);
        name.token = arg2;
        const node = try parser.createNode(Node.AsmInput);
        node.lbracket = arg1;
        node.symbolic_name = &name.base;
        node.constraint = arg4;
        node.expr = arg6;
        node.rparen = arg7;
        result = &node.base;
    }

    fn AsmClobber(Colon: *Token) ?*NodeList {
        result = null;
    }
    fn AsmClobber(Colon: *Token, StringList: *NodeList) ?*NodeList {
        result = arg2;
    }

    // Helper grammar
    fn BreakLabel(Colon: *Token, Identifier: *Token) *Node {
        const node = try parser.createNode(Node.Identifier);
        node.token = arg2;
        result = &node.base;
    }

    fn MaybeLinkSection() ?*Node;
    fn MaybeLinkSection(Keyword_linksection: *Token, LParen: *Token, Expr: *Node, RParen: *Token) ?*Node {
        result = arg3;
    }

    // Function specific
    fn MaybeFnCC() ?*Token;
    fn MaybeFnCC(Keyword_nakedcc: *Token) ?*Token;
    fn MaybeFnCC(Keyword_stdcallcc: *Token) ?*Token;
    fn MaybeFnCC(Keyword_extern: *Token) ?*Token;
    fn MaybeFnCC(Keyword_async: *Token) ?*Token;

    fn ParamDecl(MaybeNoalias: ?*Token, ParamType: *Node.ParamDecl) *Node.ParamDecl {
        result = arg2;
        arg2.noalias_token = arg1;
    }
    fn ParamDecl(MaybeNoalias: ?*Token, Identifier: *Token, Colon: *Token, ParamType: *Node.ParamDecl) *Node.ParamDecl {
        result = arg4;
        arg4.noalias_token = arg1;
        arg4.name_token = arg2;
    }
    fn ParamDecl(MaybeNoalias: ?*Token, Keyword_comptime: *Token, Identifier: *Token, Colon: *Token, ParamType: *Node.ParamDecl) *Node.ParamDecl {
        result = arg5;
        arg5.noalias_token = arg1;
        arg5.comptime_token = arg2;
        arg5.name_token = arg3;
    }

    fn ParamType(Keyword_var: *Token) *Node.ParamDecl {
        const vtype = try parser.createNode(Node.VarType);
        vtype.token = arg1;
        const node = try parser.createNode(Node.ParamDecl);
        node.type_node = &vtype.base;
        result = node;
    }
    fn ParamType(Ellipsis3: *Token) *Node.ParamDecl {
        const node = try parser.createNode(Node.ParamDecl);
        node.var_args_token = arg1;
        result = node;
    }
    fn ParamType(Expr: *Node) *Node.ParamDecl {
        const node = try parser.createNode(Node.ParamDecl);
        node.type_node = arg1;
        result = node;
    }

    // Control flow prefixes
    fn IfPrefix(Keyword_if: *Token, LParen: *Token, Expr: *Node, RParen: *Token, MaybePtrPayload: ?*Node) *Node.If {
        const node = try parser.createNode(Node.If);
        node.if_token = arg1;
        node.condition = arg3;
        node.payload = arg5;
        result = node;
    }

    fn ForPrefix(Keyword_for: *Token, LParen: *Token, Expr: *Node, RParen: *Token, PtrIndexPayload: *Node) *Node.For {
        const node = try parser.createNode(Node.For);
        node.for_token = arg1;
        node.array_expr = arg3;
        node.payload = arg5;
        result = node;
    }
    fn WhilePrefix(Keyword_while: *Token, LParen: *Token, Expr: *Node, RParen: *Token, MaybePtrPayload: ?*Node) *Node.While {
        const node = try parser.createNode(Node.While);
        node.while_token = arg1;
        node.condition = arg3;
        node.payload = arg5;
        result = node;
    }
    fn WhilePrefix(Keyword_while: *Token, LParen: *Token, Expr: *Node, RParen: *Token, MaybePtrPayload: ?*Node, Colon: *Token, LParen: *Token, AssignExpr: *Node, RParen: *Token) *Node.While {
        const node = try parser.createNode(Node.While);
        node.while_token = arg1;
        node.condition = arg3;
        node.payload = arg5;
        node.continue_expr = arg8;
        result = node;
    }

    // Payloads
    fn MaybePayload() ?*Node;
    fn MaybePayload(Pipe: *Token, Identifier: *Token, Pipe: *Token) ?*Node {
        const name = try parser.createNode(Node.Identifier);
        name.token = arg2;
        const node = try parser.createNode(Node.Payload);
        node.lpipe = arg1;
        node.error_symbol = &name.base;
        node.rpipe = arg3;
        result = &node.base;
    }

    fn MaybePtrPayload() ?*Node;
    fn MaybePtrPayload(Pipe: *Token, Identifier: *Token, Pipe: *Token) ?*Node {
        const name = try parser.createNode(Node.Identifier);
        name.token = arg2;
        const node = try parser.createNode(Node.PointerPayload);
        node.lpipe = arg1;
        node.value_symbol = &name.base;
        node.rpipe = arg3;
        result = &node.base;
    }
    fn MaybePtrPayload(Pipe: *Token, Asterisk: *Token, Identifier: *Token, Pipe: *Token) ?*Node {
        const name = try parser.createNode(Node.Identifier);
        name.token = arg3;
        const node = try parser.createNode(Node.PointerPayload);
        node.lpipe = arg1;
        node.ptr_token = arg2;
        node.value_symbol = &name.base;
        node.rpipe = arg4;
        result = &node.base;
    }

    fn PtrIndexPayload(Pipe: *Token, Identifier: *Token, Pipe: *Token) *Node {
        const name = try parser.createNode(Node.Identifier);
        name.token = arg2;
        const node = try parser.createNode(Node.PointerIndexPayload);
        node.lpipe = arg1;
        node.value_symbol = &name.base;
        node.rpipe = arg3;
        result = &node.base;
    }
    fn PtrIndexPayload(Pipe: *Token, Asterisk: *Token, Identifier: *Token, Pipe: *Token) *Node {
        const name = try parser.createNode(Node.Identifier);
        name.token = arg3;
        const node = try parser.createNode(Node.PointerIndexPayload);
        node.lpipe = arg1;
        node.ptr_token = arg2;
        node.value_symbol = &name.base;
        node.rpipe = arg4;
        result = &node.base;
    }
    fn PtrIndexPayload(Pipe: *Token, Identifier: *Token, Comma: *Token, Identifier: *Token, Pipe: *Token) *Node {
        const name = try parser.createNode(Node.Identifier);
        name.token = arg2;
        const index = try parser.createNode(Node.Identifier);
        index.token = arg4;
        const node = try parser.createNode(Node.PointerIndexPayload);
        node.lpipe = arg1;
        node.value_symbol = &name.base;
        node.index_symbol = &index.base;
        node.rpipe = arg5;
        result = &node.base;
    }
    fn PtrIndexPayload(Pipe: *Token, Asterisk: *Token, Identifier: *Token, Comma: *Token, Identifier: *Token, Pipe: *Token) *Node {
        const name = try parser.createNode(Node.Identifier);
        name.token = arg3;
        const index = try parser.createNode(Node.Identifier);
        index.token = arg5;
        const node = try parser.createNode(Node.PointerIndexPayload);
        node.lpipe = arg1;
        node.ptr_token = arg2;
        node.value_symbol = &name.base;
        node.index_symbol = &index.base;
        node.rpipe = arg6;
        result = &node.base;
    }

    // Switch specific
    fn SwitchProng(SwitchCase: *Node.SwitchCase, EqualAngleBracketRight: *Token, MaybePtrPayload: ?*Node, AssignExpr: *Node) *Node {
        result = &arg1.base;
        arg1.arrow_token = arg2;
        arg1.payload = arg3;
        arg1.expr = arg4;
    }

    fn SwitchCase(Keyword_else: *Token) *Node.SwitchCase {
        const else_node = try parser.createNode(Node.SwitchElse);
        else_node.token = arg1;
        const node = try parser.createNode(Node.SwitchCase);
        node.items = NodeList.init(parser.allocator);
        try node.items.append(&else_node.base);
        result = node;
    }
    fn SwitchCase(SwitchItems: *NodeList, MaybeComma: ?*Token) *Node.SwitchCase {
        const node = try parser.createNode(Node.SwitchCase);
        node.items = arg1.*;
        result = node;
    }

    fn SwitchItems(SwitchItem: *Node) *NodeList {
        result = try parser.createListWithNode(NodeList, arg1);
    }
    fn SwitchItems(SwitchItems: *NodeList, Comma: *Token, SwitchItem: *Node) *NodeList {
        result = arg1;
        try arg1.append(arg3);
    }

    fn SwitchItem(Expr: *Node) *Node;
    fn SwitchItem(Expr: *Node, Ellipsis3: *Token, Expr: *Node) *Node {
        const node = try parser.createNode(Node.InfixOp);
        node.lhs = arg1;
        node.op_token = arg2;
        node.op = .Range;
        node.rhs = arg3;
        result = &node.base;
    }

    fn MaybeVolatile() ?*Token;
    fn MaybeVolatile(Keyword_volatile: *Token) ?*Token;

    fn MaybeAllowzero() ?*Token;
    fn MaybeAllowzero(Keyword_allowzero: *Token) ?*Token;

    // ContainerDecl specific
    fn ContainerDeclTypeEnum(LParen: *Token, Keyword_enum: *Token, RParen: *Token) ?*Node;
    fn ContainerDeclTypeEnum(LParen: *Token, Keyword_enum: *Token, LParen: *Token, Expr: *Node, RParen: *Token, RParen: *Token) ?*Node {
        result = arg4;
    }
    fn ContainerDeclTypeType(LParen: *Token, Expr: *Node, RParen: *Token) *Node {
        result = arg2;
    }

    fn ContainerDeclOp(Keyword_struct: *Token) *Token;
    fn ContainerDeclOp(Keyword_union: *Token) *Token;
    fn ContainerDeclOp(Keyword_enum: *Token) *Token;

    // Alignment
    fn MaybeByteAlign() ?*Node;
    fn MaybeByteAlign(Keyword_align: *Token, LParen: *Token, Expr: *Node, RParen: *Token) ?*Node {
        result = arg3;
    }

    fn MaybeAlign() ?*Node.PrefixOp.PtrInfo.Align;
    fn MaybeAlign(Keyword_align: *Token, LParen: *Token, Expr: *Node, RParen: *Token) ?*Node.PrefixOp.PtrInfo.Align {
        const value = try parser.createTemporary(Node.PrefixOp.PtrInfo.Align);
        value.node = arg3;
        result = value;
    }
    fn MaybeAlign(Keyword_align: *Token, LParen: *Token, Expr: *Node, Colon: *Token, IntegerLiteral: *Token, Colon: *Token, IntegerLiteral: *Token, RParen: *Token) ?*Node.PrefixOp.PtrInfo.Align {
        const start = try parser.createNode(Node.IntegerLiteral);
        start.token = arg5;
        const end = try parser.createNode(Node.IntegerLiteral);
        end.token = arg7;
        const value = try parser.createTemporary(Node.PrefixOp.PtrInfo.Align);
        value.node = arg3;
        value.bit_range = Node.PrefixOp.PtrInfo.Align.BitRange{ .start = &start.base, .end = &end.base };
        result = value;
    }
    fn MaybeAlign(Keyword_align: *Token, LParen: *Token, Identifier: *Token, Colon: *Token, IntegerLiteral: *Token, Colon: *Token, IntegerLiteral: *Token, RParen: *Token) ?*Node.PrefixOp.PtrInfo.Align {
        const node = try parser.createNode(Node.Identifier);
        node.token = arg3;
        const start = try parser.createNode(Node.IntegerLiteral);
        start.token = arg5;
        const end = try parser.createNode(Node.IntegerLiteral);
        end.token = arg7;
        const value = try parser.createTemporary(Node.PrefixOp.PtrInfo.Align);
        value.node = &node.base;
        value.bit_range = Node.PrefixOp.PtrInfo.Align.BitRange{ .start = &start.base, .end = &end.base };
        result = value;
    }

    // Lists
    fn ErrorTagList(MaybeDocComment: ?*Node.DocComment, Identifier: *Token) *NodeList {
        const node = try parser.createNode(Node.ErrorTag);
        node.doc_comments = arg1;
        node.name_token = arg2;
        result = try parser.createListWithNode(NodeList, &node.base);
    }
    fn ErrorTagList(ErrorTagList: *NodeList, Comma: *Token, MaybeDocComment: ?*Node.DocComment, Identifier: *Token) *NodeList {
        result = arg1;
        const node = try parser.createNode(Node.ErrorTag);
        node.doc_comments = arg3;
        node.name_token = arg4;
        try arg1.append(&node.base);
    }

    fn SwitchProngList(SwitchProng: *Node) *NodeList {
        result = try parser.createListWithNode(NodeList, arg1);
    }
    fn SwitchProngList(SwitchProngList: *NodeList, Comma: *Token, SwitchProng: *Node) *NodeList {
        result = arg1;
        try arg1.append(arg3);
    }

    fn AsmOutputList(AsmOutputItem: *Node) *NodeList {
        result = try parser.createListWithNode(NodeList, arg1);
    }
    fn AsmOutputList(AsmOutputList: *NodeList, Comma: *Token, AsmOutputItem: *Node) *NodeList {
        result = arg1;
        try arg1.append(arg3);
    }

    fn AsmInputList(AsmInputItem: *Node) *NodeList {
        result = try parser.createListWithNode(NodeList, arg1);
    }
    fn AsmInputList(AsmInputList: *NodeList, Comma: *Token, AsmInputItem: *Node) *NodeList {
        result = arg1;
        try arg1.append(arg3);
    }

    fn StringList(StringLiteral: *Token) *NodeList {
        const node = try parser.createNode(Node.StringLiteral);
        node.token = arg1;
        result = try parser.createListWithNode(NodeList, &node.base);
    }
    fn StringList(StringList: *NodeList, Comma: *Token, StringLiteral: *Token) *NodeList {
        result = arg1;
        const node = try parser.createNode(Node.StringLiteral);
        node.token = arg3;
        try arg1.append(&node.base);
    }

    fn MaybeParamDeclList() ?*NodeList;
    fn MaybeParamDeclList(ParamDeclList: *NodeList, MaybeComma: ?*Token) *NodeList {
        result = arg1;
    }

    fn ParamDeclList(MaybeDocComment: ?*Node.DocComment, ParamDecl: *Node.ParamDecl) *NodeList {
        arg2.doc_comments = arg1;
        result = try parser.createListWithNode(NodeList, &arg2.base);
    }
    fn ParamDeclList(ParamDeclList: *NodeList, Comma: *Token, MaybeDocComment: ?*Node.DocComment, ParamDecl: *Node.ParamDecl) *NodeList {
        result = arg1;
        arg4.doc_comments = arg3;
        try arg1.append(&arg4.base);
    }

    fn MaybeExprList() ?*NodeList {}
    fn MaybeExprList(ExprList: *NodeList, MaybeComma: ?*Token) ?*NodeList {
        result = arg1;
    }

    fn ExprList(Expr: *Node) *NodeList {
        result = try parser.createListWithNode(NodeList, arg1);
    }
    fn ExprList(ExprList: *NodeList, Comma: *Token, Expr: *Node) *NodeList {
        result = arg1;
        try arg1.append(arg3);
    }

    fn InitList(Expr: *Node) *NodeList {
        result = try parser.createListWithNode(NodeList, arg1);
    }
    fn InitList(Period: *Token, Identifier: *Token, Equal: *Token, Expr: *Node) *NodeList {
        const node = try parser.createNode(Node.FieldInitializer);
        node.period_token = arg1;
        node.name_token = arg2;
        node.expr = arg4;
        result = try parser.createListWithNode(NodeList, &node.base);
    }
    fn InitList(InitList: *NodeList, Comma: *Token, Expr: *Node) *NodeList {
        result = arg1;
        try arg1.append(arg3);
    }
    fn InitList(InitList: *NodeList, Comma: *Token, Period: *Token, Identifier: *Token, Equal: *Token, Expr: *Node) *NodeList {
        result = arg1;
        const node = try parser.createNode(Node.FieldInitializer);
        node.period_token = arg3;
        node.name_token = arg4;
        node.expr = arg6;
        try arg1.append(&node.base);
    }

    // Various helpers
    fn MaybePub() ?*Token;
    fn MaybePub(Keyword_pub: *Token) ?*Token;

    fn MaybeColonTypeExpr() ?*Node;
    fn MaybeColonTypeExpr(Colon: *Token, Expr: *Node) ?*Node {
        result = arg2;
    }

    fn MaybeExpr() ?*Node;
    fn MaybeExpr(Expr: *Node) ?*Node;

    fn MaybeNoalias() ?*Token;
    fn MaybeNoalias(Keyword_noalias: *Token) ?*Token;

    fn MaybeInline() ?*Token;
    fn MaybeInline(Keyword_inline: *Token) ?*Token;

    fn MaybeIdentifier() ?*Token;
    fn MaybeIdentifier(Identifier: *Token) ?*Token;

    fn MaybeComma() ?*Token;
    fn MaybeComma(Comma: *Token) ?*Token;

    fn MaybeConst() ?*Token;
    fn MaybeConst(Keyword_const: *Token) ?*Token;

    fn MultilineStringLiteral(LineString: *Token) *TokenList {
        result = try parser.createListWithToken(TokenList, arg1);
    }
    fn MultilineStringLiteral(MultilineStringLiteral: *TokenList, LineString: *Token) *TokenList {
        result = arg1;
        try arg1.append(arg2);
    }

    fn MultilineCStringLiteral(LineCString: *Token) *TokenList {
        result = try parser.createListWithToken(TokenList, arg1);
    }
    fn MultilineCStringLiteral(MultilineCStringLiteral: *TokenList, LineCString: *Token) *TokenList {
        result = arg1;
        try arg1.append(arg2);
    }
};

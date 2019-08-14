pub extern "LALR" const json_grammar = struct {
    fn Object(LBrace: *Token, MaybeFields: *Variant.Object, RBrace: *Token) *Variant {
        result = &arg2.base;
    }

    fn MaybeFields() *Variant.Object {
        result = try parser.createVariant(Variant.Object);
        result.fields = VariantMap.init(parser.arena_allocator);
    }
    fn MaybeFields(Fields: *Variant.Object) *Variant.Object;

    fn Fields(StringLiteral: *Token, Colon: *Token, Element: *Variant) *Variant.Object {
        result = try parser.createVariant(Variant.Object);
        result.fields = VariantMap.init(parser.arena_allocator);
        const r = try result.fields.insert(parser.tokenString(arg1));
        if(!r.is_new)
            return error.JsonDuplicateKeyError;
        r.kv.value = arg3;
    }
    fn Fields(Fields: *Variant.Object, Comma: *Token, StringLiteral: *Token, Colon: *Token, Element: *Variant) *Variant.Object {
        result = arg1;
        const r = try result.fields.insert(parser.tokenString(arg3));
        if(!r.is_new)
            return error.JsonDuplicateKeyError;
        r.kv.value = arg5;
    }

    fn Array(LBracket: *Token, MaybeElements: ?*VariantList, RBracket: *Token) *Variant {
        const variant = try parser.createVariant(Variant.Array);
        variant.elements = if(arg2) |l| l.* else VariantList.init(parser.arena_allocator);
        result = &variant.base;
    }

    fn MaybeElements() ?*VariantList;
    fn MaybeElements(Elements: *VariantList) ?*VariantList;

    fn Elements(Element: *Variant) *VariantList {
        result = try parser.createVariantList(VariantList);
        try result.append(arg1);
    }
    fn Elements(Elements: *VariantList, Comma: *Token, Element: *Variant) *VariantList {
        result = arg1;
        try result.append(arg3);
    }

    fn Element(StringLiteral: *Token) *Variant {
        const variant = try parser.createVariant(Variant.StringLiteral);
        variant.value = try parser.unescapeTokenString(arg1);
        result = &variant.base;
    }
    fn Element(Keyword_null: *Token) *Variant {
        const variant = try parser.createVariant(Variant.NullLiteral);
        result = &variant.base;
    }
    fn Element(Keyword_true: *Token) *Variant {
        const variant = try parser.createVariant(Variant.BoolLiteral);
        variant.value = true;
        result = &variant.base;
    }
    fn Element(Keyword_false: *Token) *Variant {
        const variant = try parser.createVariant(Variant.BoolLiteral);
        variant.value = false;
        result = &variant.base;
    }
    fn Element(IntegerLiteral: *Token) *Variant {
        const variant = try parser.createVariant(Variant.IntegerLiteral);
        const str = parser.tokenString(arg1);
        var value: isize = 0;
        var signed: bool = str[0] == '-';
        // TODO: integer overflow
        for(str) |c| {
            if(c == '-') continue;
            value = value*10 + (@bitCast(i8, c)-'0');
        }
        variant.value = if(signed) -value else value;
        result = &variant.base;
    }
    fn Element(Object: *Variant) *Variant;
    fn Element(Array: *Variant) *Variant;
};

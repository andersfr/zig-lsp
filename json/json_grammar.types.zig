const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;

const Token = @import("json_grammar.tokens.zig").Token;
pub const TokenIndex = *Token;

const FlatHash = @import("../zig-flat-hash/flat_hash.zig");

usingnamespace FlatHash;

pub const VariantList = std.ArrayList(*Variant);
pub const VariantMap = Dictionary(*Variant);

pub const Variant = struct {
    id: Id,

    pub const Id = enum {
        Object,
        Array,
        IntegerLiteral,
        StringLiteral,
        BoolLiteral,
        NullLiteral,
    };

    pub fn getByName(self: *Variant, name: []const u8) ?*Variant {
        const obj = self.cast(Variant.Object) orelse return null;
        return obj.getByName(name);
    }

    pub fn getString(self: *Variant) ?[]const u8 {
        const obj = self.cast(Variant.StringLiteral) orelse return null;
        return obj.value;
    }

    pub fn getInteger(self: *Variant) ?isize {
        const obj = self.cast(Variant.IntegerLiteral) orelse return null;
        return obj.value;
    }

    pub fn getBool(self: *Variant) ?bool {
        const obj = self.cast(Variant.BoolLiteral) orelse return null;
        return obj.value;
    }

    pub fn cast(base: *Variant, comptime T: type) ?*T {
        if (base.id == comptime typeToId(T)) {
            return @fieldParentPtr(T, "base", base);
        }
        return null;
    }

    pub fn unsafe_cast(base: *Variant, comptime T: type) *T {
        return @fieldParentPtr(T, "base", base);
    }

    pub fn typeToId(comptime T: type) Id {
        comptime var i = 0;
        inline while (i < @memberCount(Id)) : (i += 1) {
            if (T == @field(Variant, @memberName(Id, i))) {
                return @field(Id, @memberName(Id, i));
            }
        }
        unreachable;
    }

    fn indentation(n: usize) void {
        var i: usize = 0;
        while(i < n) : (i += 1)
            warn(" ");
    }

    pub fn dump(self: *Variant, indent: usize) void {
        switch(self.id) {
            .NullLiteral => {
                warn("null");
            },
            .BoolLiteral => {
                if(self.unsafe_cast(Variant.BoolLiteral).value) warn("true") else warn("false");
            },
            .IntegerLiteral => {
                warn("{}", self.unsafe_cast(Variant.IntegerLiteral).value);
            },
            .StringLiteral => {
                warn("\"");
                const slice = self.unsafe_cast(Variant.StringLiteral).value;
                var i: usize = 0;
                while(i < slice.len) : (i += 1) {
                    if(slice[i] == '"' or slice[i] == '\\') warn("\\");
                    warn("{}", slice[i..i+1]);
                }
                warn("\"");
            },
            .Object => {
                warn("{}", "{");
                var it = self.unsafe_cast(Variant.Object).fields.iterator();
                var first: bool = true;
                while(it.next()) |kv| {
                    if(!first) {
                        warn(",\n");
                    }
                    else {
                        warn("\n");
                        first = false;
                    }
                    indentation(indent+2);
                    warn("\"{}\" : ", kv.key);
                    kv.value.dump(indent+2);
                }
                if(!first) {
                    warn("\n");
                    indentation(indent);
                }
                warn("{}", "}");
            },
            .Array => {
                warn("[");
                var it = self.unsafe_cast(Variant.Array).elements.iterator();
                var first: bool = true;
                while(it.next()) |element| {
                    if(!first) {
                        warn(",\n");
                    }
                    else {
                        warn("\n");
                        first = false;
                    }
                    indentation(indent+2);
                    element.dump(indent+2);
                }
                if(!first) {
                    warn("\n");
                    indentation(indent);
                }
                warn("]");
            }
        }
    }

    pub const Object = struct {
        base: Variant,
        fields: VariantMap,

        pub fn getByName(self: *Variant.Object, name: []const u8) ?*Variant {
            const kv = self.fields.find(name) orelse return null;
            return kv.value;
        }
    };

    pub const Array = struct {
        base: Variant,
        elements: VariantList,
    };

    pub const StringLiteral = struct {
        base: Variant,
        value: []u8,
    };

    pub const IntegerLiteral = struct {
        base: Variant,
        value: i64,
    };

    pub const BoolLiteral = struct {
        base: Variant,
        value: bool,
    };

    pub const NullLiteral = struct {
        base: Variant,
    };
};

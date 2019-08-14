const std = @import("std");
const warn = std.debug.warn;
const assert = std.debug.assert;

const FlatHash = @import("../zig-flat-hash/flat_hash.zig");
const IndexMap = @import("../zig-flat-hash/index_map.zig");

usingnamespace FlatHash;
usingnamespace IndexMap;

const YesNoMaybe = enum { Maybe = 0, Yes = 1, No = 2 };

const ArrayList = std.ArrayList;

fn varToStr(b: var) []const u8 {
    switch(@typeOf(b)) {
        bool => {
            if(b) return "+";
            return "-";
        },
        YesNoMaybe => switch(b) {
            .Yes => return "+",
            .No => return "-",
            .Maybe => return "?",
        },
        else => unreachable,
    }
}

pub const SymbolType = struct {
    name: []const u8,
    optional: bool,
};

pub const PrecedenceType = struct {
    value: usize,
    left: bool,
};

pub const PrecedenceMap = Dictionary(PrecedenceType);

pub const Production = struct {
    terminal: []const u8,
    terminal_type: SymbolType,
    symbols: ArrayList([]const u8),
    symbol_ids: []usize = [0]usize{},
    symbol_types: ArrayList(SymbolType),
    terminal_id: usize = 0,
    consumes: usize = 0,
    body: []const u8 = "",
    nullable: YesNoMaybe = .Maybe,
    shadowed: bool = false,
    precedence_value: isize = 0,
    precedence_left: bool = true,

    const Self = @This();

    pub fn init(allocator: *std.mem.Allocator, terminal: []const u8, terminal_type: SymbolType) Self {
        // Only store allocator in the ArrayList and pull the pointer when needed
        return Self{ .terminal = terminal, .terminal_type = terminal_type, .symbols = ArrayList([]const u8).init(allocator), .symbol_types = ArrayList(SymbolType).init(allocator), };
    }

    pub fn deinit(self: *Self) void {
        if(self.symbol_ids.len > 0) {
            self.symbols.allocator.free(self.symbol_ids);
        }
        self.symbols.deinit();
        self.symbol_types.deinit();
    }

    pub fn append(self: *Self, symbol: []const u8, precedence: ?[]const u8, precedence_value: usize, left: bool, type_info: SymbolType) !void {
        if(precedence) |p| {
            if(std.mem.compare(u8, p, "Shadow") == .Equal) {
                self.shadowed = true;
            }
            else {
                self.precedence_value = @bitCast(isize, precedence_value);
                self.precedence_left = left;
            }
        }

        try self.symbols.append(symbol);
        try self.symbol_types.append(type_info);
    }

    pub fn finalize(self: *Self) !void {
        // How many symbols does this production consume?
        self.consumes = self.symbols.len;

        // Check if production is nullable
        if(self.symbols.len == 0) {
            // Traditionally represented in litterature as the greek Epsilon
            try self.append("$epsilon", null, 0, true, SymbolType{ .name = "$epsilon", .optional = true });
            self.nullable = .Yes;
        }
        self.symbol_ids = try self.symbols.allocator.alloc(usize, self.symbols.len);
    }

    pub fn debugToFile(self: Self, grammar: *const Grammar, file: *std.fs.File.OutStream) !void {
        // try file.stream.print("{} ", varToStr(self.nullable));
        try file.stream.print("{}[#{}] <-", self.terminal, self.terminal_id);
        for(self.symbol_ids) |id,i| {
            if(id >= grammar.epsilon_index) {
                try file.stream.print(" {}[{}]", self.symbols.at(i), id - grammar.epsilon_index);
            }
            else {
                try file.stream.print(" {}[#{}]", self.symbols.at(i), id);
            }
        }
        try file.stream.write("\n");
    }

    pub fn debug(self: Self, grammar: *const Grammar) void {
        warn("{} ", varToStr(self.nullable));
        self.debugWithDot(grammar, ~@intCast(usize, 0));
    }

    pub fn debugWithDot(self: Self, grammar: *const Grammar, dot: usize) void {
        if(grammar.isSpecial(self.terminal_id)) {
            warn("\x1b[35m{}\x1b[0m[{}] <-", self.terminal, self.terminal_id);
        }
        else {
            warn("\x1b[34m{}\x1b[0m[{}] <-", self.terminal, self.terminal_id);
        }
        for(self.symbol_ids) |id,i| {
            if(i == dot) {
                warn(" .");
            }
            if(grammar.isSpecial(id)) {
                warn(" \x1b[35m{}\x1b[0m[{}]", self.symbols.at(i), id);
            }
            else if(grammar.isTerminal(id)) {
                warn(" \x1b[34m{}\x1b[0m[{}]", self.symbols.at(i), id);
            }
            else {
                warn(" \x1b[90m{}\x1b[0m[{}]", self.symbols.at(i), id);
            }
        }
        if(self.symbol_ids.len == dot) {
            warn(" .");
        }
        warn("\n");
    }
};

pub const Grammar = struct {
    allocator: *std.mem.Allocator,
    productions: ArrayList(*Production),
    names_index_map: StringIndexMap(usize),
    epsilon_index: usize = 0,
    grammar_name: []const u8,
    transitions: ArrayList([]i32),

    const Self = @This();

    pub fn init(allocator: *std.mem.Allocator, name: []const u8) Self {
        return Self{
            .allocator = allocator,
            .productions = ArrayList(*Production).init(allocator),
            .names_index_map = StringIndexMap(usize).init(allocator),
            .grammar_name = name,
            .transitions = ArrayList([]i32).init(allocator),
            };
    }

    pub fn deinit(self: *Self) void {
        // Cleanup productions and free them
        {
            var it = self.productions.iterator();
            while(it.next()) |production| {
                production.deinit();
                self.allocator.destroy(production);
            }
        }
        // Cleanup the list holding the productions
        self.productions.deinit();
        // Cleanup the index map
        self.names_index_map.deinit();
        // Cleanup the transitions
        {
            var it = self.transitions.iterator();
            while(it.next()) |transition| {
                self.allocator.free(transition);
            }
            self.transitions.deinit();
        }
    }

    pub fn append(self: *Self, production: *Production) !void {
        // The first terminal encountered is considered the initial production
        if (self.productions.len == 0) {
            // Augment the grammar with rule: $accept <- `initial` $eof
            try self.augment(production.terminal, production.terminal_type);
        }

        // Allow the production to set internal fields
        try production.finalize();

        // Append the production
        try self.productions.append(production);
    }

    pub fn finalize(self: *Self, precedence_map: ?PrecedenceMap) !void {
        // Iterate all productions and add their terminal symbol to the index mapping
        var it = self.productions.iterator();
        while(it.next()) |production| {
            production.terminal_id = try self.names_index_map.insert(production.terminal);
        }
        // Explicitly add epsilon symbol to make it the first non-terminal symbol indexed
        self.epsilon_index = try self.names_index_map.insert("$epsilon");
        // Explicitly add eof symbol to make it the second non-terminal symbol indexed
        _ = try self.names_index_map.insert("$eof");

        // Iterate again but this time add the symbols to get non-terminals into the mapping
        it.reset();
        while(it.next()) |production| {
            var sit = production.symbols.iterator();
            var i: usize = 0;
            while(sit.next()) |symbol| : (i += 1)  {
                // Store the mapped ids to avoid dealing with strings all together
                const symbol_id = try self.names_index_map.insert(symbol);
                production.symbol_ids[i]  = symbol_id;
                // Productions with non-terminals cannot be nullable
                if(self.isNonterminal(symbol_id) and symbol_id != self.epsilon_index) {
                    production.nullable = .No;
                }
            }
        }

        var symbol_precedence: []isize = try self.allocator.alloc(isize, self.names_index_map.lookup.size);
        defer self.allocator.free(symbol_precedence);

        std.mem.set(isize, symbol_precedence, 0);
        if(precedence_map) |map| {
            var mit = map.iterator();
            while(mit.next()) |kv| {
                if(self.names_index_map.indexOf(kv.key)) |index| {
                    symbol_precedence[index] = if(kv.value.left) @bitCast(isize, kv.value.value) else -@bitCast(isize, kv.value.value);
                }
            }
        }

        // Calculate which productions and terminals have the nullability property
        const terminal_nullability = try nullabilityPass(self);
        defer self.allocator.free(terminal_nullability);

        // Calculate the first and follow sets
        const follow_sets = try followSetPass(self, terminal_nullability);
        defer {
            for(follow_sets) |*follow_set| {
                follow_set.deinit();
            }
            self.allocator.free(follow_sets);
        }

        // Build the isocore set
        self.transitions = try isocorePass(self, terminal_nullability, follow_sets, symbol_precedence);

        // Optimize gotos
        try shortcutPass(self);
    }

    pub fn terminalCount(self: Self) usize {
        return self.epsilon_index;
    }

    pub fn debugToFile(self: *const Self, file: *std.fs.File.OutStream) !void {
        var it = self.productions.iterator();
        var i: usize = 0;
        while(it.next()) |production| : (i += 1) {
            try file.stream.print("{}: ", i);
            try production.debugToFile(self, file);
        }
    }

    pub fn debug(self: *const Self) void {
        warn("{}\n", self.grammar_name);
        var it = self.productions.iterator();
        while(it.next()) |production| {
            production.debug(self);
        }
        warn("\n");
    }

    fn augment(self: *Self, name: []const u8, terminal_type: SymbolType) !void {
        // Augmenting a grammar means that it gets the special rule: $accept <- `initial` $eof
        var production = try self.allocator.create(Production);
        production.* = Production.init(self.allocator, "$accept", terminal_type);
        errdefer production.deinit();

        // Build the production
        try production.append(name, null, 0, true, terminal_type);
        try production.append("$eof", null, 0, true, SymbolType{ .name = "$eof", .optional = false });
        try production.finalize();

        // Append it to the grammar
        try self.productions.append(production);
    }

    fn isTerminal(self: Self, index: usize) bool {
        return index < self.epsilon_index;
    }

    fn isNonterminal(self: Self, index: usize) bool {
        return index >= self.epsilon_index;
    }

    fn isSpecial(self: Self, index: usize) bool {
        return self.names_index_map.keyOf(index)[0] == '$';
    }

    pub fn getTerminalNullProduction(self: Self, symbol: usize) usize {
        // Check for symbol <- $epsilon
        var null_production_id: usize = 0;
        while(null_production_id < self.productions.len) : (null_production_id += 1) {
            const null_production = self.productions.items[null_production_id];
            if(null_production.terminal_id == symbol and null_production.symbol_ids[0] == self.epsilon_index) {
                return null_production_id;
            }
        }
        // Check for symbol <- S, where S is nullable
        null_production_id = 0;
        while(null_production_id < self.productions.len) : (null_production_id += 1) {
            const null_production = self.productions.items[null_production_id];
            const null_symbol_id = null_production.symbol_ids[0];
            if(null_production.terminal_id == symbol and null_symbol_id != symbol and self.isTerminal(null_symbol_id) and null_production.nullable == .Yes) {
                return self.getTerminalNullProduction(null_symbol_id);
            }
        }
        return 0;
    }
};

fn nullabilityPass(grammar: *Grammar) ![]YesNoMaybe {
    // Allocate temporary memory for performing the calculation
    var terminal_nullability: []YesNoMaybe = try grammar.allocator.alloc(YesNoMaybe, grammar.terminalCount()+1);
    errdefer grammar.allocator.free(terminal_nullability);

    // Initialy every terminal is unknown
    for(terminal_nullability) |*tn| {
        tn.* = .Maybe;
    }
    // Consider $epsilon as nullable (by definition)
    terminal_nullability[grammar.epsilon_index] = .Yes;

    // Trivial implementation loops over all productions until no further progress can be made
    var changed: bool = false;
    while(true) : (changed = false) {
        var pit = grammar.productions.iterator();
        while(pit.next()) |production| {
            // Production is known to be nullable, e.g. trivial or already computed
            if(production.nullable == .Yes) {
                if(terminal_nullability[production.terminal_id] != .Yes) {
                    terminal_nullability[production.terminal_id] = .Yes;
                    changed = true;
                }
                continue;
            }
            // Production is known not to be nullable, e.g. contains non-terminals
            else if(production.nullable == .No) {
                continue;
            }
            // Check if production is made entirely of nullable terminals
            var early_exit: bool = false;
            for(production.symbol_ids) |symbol_id| {
                if(terminal_nullability[symbol_id] == .No) {
                    terminal_nullability[production.terminal_id] = .No;
                    production.nullable = .No;
                    changed = true;
                    early_exit = true;
                    break;
                }
                else if(terminal_nullability[symbol_id] == .Maybe) {
                    early_exit = true;
                    break;
                }
            }
            // Production is indeed nullable through all its symbols
            if(!early_exit) {
                terminal_nullability[production.terminal_id] = .Yes;
                production.nullable = .Yes;
                changed = true;
            }
        }
        // No further progress can be made, i.e. solution is stable
        if(!changed) {
            // Maybe must now be converted to No
            pit.reset();
            while(pit.next()) |production| {
                if(production.nullable == .Maybe) {
                    production.nullable = .No;
                }
            }
            // Nullability pass is complete
            break;
        }
    }
    return terminal_nullability;
}

fn hashInt32(v: i32) u32 {
    return std.hash.Murmur3_32.hashUint32(@bitCast(u32, v));
}

const FirstFollowSet = FlatHash.Set(i32, null, hashInt32, null);
const TerminalChainSet = FirstFollowSet;

fn followSetPass(grammar:  *Grammar, terminal_nullability: []YesNoMaybe) ![]FirstFollowSet {
    // Allocate temporary memory for performing the calculation
    var first_sets = try grammar.allocator.alloc(FirstFollowSet, grammar.terminalCount());
    // Cleanup of self and its containing items
    defer {
        for(first_sets) |*first_set| {
            first_set.deinit();
        }
        grammar.allocator.free(first_sets);
    }

    // Initialize all the sets
    for(first_sets) |*first_set| {
        first_set.* = FirstFollowSet.init(grammar.allocator);
    }

    // Allocate temporary memory for performing the calculation
    var follow_sets = try grammar.allocator.alloc(FirstFollowSet, grammar.terminalCount());
    // Cleanup of self and its containing items
    errdefer {
        for(follow_sets) |*follow_set| {
            follow_set.deinit();
        }
        grammar.allocator.free(follow_sets);
    }

    // Initialize all the sets
    for(follow_sets) |*follow_set| {
        follow_set.* = FirstFollowSet.init(grammar.allocator);
    }

    // Allocate temporary memory for performing the calculation
    var terminal_chains = try grammar.allocator.alloc(TerminalChainSet, grammar.terminalCount());
    // Cleanup of self and its containing items
    defer {
        for(terminal_chains) |*terminal_chain| {
            terminal_chain.deinit();
        }
        grammar.allocator.free(terminal_chains);
    }

    // Initialize all the sets
    for(terminal_chains) |*terminal_chain| {
        terminal_chain.* = TerminalChainSet.init(grammar.allocator);
    }

    // Initialize first sets for all productions
    var pit = grammar.productions.iterator();
    while(pit.next()) |production| {
        // Reference to first set associated with current production
        const first_set = &first_sets[production.terminal_id];
        // Grab the first symbol, and if it is nullable, next symbol must also be considered
        for(production.symbol_ids) |symbol_id| {
            // Insert if not epsilon
            if(symbol_id != grammar.epsilon_index) {
                _ = try first_set.insert(@intCast(i32, symbol_id));
            }
            // Check nullability property
            if(grammar.isTerminal(symbol_id) and terminal_nullability[symbol_id] == .Yes)
                continue;
            // Default is to grab only first symbol
            break;
        }
        // Iterate once more to deal with terminal chains
        var i: usize = 0;
        while(i < production.symbol_ids.len) : (i += 1) {
            const symbol_id = production.symbol_ids[i];

            // If a production ends in a terminal that becomes a recursive chain
            if(i+1 == production.symbol_ids.len) {
                if(grammar.isTerminal(symbol_id)) {
                    _ = try terminal_chains[symbol_id].insert(-@intCast(i32, production.terminal_id));
                }
                break;
            }

            const next_symbol_id = production.symbol_ids[i+1];

            // Record the terminal chain
            if(grammar.isTerminal(symbol_id) and grammar.isTerminal(next_symbol_id)) {
                _ = try terminal_chains[symbol_id].insert(@intCast(i32, next_symbol_id));
            }

            // Extend first set of nullable terminals with immediate successor non-terminal
            if(grammar.isTerminal(symbol_id) and terminal_nullability[symbol_id] == .Yes and !grammar.isTerminal(next_symbol_id)) {
                _ = try first_sets[symbol_id].insert(@intCast(i32, next_symbol_id));
            }
        }
    }

    // Converge the terminal chains
    while(true) {
        var has_changed: bool = false;

        var current_terminal: usize = 0;
        while(current_terminal < terminal_chains.len) : (current_terminal += 1) {
            const terminal_chain = &terminal_chains[current_terminal];
            invalidated: while(true) {
                var it = terminal_chain.iterator();
                while(it.next()) |kv| {
                    // Negative key means it terminated a production of a terminal
                    if(kv.key < 0) {
                        const target_terminal: usize = @bitCast(u32, -kv.key);
                        const target_chain = &terminal_chains[target_terminal];
                        if(current_terminal == target_terminal)
                            continue;

                        // Propagate terminal chains
                        var tit = target_chain.iterator();
                        while(tit.next()) |tkv| {
                            if(tkv.key >= 0) {
                                const result = try terminal_chain.insert(tkv.key);
                                if(result.is_new) {
                                    has_changed = true;
                                    continue :invalidated;
                                }
                            }
                        }
                    }
                    else {
                        // Propagate terminal chains through nullability
                        const target_terminal: usize = @bitCast(u32, kv.key);
                        if(terminal_nullability[target_terminal] == .Yes) {
                            const target_chain = &terminal_chains[target_terminal];
                            if(current_terminal == target_terminal)
                                continue;

                            var tit = target_chain.iterator();
                            while(tit.next()) |tkv| {
                                const result = try terminal_chain.insert(tkv.key);
                                if(result.is_new) {
                                    has_changed = true;
                                    continue :invalidated;
                                }
                            }
                        }
                    }
                }
                break :invalidated;
            }
        }

        if(!has_changed)
            break;
    }

    // Converge the first sets
    while(true) {
        var has_changed: bool = false;

        for(first_sets) |*first_set| {
            // Invalidation of iterator may occur because the current set is being expanded
            invalidated: while(true) {
                var it = first_set.iterator();
                while(it.next()) |kv| {
                    const ukey = @bitCast(u32, kv.key);
                    if(grammar.isTerminal(ukey)) {
                        var is_invalidated: bool = false;
                        var fit = first_sets[ukey].iterator();
                        while(fit.next()) |fkv| {
                            const ufkey = @bitCast(u32, fkv.key);
                            if(!grammar.isTerminal(ufkey) and ufkey != grammar.epsilon_index) {
                                const result = try first_set.insert(fkv.key);
                                if(result.is_new)
                                    is_invalidated = true;
                            }
                        }
                        if(is_invalidated) {
                            has_changed = true;
                            continue :invalidated;
                        }
                    }
                }

                break :invalidated;
            }
        }

        if(!has_changed)
            break;
    }

    // Expand nullable terminals in first sets
    while(true) {
        var has_changed: bool = false;

        var current_first_set: usize = 0;
        while(current_first_set < first_sets.len) : (current_first_set += 1) {
            if(terminal_nullability[current_first_set] != .Yes)
                continue;

            const first_set = &first_sets[current_first_set];
            var it = terminal_chains[current_first_set].iterator();
            while(it.next()) |kv| {
                const key = @bitCast(u32, kv.key);

                if(kv.key < 0 or key == current_first_set)
                    continue;

                var fit = first_sets[key].iterator();
                while(fit.next()) |fkv| {
                    const result = try first_set.insert(fkv.key);
                    has_changed = has_changed or result.is_new;
                }
            }
        }

        if(!has_changed)
            break;
    }

    // Build follow sets
    pit = grammar.productions.iterator();
    while(pit.next()) |production| {
        var current_symbol: usize = 0;
        while(current_symbol+1 < production.symbol_ids.len) : (current_symbol += 1) {
            const symbol_id = production.symbol_ids[current_symbol];
            const next_symbol_id = production.symbol_ids[current_symbol+1];

            if(grammar.isTerminal(symbol_id) and !grammar.isTerminal(next_symbol_id)) {
                _ = try follow_sets[symbol_id].insert(@intCast(i32, next_symbol_id));
            }
            else if(grammar.isTerminal(symbol_id) and grammar.isTerminal(next_symbol_id)) {
                var fit = first_sets[next_symbol_id].iterator();
                while(fit.next()) |fkv| {
                    const fkey = @bitCast(u32, fkv.key);

                    if(!grammar.isTerminal(fkey))
                        _ = try follow_sets[symbol_id].insert(fkv.key);
                }
            }
        }
    }

    // Expand follow sets with terminal chains
    while(true) {
        var changed: bool = false;
        for(terminal_chains) |terminal_chain,current_terminal| {
            var it = terminal_chain.iterator();
            while(it.next()) |kv| {
                if(kv.key < 0) {
                    const follow_set = &follow_sets[current_terminal];
                    var fit = follow_sets[@bitCast(u32, -kv.key)].iterator();
                    while(fit.next()) |fkv| {
                        const result = try follow_set.insert(fkv.key);
                        changed = changed or result.is_new;
                    }
                }
                else {
                    const follow_set = &follow_sets[current_terminal];
                    var fit = first_sets[@bitCast(u32, kv.key)].iterator();
                    while(fit.next()) |fkv| {
                        if(!grammar.isTerminal(@bitCast(u32, fkv.key))) {
                            const result = try follow_set.insert(fkv.key);
                            changed = changed or result.is_new;
                        }
                    }
                }
            }
        }
        if(!changed) break;
    }

    // for(terminal_chains) |terminal_chain,i| {
    //     warn("Terminal chain ([{}]{}):", i, grammar.names_index_map.keyOf(i));
    //     var it = terminal_chain.iterator();
    //     while(it.next()) |kv| {
    //         if(kv.key < 0) {
    //             // warn(" [{}]{},", kv.key, grammar.names_index_map.keyOf(@bitCast(u32, -kv.key)));
    //         }
    //         else {
    //             warn(" [{}]{},", kv.key, grammar.names_index_map.keyOf(@bitCast(u32, kv.key)));
    //         }
    //     }
    //     warn("\n");
    // }

    // for(first_sets) |first_set,i| {
    //     warn("First set ({}):", grammar.names_index_map.keyOf(i));
    //     var it = first_set.iterator();
    //     while(it.next()) |kv| {
    //         if(!grammar.isTerminal(@bitCast(u32, kv.key)))
    //             warn(" [{}]{},", kv.key, grammar.names_index_map.keyOf(@bitCast(u32, kv.key)));
    //     }
    //     warn("\n");
    // }

    // for(follow_sets) |follow_set,i| {
    //     warn("Follow set ({}):", grammar.names_index_map.keyOf(i));
    //     var it = follow_set.iterator();
    //     while(it.next()) |kv| {
    //        warn(" [{}]{},", kv.key, grammar.names_index_map.keyOf(@bitCast(u32, kv.key)));
    //     }
    //     warn("\n");
    // }

    return follow_sets;
}

const IsocorePair = struct {
    production_id: u32,
    symbol_index: u32,

    const Self = @This();

    pub fn init(production_id: u32, symbol_index: u32) Self {
        return Self{ .production_id = production_id, .symbol_index = symbol_index };
    }

    pub fn hash(self: Self) u32 {
        const upper = @intCast(u64, self.production_id) << 32;
        const lower = @intCast(u64, self.symbol_index);

        return std.hash.Murmur3_32.hashUint64(upper | lower);
    }

    pub fn equal(p1: Self, p2: Self) bool {
        return p1.production_id == p2.production_id and p1.symbol_index == p2.symbol_index;
    }
};

const IsocorePairSet = FlatHash.Set(IsocorePair, null, IsocorePair.hash, IsocorePair.equal);

fn isocorePass(grammar: *Grammar, terminal_nullability: []YesNoMaybe, follow_sets: []FirstFollowSet, precedence: []isize) !ArrayList([]i32) {
    // Counters for conflict types
    var shift_reduce_conflicts: usize = 0;
    var reduce_reduce_conflicts: usize = 0;

    // Isocores holds all the states that are being built
    var isocores = ArrayList(IsocorePairSet).init(grammar.allocator);
    // Cleanup of self and its containing items
    defer {
        var it = isocores.iterator();
        while(it.next()) |*isocore| {
            isocore.deinit();
        }
        isocores.deinit();
    }

    // Fullcores holds all the full states that are being built
    var fullcores = ArrayList(IsocorePairSet).init(grammar.allocator);
    // Cleanup of self and its containing items
    defer {
        var it = fullcores.iterator();
        while(it.next()) |*fullcore| {
            fullcore.deinit();
        }
        fullcores.deinit();
    }

    // Transitions holds the shift and goto transitions between isocore states
    var transitions = ArrayList([]i32).init(grammar.allocator);
    // Cleanup of self and its containing items
    errdefer {
        var it = transitions.iterator();
        while(it.next()) |transition| {
            grammar.allocator.free(transition);
        }
        transitions.deinit();
    }

    // Initialize in own block for correct errdefer scoping
    {
        // Initialize the accepting isocore set
        var accept_set = IsocorePairSet.init(grammar.allocator);
        errdefer accept_set.deinit();

        // Insert $accept <- . `initial` $eof
        _ = try accept_set.insert(IsocorePair.init(0, 0));

        // Append to the isocores set
        _ = try isocores.append(accept_set);
    }

    // Initialize transitions for initial isocore
    {
        // Allocate room for all terminals and non-terminals
        const slice = try grammar.allocator.alloc(i32, grammar.names_index_map.size());
        errdefer grammar.allocator.free(slice);

        // It is impossible to transition into the initial isocore state
        std.mem.set(i32, slice, 0);

        // Append it to the transitions list
        try transitions.append(slice);
    }

    // The isocores are expanded during processing - allocate once for efficiency
    var expansion_core = IsocorePairSet.init(grammar.allocator);
    defer expansion_core.deinit();

    // Temporary set for building transitions
    var transition_core = IsocorePairSet.init(grammar.allocator);
    defer transition_core.deinit();

    // Process the isocores sequentially as they are built
    // Note: uses indexing to avoid iterator invalidation
    var current_isocore: usize = 0;
    while(current_isocore < isocores.len) : (current_isocore += 1) {
        // Reset the expansion and copy the current isocore
        expansion_core.reset();
        {
            // Isocore pair copying
            var pit = isocores.at(current_isocore).iterator();
            while(pit.next()) |kv| {
                _ = try expansion_core.insert(kv.key);
            }
        }

        // Expand until convergence (note: this can be optimized with a queue)
        while(true) {
            var changed: bool = false;
            // Try to expand every production in the core
            var pit = expansion_core.iterator();
            while(pit.next()) |kv| {
                const pair = kv.key;
                const production = grammar.productions.at(pair.production_id);
                // Check that it is within bounds (dot can follow last symbol)
                if(pair.symbol_index < production.symbol_ids.len) {
                    // Check that a terminal is following (non-terminals have no expansion)
                    const symbol_id = production.symbol_ids[pair.symbol_index];
                    if(grammar.isTerminal(symbol_id)) {
                        // Try to insert all productions that can produce this terminal
                        var i: usize = 0;
                        while(i < grammar.productions.len) : (i += 1) {
                            const nested_production = grammar.productions.at(i);
                            if(nested_production.terminal_id == symbol_id) {
                                const result = try expansion_core.insert(IsocorePair.init(@intCast(u32, i), 0));
                                // Record whether or not the core expanded
                                changed = changed or result.is_new;
                            }
                        }
                    }
                }
                // If expanded the iterators may have been invalidated
                if(changed) break;
            }
            // Expansion core has converged
            if(!changed) break;
        }

        // Build transitions for this isocore
        {
            // Visit every expansion and build its transitions
            var pit = expansion_core.iterator();
            outer: while(pit.next()) |kv| {
                const pair = kv.key;
                const production = grammar.productions.at(pair.production_id);
                const transition = transitions.at(current_isocore);

                // Completed productions cannot transition
                if(pair.symbol_index >= production.symbol_ids.len)
                    continue;

                const transition_symbol = production.symbol_ids[pair.symbol_index];

                // Transition already processed or is special, i.e. $accept, $epsilon, $eof
                if(grammar.isSpecial(transition_symbol) or transition[transition_symbol] != 0)
                    continue;

                // Prepare temporary transition core
                transition_core.reset();
                _ = try transition_core.insert(IsocorePair.init(pair.production_id, pair.symbol_index+1));

                var tit = pit;
                while(tit.next()) |tkv| {
                    const tpair = tkv.key;
                    const tproduction = grammar.productions.at(tpair.production_id);

                    // Completed productions cannot transition
                    if(tpair.symbol_index >= tproduction.symbol_ids.len)
                        continue;

                    if(tproduction.symbol_ids[tpair.symbol_index] == transition_symbol) {
                        _ = try transition_core.insert(IsocorePair.init(tpair.production_id, tpair.symbol_index+1));
                    }
                }

                // Check if transition core is already in the isocore set
                var iit: usize = 0;
                inner: while(iit < isocores.len) : (iit += 1) {
                    const isocore = isocores.at(iit);
                    // Number of elements must agree to be equal
                    if(isocore.size != transition_core.size)
                        continue :inner;

                    // Check if all keys from isocore is in transition core
                    var it1 = isocore.iterator();
                    while(it1.next()) |kv1| {
                        // If not they cannot be equal
                        if(!transition_core.contains(kv1.key))
                            continue :inner;
                    }

                    // Update transition table
                    transition[transition_symbol] = @intCast(i32, iit);
                    // No new isocore to add so continue in outer loop
                    continue :outer;
                }

                // Initialize in own block for correct errdefer scoping
                {
                    // Initialize the accepting isocore set
                    var new_isocore_set = IsocorePairSet.init(grammar.allocator);
                    errdefer new_isocore_set.deinit();

                    try new_isocore_set.reserve(transition_core.size);

                    var tcit = transition_core.iterator();
                    while(tcit.next()) |tckv| {
                        _ = try new_isocore_set.insert(tckv.key);
                    }

                    // Update transition table (reference not invalidated yet)
                    transition[transition_symbol] = @intCast(i32, isocores.len);

                    // Append to the isocores set
                    try isocores.append(new_isocore_set);
                }

                // Initialize transitions for new isocore
                {
                    // Allocate room for all terminals and non-terminals
                    const slice = try grammar.allocator.alloc(i32, grammar.names_index_map.size());
                    errdefer grammar.allocator.free(slice);

                    // It is impossible to transition into the initial isocore state
                    std.mem.set(i32, slice, 0);

                    // Append it to the transitions list
                    try transitions.append(slice);
                }
            }

            // Build fullcore as a copy of the expansion core
            {
                // Initialize the accepting isocore set
                var new_core_set = IsocorePairSet.init(grammar.allocator);
                errdefer new_core_set.deinit();

                try new_core_set.reserve(expansion_core.size);

                var tcit = expansion_core.iterator();
                while(tcit.next()) |tckv| {
                    _ = try new_core_set.insert(tckv.key);
                }

                try fullcores.append(new_core_set);
            }

           // warn("Expansion core {}:\n------------\n", current_isocore);
           // {
           //     var tcit = expansion_core.iterator();
           //     while(tcit.next()) |tckv| {
           //         const tcpair = tckv.key;
           //         warn("{} ", tcpair.production_id);
           //         grammar.productions.at(tcpair.production_id).debugWithDot(grammar, tcpair.symbol_index);
           //     }
           // }
        }
    }

    current_isocore = 0;
    while(current_isocore < isocores.len) : (current_isocore += 1) {
        warn("Isocore {}:\n------------\n", current_isocore);
        {
            var pit = isocores.at(current_isocore).iterator();
            // var pit = fullcores.at(current_isocore).iterator();
            while(pit.next()) |kv| {
                const pair = kv.key;
                warn("{} ", pair.production_id);
                grammar.productions.at(pair.production_id).debugWithDot(grammar, pair.symbol_index);
            }
        }
        warn("\n");
        var has_conflicts: bool = false;
        var iit = fullcores.items[current_isocore].iterator();
        while(iit.next()) |kv| {
            const pair = kv.key;
            const production = grammar.productions.items[pair.production_id];
            const transition = transitions.items[current_isocore];

            if(pair.symbol_index == production.symbol_ids.len) {
                var fit = follow_sets[production.terminal_id].iterator();
                while(fit.next()) |fkv| {
                    const key = @bitCast(u32, fkv.key);
                    if(grammar.isTerminal(key))
                        continue;
                    if(transition[key] == 0) {
                        transition[key] = -@intCast(i32, pair.production_id);
                    }
                    else if(transition[key] > 0) {
                        if(!resolveShiftReducePass(grammar, &isocores.items[current_isocore], pair.production_id)) {
                            if(production.precedence_value != 0 and precedence[key] != 0) {
                                // Resolve with precedence
                                if(production.precedence_left) {
                                    if(precedence[key] > 0) {
                                        // left vs left
                                        if(production.precedence_value >= precedence[key]) {
                                            // reduce
                                            transition[key] = -@intCast(i32, pair.production_id);
                                        }
                                    }
                                    else {
                                        // left vs right
                                        if(production.precedence_value >= -precedence[key]) {
                                            // reduce
                                            transition[key] = -@intCast(i32, pair.production_id);
                                        }
                                    }
                                }
                                else {
                                    if(precedence[key] > 0) {
                                        // right vs left
                                        if(production.precedence_value >= precedence[key]) {
                                            // reduce
                                            transition[key] = -@intCast(i32, pair.production_id);
                                        }
                                    }
                                    else {
                                        // right vs right
                                        if(production.precedence_value > -precedence[key]) {
                                            // reduce
                                            transition[key] = -@intCast(i32, pair.production_id);
                                        }
                                    }
                                }
                            }
                            else if(production.precedence_value != 0 or precedence[key] != 0) {
                                // shift when precedence is missing
                            }
                            else {
                                warn("\x1b[31mShift-Reduce conflict:\x1b[0m s{} vs r{} on symbol {}\n", transition[key], pair.production_id, grammar.names_index_map.keyOf(key));
                                shift_reduce_conflicts += 1;
                                has_conflicts = true;
                            }
                        }
                        else {
                            warn("\x1b[31mResolved Shift-Reduce conflict:\x1b[0m s{} vs r{} on symbol {}\n", transition[key], pair.production_id, grammar.names_index_map.keyOf(key));
                        }
                    }
                    else {
                        const tkey = @bitCast(u32, -transition[key]);
                        if(tkey != pair.production_id) {
                            if(production.shadowed) {
                                warn("\x1b[31mShadowed Reduce-Reduce conflict:\x1b[0m r{} vs r{} on symbol {} => {}\n", -transition[key], pair.production_id, grammar.names_index_map.keyOf(key), tkey);
                                const pk = -@intCast(i32, pair.production_id);
                                const tk = transition[key];
                                for(transition) |*t| {
                                    if(t.* == pk)
                                        t.* = tk;
                                }
                            }
                            else if(grammar.productions.items[tkey].shadowed) {
                                warn("\x1b[31mShadowed Reduce-Reduce conflict:\x1b[0m r{} vs r{} on symbol {} => {}\n", -transition[key], pair.production_id, grammar.names_index_map.keyOf(key), pair.production_id);
                                // transition[key] = -@intCast(i32, pair.production_id);
                                const tk = transition[key];
                                for(transition) |*t| {
                                    if(t.* == tk)
                                        t.* = -@intCast(i32, pair.production_id);
                                }
                            }
                            else {
                                const resolve = resolveReduceReducePass(grammar, @intCast(u32, -transition[key]), pair.production_id);
                                if(resolve >= 0) {
                                    warn("\x1b[31mResolved Reduce-Reduce conflict:\x1b[0m r{} vs r{} on symbol {} => {}\n", -transition[key], pair.production_id, grammar.names_index_map.keyOf(key), resolve);
                                    transition[key] = -resolve;
                                }
                                else {
                                    warn("\x1b[31mReduce-Reduce conflict:\x1b[0m r{} vs r{} on symbol {}\n", -transition[key], pair.production_id, grammar.names_index_map.keyOf(key));
                                    // Default to rule with lowest number
                                    if(tkey > pair.production_id) transition[key] = -@intCast(i32, pair.production_id);
                                    reduce_reduce_conflicts += 1;
                                    has_conflicts = true;
                                }
                            }
                        }
                    }
                }
            }
            else if(pair.symbol_index == 0 and production.symbol_ids[0] == grammar.epsilon_index) {
                const symbol = production.terminal_id;
                const null_production_id = pair.production_id;
                if(null_production_id != 0) {
                    const null_production = grammar.productions.items[null_production_id];
                    var fit = follow_sets[null_production.terminal_id].iterator();
                    while(fit.next()) |fkv| {
                        const key = @bitCast(u32, fkv.key);
                        if(grammar.isTerminal(key))
                            continue;
                        if(transition[key] == 0) {
                            transition[key] = -@intCast(i32, null_production_id);
                            // warn("nullable reduce {} {} => {}\n", grammar.names_index_map.keyOf(key), key, -transition[key]);
                        }
                        else if(transition[key] > 0) {
                            // Nullable productions cannot take precedence in a Shift-Reduce conflict resolution
                            warn("supressed conflict {}\n", grammar.names_index_map.keyOf(key));
                        }
                        else {
                            if(transition[key] != -@intCast(i32, null_production_id)) {
                                if(terminal_nullability[grammar.productions.items[@bitCast(u32, -transition[key])].terminal_id] == .Yes) {
                                    warn("\x1b[31mReduce-Reduce conflict:\x1b[0m r{} vs r{} on symbol {}\n", -transition[key], null_production_id, grammar.names_index_map.keyOf(key));
                                    reduce_reduce_conflicts += 1;
                                    has_conflicts = true;
                                }
                                else {
                                    warn("\x1b[31mNull-Reduce conflict:\x1b[0m r{} vs r{} on symbol {}\n", -transition[key], null_production_id, grammar.names_index_map.keyOf(key));
                                    transition[key] = -@intCast(i32, null_production_id);
                                    shift_reduce_conflicts += 1;
                                }
                            }
                        }
                    }
                }
            }
        }
        if(has_conflicts)
            warn("\n");

        var has_transitions: bool = false;
        var default_reduce: i32 = -1;
        for(transitions.at(current_isocore)) |t,i| {
            if(t == 0) continue;

            has_transitions = true;
            if(grammar.isTerminal(i)) {
                warn("[{}]g{}, ", i, t);
            }
            else if(t > 0) {
                warn("[{}]s{}, ", i, t);
            }
            else {
                if(default_reduce == -1) {
                    default_reduce = -t;
                }
                else if(default_reduce != -t) {
                    default_reduce = -2;
                }
            }
        }
        if(default_reduce >= 0) {
            warn("[*]r{}", default_reduce);
        }
        else {
            for(transitions.at(current_isocore)) |t,i| {
                if(t == 0) continue;

                if(!grammar.isTerminal(i) and t <= 0) {
                    warn("[{}]r{}, ", i, -t);
                }
            }
        }
        if(has_transitions)
            warn("\n\n");
    }

    if(shift_reduce_conflicts + reduce_reduce_conflicts > 0) {
        warn("Shift-Reduce conflicts: {}\n", shift_reduce_conflicts);
        warn("Reduce-Reduce conflicts: {}\n", reduce_reduce_conflicts);
        warn("\n");
    }

    return transitions;

    // // Debug
    // current_isocore = 0;
    // while(current_isocore < isocores.len) : (current_isocore += 1) {
    //     warn("Isocore {}:\n------------\n", current_isocore);
    //     {
    //         var pit = isocores.at(current_isocore).iterator();
    //         while(pit.next()) |kv| {
    //             const pair = kv.key;
    //             grammar.productions.at(pair.production_id).debugWithDot(grammar, pair.symbol_index);
    //         }
    //     }
    //     warn("\n");
    //     var has_transitions: bool = false;
    //     for(transitions.at(current_isocore)) |t,i| {
    //         if(t == 0) continue;

    //         has_transitions = true;
    //         if(grammar.isTerminal(i)) {
    //             warn("[{}]g{}, ", i, t);
    //         }
    //         else if(t > 0) {
    //             warn("[{}]s{}, ", i, t);
    //         }
    //         else {
    //             warn("[{}]r{}, ", i, -t);
    //         }
    //     }
    //     if(has_transitions)
    //         warn("\n\n");
    // }
}

fn resolveShiftReducePass(grammar: *Grammar, isocore: *IsocorePairSet, production_id: usize) bool {
    const production = grammar.productions.items[production_id];
    var good: usize = 1;
    var it = isocore.iterator();
    // Resolve as shift
    while(it.next()) |kv| {
        if(kv.key.production_id != production_id) {
            const sproduction = grammar.productions.items[kv.key.production_id];
            // Resolve as greedy shift when shift eventually produces itself as terminal
            if(production.terminal_id != sproduction.terminal_id) {
                if(sproduction.terminal_id == production.symbol_ids[production.symbol_ids.len-1]) {
                    good += 1;
                    continue;
                }
                else if(subProductionPass(grammar, kv.key.production_id, production_id)) {
                    good += 1;
                    continue;
                }
            }
        }
    }
    return good == isocore.size;
}

fn resolveReduceReducePass(grammar: *Grammar, lproduction_id: usize, rproduction_id: usize) i32 {
    if(lproduction_id > rproduction_id)
        return resolveReduceReducePass(grammar, rproduction_id, lproduction_id);
    var result: i32 = -1;
    if(subProductionPass(grammar, lproduction_id, rproduction_id))
        result = @bitCast(i32, @truncate(u32, lproduction_id));
    if(subProductionPass(grammar, rproduction_id, lproduction_id))
        result = switch(result) {
            -1 => @bitCast(i32, @truncate(u32, rproduction_id)),
            else => -1,
        };
    return result;
}

fn subProductionPass(grammar: *Grammar, lproduction_id: usize, rproduction_id: usize) bool {
    const lproduction = grammar.productions.items[lproduction_id];
    const rproduction = grammar.productions.items[rproduction_id];
    const rsymbol = rproduction.symbol_ids[rproduction.symbol_ids.len-1];
    var i: usize = 0;
    while(i < grammar.productions.len) : (i += 1) {
        if(i == lproduction_id)
            continue;

        const production = grammar.productions.items[i];

        if(production.symbol_ids.len == 1 and production.symbol_ids[0] == lproduction.terminal_id) {
            if(production.terminal_id == rsymbol)
                return true;
            if(subProductionPass(grammar, i, rproduction_id))
                return true;
        }
    }
    return false;
}

fn shortcutPass(grammar: *Grammar) !void {
    const reducers = try grammar.allocator.alloc(i32, grammar.transitions.len);
    defer grammar.allocator.free(reducers);

    var i: usize = 0;
    while(i < grammar.transitions.len) : (i += 1) {
        const transition = grammar.transitions.items[i];

        var default_reduce: i32 = -1;
        for(transition) |t,ti| {
            if(t == 0 or ti <= grammar.epsilon_index) continue;

            // if(t < 0) {
                if(default_reduce == -1) {
                    default_reduce = -t;
                }
                else if(default_reduce != -t) {
                    default_reduce = -2;
                    break;
                }
            // }
        }
        reducers[i] = blk: {
            const zero: i32 = 0;
            if(default_reduce >= 0) {
                const production = grammar.productions.items[@bitCast(u32, default_reduce)];
                if(production.body.len != 0 or production.consumes != 1)
                    break :blk zero;
                if(!grammar.isTerminal(production.symbol_ids[0]))
                    break :blk zero;
                if(std.mem.compare(u8, production.terminal_type.name, production.symbol_types.items[0].name) != .Equal)
                    break :blk zero;
                break :blk default_reduce;
            }
            break :blk zero;
        };
    }
    while(true) {
        var changed: bool = false;
        i = 0;
        while(i < grammar.transitions.len) : (i += 1) {
            const transition = grammar.transitions.items[i];

            var t: usize = 0;
            while(grammar.isTerminal(t)) : (t += 1) {
                if(transition[t] == 0) continue;
                const goto = @bitCast(u32, transition[t]);

                if(reducers[goto] != 0) {
                    const production = grammar.productions.items[@bitCast(u32, reducers[goto])];
                    transition[t] = transition[production.terminal_id];
                    changed = true;
                }
            }
        }
        if(!changed)
            break;
    }
}

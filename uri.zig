const std = @import("std");

fn parseHex(c: u8) !u8 {
    return switch(c) {
        '0'...'9' => c-'0',
        'a'...'f' => c-'a' + 10,
        'A'...'F' => c-'A' + 10,
        else => return error.UriBadHexChar,
    };
}

pub fn parse(allocator: *std.mem.Allocator, str: []const u8) ![]u8 {
    if(str.len < 7 or std.mem.compare(u8, "file://", str[0..7]) != .Equal) return error.UriBadScheme;

    var uri = try allocator.alloc(u8, str.len-7);
    errdefer allocator.free(uri);

    const path = str[7..];

    var i: usize = 0;
    var j: usize = 0;
    var e: usize = path.len;
    while(j < e) : (i += 1) {
        if(path[j] == '%') {
            if(j+2 >= e) return error.UriBadEscape;
            const upper = try parseHex(path[j+1]);
            const lower = try parseHex(path[j+2]);
            uri[i] = (upper << 4) + lower;
            j += 3;
        }
        else {
            uri[i] = if(path[j] == '/') std.fs.path.sep else path[j];
            j += 1;
        }
    }
    // Remove trailing separator
    if(i > 0 and uri[i-1] == std.fs.path.sep)
        i -= 1;

    return try allocator.realloc(uri, i);
}

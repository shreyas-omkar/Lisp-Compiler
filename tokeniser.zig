const std = @import("std");

pub fn tokenise(input: []const u8, allocator: std.mem.Allocator) ![]const []const u8 {
    var tokens = std.ArrayList([]const u8).init(allocator);
    var i: usize = 0;

    while (i < input.len) {
        const c = input[i];
        if (std.ascii.isWhitespace(c)) {
            i += 1;
            continue;
        }
        if (c == '(' or c == ')') {
            try tokens.append(input[i .. i + 1]);
            i += 1;
            continue;
        }
        const start = i;
        while (i < input.len and !std.ascii.isWhitespace(input[i]) and input[i] != '(' and input[i] != ')') {
            i += 1;
        }
        try tokens.append(input[start..i]);
    }

    return tokens.toOwnedSlice();
}

const std = @import("std");
const ast = @import("ast.zig");

pub fn parse(tokens: []const []const u8, allocator: std.mem.Allocator) !ast.Expr {
    var index: usize = 0;
    const expr = try parseExpr(tokens, &index, allocator);

    if (index != tokens.len) {
        return error.ExtraTokensAfterExpression;
    }

    return expr;
}

fn parseExpr(tokens: []const []const u8, index: *usize, allocator: std.mem.Allocator) !ast.Expr {
    if (index.* >= tokens.len) {
        return error.UnexpectedEndOfInput;
    }

    const token = tokens[index.*];
    index.* += 1;

    if (std.mem.eql(u8, token, "(")) {
        var exprs = std.ArrayList(ast.Expr).init(allocator);

        while (index.* < tokens.len and !std.mem.eql(u8, tokens[index.*], ")")) {
            try exprs.append(try parseExpr(tokens, index, allocator));
        }

        if (index.* >= tokens.len) {
            return error.MissingClosingParen;
        }

        index.* += 1; // skip closing ')'
        return ast.Expr{ .List = try exprs.toOwnedSlice() };
    } else if (std.mem.eql(u8, token, ")")) {
        return error.UnexpectedClosingParen;
    } else if (std.fmt.parseInt(i64, token, 10)) |num| {
        return ast.Expr{ .Number = num };
    } else |_| {
        return ast.Expr{ .Symbol = token };
    }
}

pub fn printExpr(expr: ast.Expr, writer: anytype) !void {
    switch (expr) {
        .Number => |n| try writer.print("{d}", .{n}),
        .Symbol => |s| try writer.print("{s}", .{s}),
        .List => |li| {
            try writer.print("(", .{});
            for (li, 0..) |item, i| {
                try printExpr(item, writer);
                if (i != li.len - 1)
                    try writer.print(" ", .{});
            }
            try writer.print(")", .{});
        },
    }
}

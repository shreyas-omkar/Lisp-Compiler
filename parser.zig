const std = @import("std");
const ast = @import("ast.zig");
const ParserError = ast.ParserError;

pub fn parse(tokens: []const []const u8, allocator: std.mem.Allocator) ParserError!ast.Expr {
    var index: usize = 0;
    const expr = try parseExpr(tokens, &index, allocator);

    if (index != tokens.len) {
        return ParserError.ExtraTokensAfterExpression;
    }

    return expr;
}

fn parseExpr(tokens: []const []const u8, index: *usize, allocator: std.mem.Allocator) ParserError!ast.Expr {
    if (index.* >= tokens.len) {
        return ParserError.UnexpectedEndOfInput;
    }

    const token = tokens[index.*];
    index.* += 1;

    //Handling Let
    if (std.mem.eql(u8, token, "let")) {
        return parseLet(tokens, index, allocator);
    }

    if (std.mem.eql(u8, token, "(")) {
        var exprs = std.ArrayList(ast.Expr).init(allocator);

        while (index.* < tokens.len and !std.mem.eql(u8, tokens[index.*], ")")) {
            try exprs.append(try parseExpr(tokens, index, allocator));
        }

        if (index.* >= tokens.len) {
            return ParserError.MissingClosingParen;
        }

        index.* += 1; // skip closing ')'

        const list_expr_ptr = try allocator.create(ast.ListExpr);
        var expr_ptrs = try allocator.alloc(*ast.Expr, exprs.items.len);

        for (exprs.items, 0..) |e, i| {
            const ptr = try allocator.create(ast.Expr);
            ptr.* = e;
            expr_ptrs[i] = ptr;
        }

        list_expr_ptr.* = ast.ListExpr{
            .items = expr_ptrs,
        };

        return ast.Expr{ .List = list_expr_ptr };
    } else if (std.mem.eql(u8, token, ")")) {
        return ParserError.UnexpectedClosingParen;
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
        .Let => |let_ptr| {
            try writer.print("(let {s} ", .{let_ptr.name});
            try printExpr(let_ptr.expr.*, writer);
            try writer.print(")", .{});
        },
        .FuncDef => |func_ptr| {
            try writer.print("(func {s} (", .{func_ptr.name});
            for (func_ptr.params, 0..) |param, i| {
                try writer.print("{s}", .{param});
                if (i != func_ptr.params.len - 1)
                    try writer.print(" ", .{});
            }
            try writer.print(") ", .{});
            try printExpr(func_ptr.body.*, writer);
            try writer.print(")", .{});
        },
        .List => |li| {
            try writer.print("(", .{});
            for (li.items, 0..) |item, i| {
                try printExpr(item.*, writer);
                if (i != li.items.len - 1)
                    try writer.print(" ", .{});
            }
            try writer.print(")", .{});
        },
    }
}

fn parseLet(tokens: []const []const u8, index: *usize, allocator: std.mem.Allocator) ParserError!ast.Expr {
    if (index.* + 3 > tokens.len) return ParserError.InvalidLetSyntax;

    const type_sym = tokens[index.*];
    const name_sym = tokens[index.* + 1];

    var value_index: usize = index.* + 2;
    const value_expr = try parseExpr(tokens, &value_index, allocator);
    index.* = value_index;

    const type_tag = try parseTypeTag(type_sym);
    if (type_tag == ast.TypeTag.func) {
        // Create a copy of value_expr to pass to parseFunc
        const mutable_value_expr = try allocator.create(ast.Expr);
        mutable_value_expr.* = value_expr;
        const func_expr = try parseFunc(name_sym, mutable_value_expr, allocator);
        return func_expr.*;
    }

    const value_ptr = try allocator.create(ast.Expr);
    value_ptr.* = value_expr;

    const let_ptr = try allocator.create(ast.LetBinding);
    let_ptr.* = ast.LetBinding{
        .type_tag = type_tag,
        .name = name_sym,
        .expr = value_ptr,
    };

    return ast.Expr{ .Let = let_ptr };
}

fn parseFunc(name: []const u8, value_expr: *ast.Expr, allocator: std.mem.Allocator) ParserError!*ast.Expr {
    if (value_expr.* != .List) return ParserError.InvalidFunctionFormat;

    const fn_parts = value_expr.List.*;

    if (fn_parts.items.len < 2) return ParserError.InvalidFunctionFormat;

    const param_expr = fn_parts.items[0];
    if (param_expr.* != .List) return ParserError.InvalidFunctionParameters;

    var param_list = std.ArrayList([]const u8).init(allocator);
    for (param_expr.List.*.items) |param| {
        if (param.* != .Symbol) return ParserError.InvalidFunctionParameterName;
        try param_list.append(param.*.Symbol);
    }

    const body_exprs = fn_parts.items[1..];

    // Create a new ListExpr to own the body expressions
    const body_list_ptr = try allocator.create(ast.ListExpr);
    body_list_ptr.* = ast.ListExpr{
        .items = try allocator.dupe(*ast.Expr, body_exprs),
    };

    const body_expr = try allocator.create(ast.Expr);
    body_expr.* = ast.Expr{ .List = body_list_ptr };

    const func_def = try allocator.create(ast.FunctionDefinition);
    func_def.* = ast.FunctionDefinition{
        .name = name,
        .params = try param_list.toOwnedSlice(),
        .body = body_expr,
    };

    const result = try allocator.create(ast.Expr);
    result.* = ast.Expr{
        .FuncDef = func_def,
    };
    return result;
}

fn parseTypeTag(sym: []const u8) ParserError!ast.TypeTag {
    return std.meta.stringToEnum(ast.TypeTag, sym) orelse ParserError.UnknownTypeTag;
}

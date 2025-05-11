const std = @import("std");
const ast = @import("ast.zig");

pub fn eval(expr: ast.Expr, allocator: std.mem.Allocator) !ast.Expr {
    switch (expr) {
        .Number => return expr,
        .Symbol => return error.UnknownSymbol,
        .List => |list_ptr| {
            if (list_ptr.items.len == 0) return error.EmptyExpression;
            const head = list_ptr.items[0].*;
            if (head != .Symbol) return error.InvalidOperator;
            const op = head.Symbol;

            if (std.mem.eql(u8, op, "+")) {
                var sum: i64 = 0;
                for (list_ptr.items[1..]) |item| {
                    const value = try eval(item.*, allocator);
                    if (value != .Number) {
                        return error.ExpectedNumber;
                    }
                    sum += value.Number;
                }
                return ast.Expr{ .Number = sum };
            } else if (std.mem.eql(u8, op, "*")) {
                var product: i64 = 1;
                for (list_ptr.items[1..]) |item| {
                    const value = try eval(item.*, allocator);
                    if (value != .Number) return error.ExpectedNumber;
                    product *= value.Number;
                }
                return ast.Expr{ .Number = product };
            } else if (std.mem.eql(u8, op, "-")) {
                if (list_ptr.items.len < 2) return error.ExpectedNumber;
                const result_expr = try eval(list_ptr.items[1].*, allocator);
                if (result_expr != .Number) return error.ExpectedNumber;
                var result = result_expr.Number;
                for (list_ptr.items[2..]) |item| {
                    const val = try eval(item.*, allocator);
                    if (val != .Number) return error.ExpectedNumber;
                    result -= val.Number;
                }
                return ast.Expr{ .Number = result };
            } else if (std.mem.eql(u8, op, "/")) {
                if (list_ptr.items.len < 2) return error.ExpectedNumber;
                const result_expr = try eval(list_ptr.items[1].*, allocator);
                if (result_expr != .Number) return error.ExpectedNumber;
                var result = result_expr.Number;
                for (list_ptr.items[2..]) |item| {
                    const val = try eval(item.*, allocator);
                    if (val != .Number) return error.ExpectedNumber;
                    if (val.Number == 0) return error.DivideByZero;
                    result = @divTrunc(result, val.Number);
                }
                return ast.Expr{ .Number = result };
            } else if (std.mem.eql(u8, op, "%")) {
                if (list_ptr.items.len != 3) return error.InvalidArguments;

                const left_expr = try eval(list_ptr.items[1].*, allocator);
                const right_expr = try eval(list_ptr.items[2].*, allocator);

                if (left_expr != .Number or right_expr != .Number) return error.ExpectedNumber;
                if (right_expr.Number == 0) return error.DivideByZero;

                const result = @mod(left_expr.Number, right_expr.Number);
                return ast.Expr{ .Number = result };
            } else if (std.mem.eql(u8, op, "let")) {
                return error.InvalidOperator;
            } else if (std.mem.eql(u8, op, "func")) {
                return error.InvalidOperator;
            }
            return error.UnknownOperator;
        },
        .Let => |let_ptr| {
            return try eval(let_ptr.expr.*, allocator);
        },
        .FuncDef => {
            return expr;
        },
    }
}

const std = @import("std");
const ast = @import("ast.zig");

pub fn eval(expr: ast.Expr, allocator: std.mem.Allocator) !ast.Expr {
    switch (expr) {
        .Number => return expr,
        .Symbol => return error.UnknownSymbol,
        .List => |list| {
            if (list.len == 0) return error.EmptyExpression;
            const head = list[0];
            if (head != .Symbol) return error.InvalidOperator;
            const op = head.Symbol;

            if (std.mem.eql(u8, op, "+")) {
                var sum: i64 = 0;
                for (list[1..]) |i| {
                    const value = try eval(i, allocator);
                    if (value != .Number) {
                        return error.ExpectedNumber;
                    }
                    sum += value.Number;
                }
                return ast.Expr{ .Number = sum };
            } else if (std.mem.eql(u8, op, "*")) {
                var product: i64 = 1;
                for (list[1..]) |i| {
                    const value = try eval(i, allocator);
                    if (value != .Number) return error.ExpectedNumber;
                    product *= value.Number;
                }
                return ast.Expr{ .Number = product };
            } else if (std.mem.eql(u8, op, "-")) {
                if (list.len < 2) return error.ExpectedNumber;
                const result_expr = try eval(list[1], allocator);
                if (result_expr != .Number) return error.ExpectedNumber;
                var result = result_expr.Number;
                for (list[2..]) |i| {
                    const val = try eval(i, allocator);
                    if (val != .Number) return error.ExpectedNumber;
                    result -= val.Number;
                }
                return ast.Expr{ .Number = result };
            } else if (std.mem.eql(u8, op, "/")) {
                if (list.len < 2) return error.ExpectedNumber;
                const result_expr = try eval(list[1], allocator);
                if (result_expr != .Number) return error.ExpectedNumber;
                var result = result_expr.Number;
                for (list[2..]) |i| {
                    const val = try eval(i, allocator);
                    if (val != .Number) return error.ExpectedNumber;
                    if (val.Number == 0) return error.DivideByZero;
                    result = @divTrunc(result, val.Number);
                }
                return ast.Expr{ .Number = result };
            } else if (std.mem.eql(u8, op, "%")) {
                if (list.len != 3) return error.InvalidArguments;

                const left_expr = try eval(list[1], allocator);
                const right_expr = try eval(list[2], allocator);

                if (left_expr != .Number or right_expr != .Number) return error.ExpectedNumber;
                if (right_expr.Number == 0) return error.DivideByZero;

                const result = @mod(left_expr.Number, right_expr.Number);
                return ast.Expr{ .Number = result };
            }
            return error.UnknownOperator;
        },
    }
}

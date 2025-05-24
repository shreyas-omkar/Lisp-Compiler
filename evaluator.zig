const std = @import("std");
const ast = @import("ast.zig");
const parser = @import("parser.zig");
const Expr = ast.Expr;
const LambdaExpr = ast.Expr.LambdaExpr;
const DefineExpr = ast.Expr.DefineExpr;
const IfExpr = ast.Expr.IfExpr;

pub const EvalError = error{
    OutOfMemory,
    UnknownSymbol,
    InvalidApplication,
    ArityMismatch,
    TypeMismatch,
};

// Simple global environment for now
var global_env: std.HashMap([]const u8, Expr, std.hash_map.StringContext, std.hash_map.default_max_load_percentage) = undefined;
var env_initialized = false;

fn initEnv() void {
    if (!env_initialized) {
        global_env = std.HashMap([]const u8, Expr, std.hash_map.StringContext, std.hash_map.default_max_load_percentage).init(std.heap.page_allocator);
        env_initialized = true;
    }
}

pub fn eval(expr: Expr) EvalError!Expr {
    initEnv();
    return switch (expr) {
        .Number, .Bool => expr,
        .Symbol => lookupSymbol(expr.Symbol),
        .Define => try evalDefine(expr.Define),
        .If => try evalIf(expr.If),
        .Lambda => expr,
        .List => try evalApplication(expr.List),
        .Let => {
            std.debug.print("Warning: Let evaluation not yet implemented.\n", .{});
            return expr;
        },
        .FuncDef => {
            std.debug.print("Warning: FuncDef evaluation not yet implemented.\n", .{});
            return expr;
        },
    };
}

fn lookupSymbol(symbol: []const u8) EvalError!Expr {
    if (global_env.get(symbol)) |value| {
        return value;
    }

    // Handle built-in operators
    if (std.mem.eql(u8, symbol, "+") or
        std.mem.eql(u8, symbol, "-") or
        std.mem.eql(u8, symbol, "*") or
        std.mem.eql(u8, symbol, "/") or
        std.mem.eql(u8, symbol, "=") or
        std.mem.eql(u8, symbol, "<") or
        std.mem.eql(u8, symbol, ">"))
    {
        return Expr{ .Symbol = symbol };
    }

    std.debug.print("Error: Unknown symbol `{s}`\n", .{symbol});
    return EvalError.UnknownSymbol;
}

fn evalDefine(def: DefineExpr) EvalError!Expr {
    const value = try eval(def.value.*);
    global_env.put(def.name, value) catch return EvalError.OutOfMemory;
    std.debug.print("Define: {s} = ", .{def.name});
    printExpr(value);
    return value;
}

fn evalIf(if_expr: IfExpr) EvalError!Expr {
    const cond = try eval(if_expr.cond.*);
    if (isTruthy(cond)) {
        return try eval(if_expr.then_branch.*);
    } else {
        return try eval(if_expr.else_branch.*);
    }
}

fn evalApplication(list_expr: *ast.ListExpr) EvalError!Expr {
    if (list_expr.items.len == 0) return Expr{ .Symbol = "()" };

    const op = list_expr.items[0];
    const args = list_expr.items[1..];

    const func = try eval(op.*);
    const evaled_args = try evalAll(args);

    return try apply(func, evaled_args);
}

fn evalAll(args: []const *Expr) EvalError![]Expr {
    const allocator = std.heap.page_allocator;
    var result = allocator.alloc(Expr, args.len) catch return EvalError.OutOfMemory;

    for (args, 0..) |arg, i| {
        result[i] = try eval(arg.*);
    }

    return result;
}

fn apply(func: Expr, args: []Expr) EvalError!Expr {
    return switch (func) {
        .Symbol => |op| try applyBuiltin(op, args),
        .Lambda => {
            std.debug.print("Calling lambda (envs not supported yet)\n", .{});
            return try eval(func.Lambda.body.*);
        },
        else => {
            std.debug.print("Cannot apply non-function: ", .{});
            printExpr(func);
            return EvalError.InvalidApplication;
        },
    };
}

fn applyBuiltin(op: []const u8, args: []Expr) EvalError!Expr {
    if (std.mem.eql(u8, op, "+")) {
        return try applyArithmetic(op, args);
    } else if (std.mem.eql(u8, op, "-")) {
        return try applyArithmetic(op, args);
    } else if (std.mem.eql(u8, op, "*")) {
        return try applyArithmetic(op, args);
    } else if (std.mem.eql(u8, op, "/")) {
        return try applyArithmetic(op, args);
    } else if (std.mem.eql(u8, op, "=")) {
        return try applyComparison(op, args);
    } else if (std.mem.eql(u8, op, "<")) {
        return try applyComparison(op, args);
    } else if (std.mem.eql(u8, op, ">")) {
        return try applyComparison(op, args);
    }

    std.debug.print("Unknown builtin operator: {s}\n", .{op});
    return EvalError.InvalidApplication;
}

fn applyArithmetic(op: []const u8, args: []Expr) EvalError!Expr {
    if (args.len < 2) {
        std.debug.print("Arithmetic operator {s} requires at least 2 arguments, got {d}\n", .{ op, args.len });
        return EvalError.ArityMismatch;
    }

    for (args) |arg| {
        if (arg != .Number) {
            std.debug.print("Arithmetic operator {s} requires numeric arguments\n", .{op});
            return EvalError.TypeMismatch;
        }
    }

    var result = args[0].Number;

    if (std.mem.eql(u8, op, "+")) {
        for (args[1..]) |arg| {
            result += arg.Number;
        }
    } else if (std.mem.eql(u8, op, "-")) {
        for (args[1..]) |arg| {
            result -= arg.Number;
        }
    } else if (std.mem.eql(u8, op, "*")) {
        for (args[1..]) |arg| {
            result *= arg.Number;
        }
    } else if (std.mem.eql(u8, op, "/")) {
        for (args[1..]) |arg| {
            if (arg.Number == 0) {
                std.debug.print("Division by zero\n", .{});
                return EvalError.TypeMismatch;
            }
            result = @divTrunc(result, arg.Number);
        }
    }

    return Expr{ .Number = result };
}

fn applyComparison(op: []const u8, args: []Expr) EvalError!Expr {
    if (args.len != 2) {
        std.debug.print("Comparison operator {s} requires exactly 2 arguments, got {d}\n", .{ op, args.len });
        return EvalError.ArityMismatch;
    }

    if (args[0] != .Number or args[1] != .Number) {
        std.debug.print("Comparison operator {s} requires numeric arguments\n", .{op});
        return EvalError.TypeMismatch;
    }

    const left = args[0].Number;
    const right = args[1].Number;

    const result = if (std.mem.eql(u8, op, "="))
        left == right
    else if (std.mem.eql(u8, op, "<"))
        left < right
    else if (std.mem.eql(u8, op, ">"))
        left > right
    else
        false;

    return Expr{ .Bool = result };
}

fn isTruthy(expr: Expr) bool {
    return switch (expr) {
        .Bool => expr.Bool,
        else => true,
    };
}

pub fn printExpr(expr: Expr) void {
    switch (expr) {
        .Number => std.debug.print("Number({d})\n", .{expr.Number}),
        .Bool => std.debug.print("Bool({})\n", .{expr.Bool}),
        .Symbol => std.debug.print("Symbol({s})\n", .{expr.Symbol}),
        .List => |list_ptr| {
            std.debug.print("List(", .{});
            for (list_ptr.items) |e| {
                printExpr(e.*);
            }
            std.debug.print(")\n", .{});
        },
        .Define => |def| {
            std.debug.print("Define({s} = ", .{def.name});
            printExpr(def.value.*);
            std.debug.print(")\n", .{});
        },
        .Lambda => {
            std.debug.print("Lambda(...)\n", .{});
        },
        .If => |if_expr| {
            std.debug.print("If(cond: ", .{});
            printExpr(if_expr.cond.*);
            std.debug.print(", then: ", .{});
            printExpr(if_expr.then_branch.*);
            std.debug.print(", else: ", .{});
            printExpr(if_expr.else_branch.*);
            std.debug.print(")\n", .{});
        },
        .Let => {
            std.debug.print("Let(...)\n", .{});
        },
        .FuncDef => {
            std.debug.print("FuncDef(...)\n", .{});
        },
    }
}

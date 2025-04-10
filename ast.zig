const std = @import("std");

pub const Expr = union(enum) { Number: i64, Symbol: []const u8, List: []Expr };

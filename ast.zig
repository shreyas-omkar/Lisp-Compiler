const std = @import("std");

pub const Expr = union(enum) {
    Number: i64,
    Symbol: []const u8,
    Let: *LetBinding,
    FuncDef: *FunctionDefinition,
    List: *ListExpr,
};

pub const TypeTag = enum {
    ui,
    si,
    uf,
    sf,
    ul,
    sl,
    c,
    s,
    b,
    func,
};

pub const LetBinding = struct {
    type_tag: TypeTag,
    name: []const u8,
    expr: *Expr,
};

pub const FunctionDefinition = struct {
    name: []const u8,
    params: []const []const u8,
    body: *Expr,
};

pub const ListExpr = struct {
    items: []const *Expr,
};

pub const ParserError = error{
    UnexpectedEndOfInput,
    UnexpectedClosingParen,
    MissingClosingParen,
    ExtraTokensAfterExpression,
    InvalidLetSyntax,
    UnknownTypeTag,
    InvalidFunctionFormat,
    InvalidFunctionParameters,
    InvalidFunctionParameterName,
    OutOfMemory,
};

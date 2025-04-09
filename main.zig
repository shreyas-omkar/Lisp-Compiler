const std = @import("std");
const tokeniser = @import("tokeniser.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    const allocator = std.heap.page_allocator;
    var buf: [1024]u8 = undefined;

    try stdout.print("Lisp Compiler 0.0.1\n Type `exit` to quit.\n\n", .{});
    while (true) {
        try stdout.print("list> ", .{});
        const line = try stdin.readUntilDelimiterOrEof(&buf, '\n');
        if (line == null) {
            break;
        }
        const input = line.?;
        const trimmed = std.mem.trim(u8, input, " \t\r\n");
        if (std.mem.eql(u8, trimmed, "exit")) {
            try stdout.print("Goodbye", .{});
            break;
        }

        //Majority Logic Starts Here

        const tokens = try tokeniser.tokenise(trimmed, allocator);
        if (tokens.len == 0) {
            try stdout.print("No Tokens Present", .{});
            break;
        }
        try stdout.print("Tokens : \n", .{});
        for (tokens, 1..) |token, tokenNo| {
            try stdout.print("Token No. {d}: {s}\n", .{ tokenNo, token });
        }
    }
}

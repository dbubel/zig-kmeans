const std = @import("std");
const cmd = @import("src/cmd/kmeans.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var args = try std.process.ArgIterator.initWithAllocator(allocator);

    const stdout = std.io.getStdOut().writer();
    while (args.next()) |arg| {
        try stdout.print("{s}\n", .{arg});
    }
    _ = cmd.run();
}

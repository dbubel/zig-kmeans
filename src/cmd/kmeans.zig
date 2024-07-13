const std = @import("std");
const ls = @import("../lib/lc.zig");
const print = std.debug.print;

pub fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdin = std.io.getStdIn();
    const stdinReader = stdin.reader();

    var buf: [1024]u8 = undefined;
    var writer = std.io.fixedBufferStream(&buf);

    while (true) {
        defer writer.reset();
        stdinReader.streamUntilDelimiter(writer.writer(), '\n', null) catch |err| {
            switch (err) {
                error.EndOfStream => {
                    return;
                },
                else => {
                    print("err", .{});
                    return;
                },
            }
        };

        const arr = std.json.parseFromSlice([]f32, allocator, buf[0..writer.pos], .{}) catch |err| {
            switch (err) {
                error.UnexpectedEndOfInput => {
                    return;
                },
                else => {
                    return;
                },
            }
        };

        defer arr.deinit();
        std.debug.print("{any}\n", .{arr.value});
    }
}

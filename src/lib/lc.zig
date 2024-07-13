const std = @import("std");
fn lc(fp: []const u8) !usize {
    const file = try std.fs.cwd().openFile(fp, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    var line: [512]u8 = undefined;
    var writer = std.io.fixedBufferStream(&line);
    var count: usize = 0;

    while (true) {
        defer writer.reset();
        reader.streamUntilDelimiter(writer.writer(), '\n', 4096) catch |err| {
            switch (err) {
                error.EndOfStream => {
                    break;
                },
                else => {
                    std.debug.print("{any}", .{err});
                    break;
                },
            }
        };
        count = count + 1;
    }
    return count;
}

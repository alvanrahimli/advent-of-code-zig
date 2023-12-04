const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().openFile("inputs/d1.txt", .{});
    const fileReader = file.reader();
    defer file.close();

    var totalSum: i32 = 0;

    while (true) {
        var buff: [256]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buff);
        const allocator = fba.allocator();
        var lineArr = std.ArrayList(u8).init(allocator);
        defer lineArr.deinit();

        fileReader.streamUntilDelimiter(lineArr.writer(), '\n', null) catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };

        var firstDigit: u8 = undefined;
        var lastDigit: u8 = undefined;

        for (lineArr.items) |el| {
            if (el >= '0' and el <= '9') {
                firstDigit = el;
                break;
            }
        }

        var i: usize = lineArr.items.len - 1;
        while (i >= 0) : (i -= 1) {
            var el = lineArr.items[i];
            if (el >= '0' and el <= '9') {
                lastDigit = el;
                break;
            }
        }

        const numStr = [_]u8{ firstDigit, lastDigit };

        const num = try std.fmt.parseInt(i8, &numStr, 10);
        totalSum += num;
    }

    std.debug.print("TOTAL: {d}", .{totalSum});
}

const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().openFile("src/1-input.txt", .{});
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

const HumanizedParseError = error{Unrecognized};
pub fn parseHumanizedDigit(numberStr: []const u8) HumanizedParseError!i32 {
    if (std.mem.eql(u8, numberStr, "one")) {
        return 1;
    } else if (std.mem.eql(u8, numberStr, "two")) {
        return 2;
    } else if (std.mem.eql(u8, numberStr, "three")) {
        return 3;
    } else if (std.mem.eql(u8, numberStr, "four")) {
        return 4;
    } else if (std.mem.eql(u8, numberStr, "five")) {
        return 5;
    } else if (std.mem.eql(u8, numberStr, "six")) {
        return 6;
    } else if (std.mem.eql(u8, numberStr, "seven")) {
        return 7;
    } else if (std.mem.eql(u8, numberStr, "eight")) {
        return 8;
    } else if (std.mem.eql(u8, numberStr, "nine")) {
        return 9;
    } else {
        return HumanizedParseError.Unrecognized;
    }
}

test "Should Parse Humanized" {
    const x = try parseHumanizedDigit("two");
    try std.testing.expect(x == 2);
}

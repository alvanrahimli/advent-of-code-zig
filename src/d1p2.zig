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

        const alphabet = [_][]const u8{ "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
        const reverseAlphabet = [_][]const u8{ "orez", "eno", "owt", "eerht", "ruof", "evif", "xis", "neves", "thgie", "enin" };

        var firstDigit: u8 = findFirstDigit(lineArr.items, alphabet);
        std.mem.reverse(u8, lineArr.items);
        var lastDigit: u8 = findFirstDigit(lineArr.items, reverseAlphabet);

        totalSum += (firstDigit * 10 + lastDigit);
    }

    std.debug.print("{d}", .{totalSum});
}

pub fn findFirstDigit(str: []const u8, alphabet: [10][]const u8) u8 {
    var i: usize = 0;
    while (i < str.len) : (i += 1) {
        var digit = parseDigit(str[i..], alphabet) catch {
            continue;
        };
        return digit;
    }

    return 0;
}

const HumanizedParseError = error{Unrecognized};
pub fn parseDigit(numberStr: []const u8, alphabet: [10][]const u8) (std.fmt.ParseIntError || HumanizedParseError)!u8 {
    const x = numberStr[0];
    if (x >= '0' and numberStr[0] <= '9') {
        const num = try std.fmt.parseInt(u8, numberStr[0..1], 10);
        return num;
    }

    var i: u8 = 0;
    while (i < alphabet.len) : (i += 1) {
        if (startsWith(numberStr, alphabet[i])) {
            return i;
        }
    }

    return HumanizedParseError.Unrecognized;
}

pub fn startsWith(str: []const u8, prefix: []const u8) bool {
    if (str.len < prefix.len)
        return false;

    return std.mem.eql(u8, str[0..prefix.len], prefix);
}

test "Should Parse Humanized" {
    const x = try parseDigit("two");
    try std.testing.expect(x == 2);
}

test "Can we find the first digit" {
    try std.testing.expect(findFirstDigit("rtkrbtthree8sixfoureight6") == 3);
}

const std = @import("std");

pub fn main() !void {
    // TODO
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

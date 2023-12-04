const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().openFile("inputs/d2.txt", .{});
    const fileReader = file.reader();
    defer file.close();

    var powerSum: u32 = 0;

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

        const line = lineArr.items[5..];
        var iColon = std.mem.indexOf(u8, line, ":") orelse 0;
        if (iColon == 0) {
            continue;
        }

        const delimitedRounds = line[iColon + 1 ..];

        var necessaryRed: u32 = 0;
        var necessaryGreen: u32 = 0;
        var necessaryBlue: u32 = 0;

        var roundStart: usize = 0;
        while (roundStart < delimitedRounds.len) {
            const roundLength = std.mem.indexOf(u8, delimitedRounds[roundStart..], ";") orelse delimitedRounds.len - roundStart;
            const roundStats = try parseGame(delimitedRounds[roundStart..(roundStart + roundLength)]);

            if (necessaryRed < roundStats.r) {
                necessaryRed = roundStats.r;
            }
            if (necessaryGreen < roundStats.g) {
                necessaryGreen = roundStats.g;
            }
            if (necessaryBlue < roundStats.b) {
                necessaryBlue = roundStats.b;
            }

            roundStart += roundLength + 1; // +1 to skip semicolon
        }

        powerSum += necessaryRed * necessaryGreen * necessaryBlue;
    }

    std.debug.print("{d}", .{powerSum});
}

pub fn parseGame(str: []const u8) !RoundResult {
    var i: usize = 0;

    var red: u8 = 0;
    var green: u8 = 0;
    var blue: u8 = 0;

    var currentNum: u8 = 0;
    while (i < str.len) {
        switch (str[i]) {
            '0'...'9' => {
                const numLength = std.mem.indexOf(u8, str[i..], " ") orelse 0;
                currentNum = try std.fmt.parseInt(u8, str[i..(i + numLength)], 10);
                i += numLength;
            },
            ' ', ',' => {
                i += 1;
            },
            'r', 'g', 'b' => {
                const colorLength = std.mem.indexOf(u8, str[i..], ",") orelse str.len - i;
                const colorStr = str[i..(i + colorLength)];
                if (std.mem.eql(u8, colorStr, "red")) {
                    red += currentNum;
                } else if (std.mem.eql(u8, colorStr, "green")) {
                    green += currentNum;
                } else if (std.mem.eql(u8, colorStr, "blue")) {
                    blue += currentNum;
                }

                i += colorLength;
            },
            else => {
                i += 1;
            },
        }
    }

    return RoundResult{ .r = red, .g = green, .b = blue };
}

const RoundResult = struct { r: u8, g: u8, b: u8 };

test "Should parse round correctly" {
    const roundStats = try parseGame(" 4 green");
    try std.testing.expect(roundStats.r == 0 and roundStats.g == 4 and roundStats.b == 0);
}

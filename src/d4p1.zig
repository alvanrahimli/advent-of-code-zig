const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("inputs/d4.txt", .{});
    const fileReader = file.reader();
    defer file.close();

    var totalSum: i32 = 0;

    while (true) {
        var newLine = try nextLine(allocator, fileReader);
        defer newLine.deinit();

        if (newLine.items.len == 0) {
            break;
        }

        const colonI = std.mem.indexOf(u8, newLine.items, ":");
        const separatorI = std.mem.indexOf(u8, newLine.items, "|");
        const winningSection = newLine.items[(colonI.?)..(separatorI.?)];
        const ourNumbersSection = newLine.items[(separatorI.?)..];

        const cardNum = try parseNextInt(allocator, newLine.items[5..]);

        var winningNumbers = std.ArrayList(i32).init(allocator);

        // Parse winning numbers
        var i: usize = 0;
        while (i < winningSection.len) {
            if (isDigit(winningSection[i])) {
                const parseResult = try parseNextInt(allocator, winningSection[i..]);
                try winningNumbers.append(parseResult.number);
                i += parseResult.length;
            } else {
                i += 1;
            }
        }

        var cardPoints: i32 = 0;
        i = 0;
        while (i < ourNumbersSection.len) {
            if (isDigit(ourNumbersSection[i])) {
                const parseResult = try parseNextInt(allocator, ourNumbersSection[i..]);
                if (existsInList(winningNumbers.items, parseResult.number)) {
                    cardPoints = if (cardPoints == 0) 1 else cardPoints * 2;
                }
                i += parseResult.length;
            } else {
                i += 1;
            }
        }

        std.debug.print("Winning numbers: {d}: {any}; sum: {d}\n", .{ cardNum.number, winningNumbers.items, cardPoints });
        totalSum += cardPoints;
    }

    std.debug.print("TOTAL: {d}", .{totalSum});
}

const ParsedNumber = struct { number: i32, length: usize };
pub fn parseNextInt(allocator: std.mem.Allocator, str: []const u8) !ParsedNumber {
    var intStr = std.ArrayList(u8).init(allocator);
    defer intStr.deinit();
    var len: usize = 0;
    var readInt = false;
    for (str) |v| {
        if (isDigit(v)) {
            try intStr.append(v);
            len += 1;
            readInt = true;
            continue;
        }

        if (!isDigit(v) and readInt) {
            break;
        } else if (!isDigit(v)) {
            len += 1;
            continue;
        }
    }

    const num = try std.fmt.parseInt(i32, intStr.items, 10);
    return ParsedNumber{
        .number = num,
        .length = len,
    };
}

pub fn existsInList(haysack: []const i32, item: i32) bool {
    for (haysack) |v| {
        if (v == item) {
            return true;
        }
    }

    return false;
}

/// Returns next line, but doesn't handle error.EndOfStream
pub fn nextLine(allocator: std.mem.Allocator, reader: std.fs.File.Reader) !std.ArrayList(u8) {
    var line = std.ArrayList(u8).init(allocator);
    reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    };
    return line;
}

pub inline fn isSymbol(char: u8) bool {
    return !isDigit(char) and char != '.';
}
pub inline fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

test "Should parse next int 2 times" {
    const input = "  12#56";
    const res1 = try parseNextInt(std.testing.allocator, input);
    std.debug.print("1: {any}\n", .{res1});

    const res2 = try parseNextInt(std.testing.allocator, input[res1.length..]);
    std.debug.print("2: {any}\n", .{res2});
}

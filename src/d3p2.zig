const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("inputs/d3.txt", .{});
    const fileReader = file.reader();
    defer file.close();

    var totalSum: i32 = 0;

    var firstLine = try nextLine(allocator, fileReader);

    var lines = try LineStack.init(allocator);
    defer lines.deinit();

    try lines.push(allocator, firstLine.items);
    firstLine.deinit();

    var lineN: i32 = 1;
    var firstEOFHappened = false;
    while (true) : (lineN += 1) {
        var newLine = try nextLine(allocator, fileReader);
        defer newLine.deinit();

        if (newLine.items.len == 0) {
            if (firstEOFHappened) {
                break;
            } else {
                firstEOFHappened = true;
            }
        }

        try lines.push(allocator, newLine.items);

        totalSum += lines.calculateRatioSum();
    }

    std.debug.print("TOTAL: {d}", .{totalSum});
}

const TokenType = enum { Symbol, Number };
const Token = struct {
    tokenType: TokenType,
    startPos: usize,
    endPos: usize,
    data: std.ArrayList(u8),

    pub fn getValueInt(self: *const Token) std.fmt.ParseIntError!i32 {
        return std.fmt.parseInt(i32, self.data.items, 10);
    }

    pub fn touchesIndex(self: *const Token, i: usize) bool {
        return i >= (if (self.startPos > 1) self.startPos - 1 else 0) and i <= self.endPos;
    }

    pub fn deinit(self: *const Token) void {
        self.data.deinit();
    }
};

const SurroundingNumberSearchError = error{InsufficientNumberOfSurrounding};
const LineStack = struct {
    topLine: std.ArrayList(Token),
    currentLine: std.ArrayList(Token),
    bottomLine: std.ArrayList(Token),

    pub fn init(allocator: std.mem.Allocator) !LineStack {
        return .{
            .topLine = std.ArrayList(Token).init(allocator),
            .currentLine = std.ArrayList(Token).init(allocator),
            .bottomLine = std.ArrayList(Token).init(allocator),
        };
    }

    pub fn push(self: *LineStack, allocator: std.mem.Allocator, line: []const u8) !void {
        for (self.topLine.items) |t| {
            t.deinit();
        }
        self.topLine.deinit();
        self.topLine = self.currentLine;
        self.currentLine = self.bottomLine;
        self.bottomLine = try parseLine(allocator, line);
    }

    pub fn calculateRatioSum(self: *const LineStack) i32 {
        var totalSum: i32 = 0;
        if (self.currentLine.items.len == 0) {
            return 0;
        }

        for (self.currentLine.items, 0..) |token, i| {
            if (token.tokenType != TokenType.Symbol) {
                continue;
            }

            if (token.data.items[0] != '*') {
                continue;
            }

            var sum = self.getGearRatio(i) catch {
                continue;
            };

            totalSum += sum;
        }

        return totalSum;
    }

    pub fn getGearRatio(self: *const LineStack, i: usize) SurroundingNumberSearchError!i32 {
        var v = self.currentLine.items[i];
        var mult: i32 = 1;
        var surroundingCount: i32 = 0;

        // Top
        if (self.topLine.items.len > 0) {
            for (self.topLine.items) |t| {
                if (t.tokenType == TokenType.Number and t.touchesIndex(v.startPos) and surroundingCount < 2) {
                    surroundingCount += 1;
                    const x = t.getValueInt() catch {
                        continue;
                    };
                    mult *= x;
                }
            }
        }

        // Bottom
        if (self.bottomLine.items.len > 0 and surroundingCount < 2) {
            for (self.bottomLine.items) |t| {
                if (t.tokenType == TokenType.Number and t.touchesIndex(v.startPos) and surroundingCount < 2) {
                    surroundingCount += 1;
                    const x = t.getValueInt() catch {
                        continue;
                    };
                    mult *= x;
                }
            }
        }

        // Current
        if (self.currentLine.items.len > 0 and surroundingCount < 2) {
            for (self.currentLine.items, 0..) |t, iCurr| {
                if (iCurr == i) {
                    continue;
                }

                if (t.tokenType == TokenType.Number and t.touchesIndex(v.startPos) and surroundingCount < 2) {
                    surroundingCount += 1;
                    const x = t.getValueInt() catch {
                        continue;
                    };
                    mult *= x;
                }
            }
        }

        if (surroundingCount == 2) {
            return mult;
        }

        return SurroundingNumberSearchError.InsufficientNumberOfSurrounding;
    }

    pub fn dump(lines: *const LineStack) void {
        std.debug.print("\nTOP: Tokens:\n", .{});
        for (lines.topLine.items, 0..) |el, i| {
            std.debug.print("{d}: {any}\n", .{ i, el });
        }
        std.debug.print("\nCURR: Tokens:\n", .{});
        for (lines.currentLine.items, 0..) |el, i| {
            std.debug.print("{d}: {any}\n", .{ i, el });
        }
        std.debug.print("\nBOTTOM: Tokens:\n", .{});
        for (lines.bottomLine.items, 0..) |el, i| {
            std.debug.print("{d}: {any}\n", .{ i, el });
        }
    }

    pub fn deinit(self: *LineStack) void {
        for (self.topLine.items) |v| {
            v.deinit();
        }
        self.topLine.deinit();

        for (self.currentLine.items) |v| {
            v.deinit();
        }
        self.currentLine.deinit();

        for (self.bottomLine.items) |v| {
            v.deinit();
        }
        self.bottomLine.deinit();
    }
};

pub fn parseLine(allocator: std.mem.Allocator, line: []const u8) !std.ArrayList(Token) {
    var tokenList = std.ArrayList(Token).init(allocator);

    var i: usize = 0;
    while (i < line.len) : (i += 1) {
        if (line[i] == '.') {
            continue;
        }

        if (isDigit(line[i])) {
            var start = i;
            while (i < line.len) {
                if (!isDigit(line[i])) {
                    break;
                }

                i += 1;
            }

            var t = Token{
                .startPos = start,
                .endPos = i,
                .tokenType = TokenType.Number,
                .data = std.ArrayList(u8).init(allocator),
            };
            try t.data.appendSlice(line[start..i]);
            try tokenList.append(t);
        }

        if (isSymbol(line[i])) {
            var t = Token{
                .startPos = i,
                .endPos = i + 1,
                .tokenType = TokenType.Symbol,
                .data = std.ArrayList(u8).init(allocator),
            };
            try t.data.appendSlice(line[i..(i + 1)]);
            try tokenList.append(t);
        }
    }

    return tokenList;
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

test "Should parse line correctly" {
    const allocator = std.testing.allocator;
    var tokenList = try parseLine(allocator, "...123..*.23#");

    try std.testing.expect(try tokenList.items[0].getValueInt() == 123);
    try std.testing.expect(std.mem.eql(u8, tokenList.items[1].data.items, "*"));
    try std.testing.expect(try tokenList.items[2].getValueInt() == 23);
    try std.testing.expect(std.mem.eql(u8, tokenList.items[3].data.items, "#"));

    for (tokenList.items) |t| {
        t.deinit();
    }
    tokenList.deinit();
}

test "Should calculate gear mult correctly" {
    const allocator = std.testing.allocator;
    var lines = try LineStack.init(allocator);
    defer lines.deinit();

    try lines.push(allocator, "467..114..");
    try lines.push(allocator, "...*......");
    try lines.push(allocator, "..35..633.");
    try std.testing.expect(lines.calculateRatioSum() == 16345);

    try lines.push(allocator, "......#...");
    try lines.push(allocator, "617*......");
    try lines.push(allocator, ".....+.58.");
    try lines.push(allocator, "..592.....");
    try lines.push(allocator, "......755.");
    try lines.push(allocator, "...$.*....");
    try lines.push(allocator, ".664.598..");

    try std.testing.expect(try lines.getGearRatio(1) == 451490);
}

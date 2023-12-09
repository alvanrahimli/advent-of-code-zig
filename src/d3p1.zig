const std = @import("std");
const pa = std.heap.page_allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("inputs/d3.txt", .{});
    const fileReader = file.reader();
    defer file.close();

    var totalSum: i32 = 0;

    var firstLine = try nextLine(allocator, fileReader);

    var lines = try LineStack.init(allocator, firstLine.items.len);
    defer lines.deinit();

    try lines.push(firstLine);
    firstLine.deinit();

    var firstEOFHappened = false;
    while (true) {
        var newLine = try nextLine(allocator, fileReader);
        defer newLine.deinit();

        if (newLine.items.len == 0 and firstEOFHappened) {
            break;
        } else if (newLine.items.len == 0) {
            firstEOFHappened = true;
        }

        try lines.push(newLine);

        var i: usize = 0;
        while (i < lines.currentLine.items.len) {
            if (!isDigit(lines.currentLine.items[i])) {
                i += 1;
                continue;
            }

            var numStr = std.ArrayList(u8).init(allocator);
            defer numStr.deinit();

            var isEngineNumber = false;
            while (i < lines.currentLine.items.len and isDigit(lines.currentLine.items[i])) {
                try numStr.append(lines.currentLine.items[i]);

                if (lines.touchesASymbol(i)) {
                    isEngineNumber = true;
                }
                i += 1;
            }

            if (isEngineNumber) {
                const number = try std.fmt.parseInt(i32, numStr.items, 10);
                totalSum += number;
            }
        }
    }

    std.debug.print("TOTAL: {d}", .{totalSum});
}

pub inline fn isSymbol(char: u8) bool {
    return !isDigit(char) and char != '.';
}
pub inline fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

const LineStack = struct {
    topLine: std.ArrayList(u8),
    currentLine: std.ArrayList(u8),
    bottomLine: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator, len: usize) !LineStack {
        return .{
            .topLine = try std.ArrayList(u8).initCapacity(allocator, len),
            .currentLine = try std.ArrayList(u8).initCapacity(allocator, len),
            .bottomLine = try std.ArrayList(u8).initCapacity(allocator, len),
        };
    }

    pub fn push(self: *LineStack, line: std.ArrayList(u8)) !void {
        self.topLine.deinit();
        self.topLine = self.currentLine;
        self.currentLine = self.bottomLine;
        self.bottomLine = try line.clone();
    }

    pub fn touchesASymbol(self: *LineStack, i: usize) bool {
        // Left
        if (i > 1) {
            if (self.topLine.items.len > 0 and isSymbol(self.topLine.items[i - 1])) {
                return true;
            }
            if (self.currentLine.items.len > 0 and isSymbol(self.currentLine.items[i - 1])) {
                return true;
            }
            if (self.bottomLine.items.len > 0 and isSymbol(self.bottomLine.items[i - 1])) {
                return true;
            }
        }

        // Right
        if ((i + 1) < self.topLine.items.len and isSymbol(self.topLine.items[i + 1])) {
            return true;
        }
        if ((i + 1) < self.currentLine.items.len and isSymbol(self.currentLine.items[i + 1])) {
            return true;
        }
        if ((i + 1) < self.bottomLine.items.len and isSymbol(self.bottomLine.items[i + 1])) {
            return true;
        }

        // Top
        if (self.topLine.items.len > 0 and isSymbol(self.topLine.items[i])) {
            return true;
        }

        // Bottom
        if (self.bottomLine.items.len > 0 and isSymbol(self.bottomLine.items[i])) {
            return true;
        }

        return false;
    }

    pub fn dump(lines: LineStack) void {
        std.debug.print("TOP > {s}\n", .{lines.topLine.items});
        std.debug.print("CRR > {s}\n", .{lines.currentLine.items});
        std.debug.print("BOT > {s}\n", .{lines.bottomLine.items});
    }

    pub fn deinit(self: *LineStack) void {
        self.topLine.deinit();
        self.currentLine.deinit();
        self.bottomLine.deinit();
    }
};

/// Returns next line, but doesn't handle error.EndOfStream
pub fn nextLine(allocator: std.mem.Allocator, reader: std.fs.File.Reader) !std.ArrayList(u8) {
    var line = std.ArrayList(u8).init(allocator);
    reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    };
    return line;
}

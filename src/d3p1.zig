const std = @import("std");
const pa = std.heap.page_allocator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("inputs/d3.txt", .{});
    const fileReader = file.reader();
    defer file.close();

    var totalSum: i32 = 0;

    var line = std.ArrayList(u8).init(allocator);
    try fileReader.streamUntilDelimiter(line.writer(), '\n', null);
    defer line.deinit();

    var lines = try LineStack.init(allocator, line.items.len);
    try lines.push(line);

    while (true) {
        var newLine = nextLine(allocator, fileReader) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        defer newLine.deinit();
        try lines.push(newLine);

        lines.dump();

        var currentNumber = std.ArrayList(u8).init(allocator);
        defer currentNumber.deinit();
        var isEngineNumber = false;
        _ = isEngineNumber;
    }

    std.debug.print("TOTAL: {d}", .{totalSum});
}

pub fn checkSurroundings(i: usize, lines: *const LineStack) bool {
    if (lines.currentLine != null and (lines.currentLine.?[i] < '0' or lines.currentLine.?[i] > '9'))
        return false;

    // Left
    if (i > 1) {
        if (lines.currentLine != null and isSymbol(lines.currentLine.?[i - 1])) {
            return true;
        }
        if (lines.topLine != null and isSymbol(lines.topLine.?[i - 1])) {
            return true;
        }
        if (lines.bottomLine != null and isSymbol(lines.bottomLine.?[i - 1])) {
            return true;
        }
    }

    // Right
    if (lines.currentLine != null and (i + 1) < lines.currentLine.?.len) {
        if (isSymbol(lines.currentLine.?[i + 1])) {
            return true;
        }
        if (lines.topLine != null and isSymbol(lines.topLine.?[i + 1])) {
            return true;
        }
        if (lines.bottomLine != null and isSymbol(lines.bottomLine.?[i + 1])) {
            return true;
        }
    }

    // Top
    if (lines.topLine != null and isSymbol(lines.topLine.?[i])) {
        return true;
    }

    // Bottom
    if (lines.bottomLine != null and isSymbol(lines.bottomLine.?[i])) {
        return true;
    }

    return false;
}

pub inline fn isSymbol(char: u8) bool {
    return !((char > '0' and char < '9') or char == '.');
}

const LineStack = struct {
    topLine: std.ArrayList(u8),
    currentLine: std.ArrayList(u8),
    bottomLine: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator, len: usize) !LineStack {
        var topLine = try std.ArrayList(u8).initCapacity(allocator, len);
        var currentLine = try std.ArrayList(u8).initCapacity(allocator, len);
        var bottomLine = try std.ArrayList(u8).initCapacity(allocator, len);
        return .{
            .topLine = topLine,
            .currentLine = currentLine,
            .bottomLine = bottomLine,
        };
    }

    pub fn push(self: *LineStack, line: std.ArrayList(u8)) !void {
        self.topLine = try self.currentLine.clone();
        self.currentLine = try self.bottomLine.clone();
        self.bottomLine = try line.clone();
    }

    pub fn dump(lines: LineStack) void {
        std.debug.print("TOP > {s}\n", .{lines.topLine.items});
        std.debug.print("CRR > {s}\n", .{lines.currentLine.items});
        std.debug.print("BOT > {s}\n", .{lines.bottomLine.items});
        std.debug.print("----------------------\n", .{});
    }
};

pub fn nextLine(allocator: std.mem.Allocator, reader: std.fs.File.Reader) !std.ArrayList(u8) {
    var line = std.ArrayList(u8).init(allocator);
    try reader.streamUntilDelimiter(line.writer(), '\n', null);
    return line;
}

test "Should check surroundings correctly" {
    const top = [_]u8{ '.', '.', '#', '.', '4' };
    const crr = [_]u8{ '.', '2', '2', '.', '4' };
    const bot = [_]u8{ '.', '.', '#', '.', '4' };

    const lines = LineStack{
        .topLine = top[0..],
        .currentLine = crr[0..],
        .bottomLine = bot[0..],
    };

    try std.testing.expect(checkSurroundings(1, &lines));
}

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
            // var el = lines.currentLine.items[i];
            if (lines.currentLine.items[i] < '0' or lines.currentLine.items[i] > '9') {
                i += 1;
                continue;
            }

            var numStr = std.ArrayList(u8).init(allocator);
            defer numStr.deinit();

            var isEngineNumber = false;
            while (i < lines.currentLine.items.len and (lines.currentLine.items[i] >= '0' and lines.currentLine.items[i] <= '9')) {
                try numStr.append(lines.currentLine.items[i]);

                const touchesSymbol = checkSurroundings(i, &lines);
                if (touchesSymbol) {
                    isEngineNumber = true;
                }
                i += 1;
            }

            if (isEngineNumber) {
                const number = try std.fmt.parseInt(i32, numStr.items, 10);
                // if (number == 150) {
                //     std.debug.print("{d}, ", .{number});
                // }
                std.debug.print("[{d}] {d}, ", .{ i, number });
                totalSum += number;
            }
        }
        std.debug.print("\n", .{});
        lines.dump();
        std.debug.print("\n---------\n", .{});
    }

    std.debug.print("TOTAL: {d}, push: {d}", .{ totalSum, lines.pushCount });
}

pub fn checkSurroundings(i: usize, lines: *const LineStack) bool {
    if (lines.currentLine.items[i] < '0' or lines.currentLine.items[i] > '9')
        return false;

    // Left
    if (i > 1) {
        if (lines.topLine.items.len > 0 and isSymbol(lines.topLine.items[i - 1])) {
            return true;
        }
        if (lines.currentLine.items.len > 0 and isSymbol(lines.currentLine.items[i - 1])) {
            return true;
        }
        if (lines.bottomLine.items.len > 0 and isSymbol(lines.bottomLine.items[i - 1])) {
            return true;
        }
    }

    // Right
    if ((i + 1) < lines.topLine.items.len) {
        if (isSymbol(lines.topLine.items[i + 1])) {
            return true;
        }
    }
    if ((i + 1) < lines.currentLine.items.len) {
        if (isSymbol(lines.currentLine.items[i + 1])) {
            return true;
        }
    }
    if ((i + 1) < lines.bottomLine.items.len) {
        if (isSymbol(lines.bottomLine.items[i + 1])) {
            return true;
        }
    }

    // Top
    if (lines.topLine.items.len > 0 and isSymbol(lines.topLine.items[i])) {
        return true;
    }

    // Bottom
    if (lines.bottomLine.items.len > 0 and isSymbol(lines.bottomLine.items[i])) {
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
    pushCount: i32,

    pub fn init(allocator: std.mem.Allocator, len: usize) !LineStack {
        var topLine = try std.ArrayList(u8).initCapacity(allocator, len);
        var currentLine = try std.ArrayList(u8).initCapacity(allocator, len);
        var bottomLine = try std.ArrayList(u8).initCapacity(allocator, len);
        return .{
            .topLine = topLine,
            .currentLine = currentLine,
            .bottomLine = bottomLine,
            .pushCount = 0,
        };
    }

    pub fn push(self: *LineStack, line: std.ArrayList(u8)) !void {
        self.topLine = try self.currentLine.clone();
        self.currentLine = try self.bottomLine.clone();
        self.bottomLine = try line.clone();
        self.pushCount += 1;
        std.debug.print("pushed ({d}) {s}\n", .{ self.pushCount, line.items });
    }

    pub fn dump(lines: LineStack) void {
        std.debug.print("TOP > {s}\n", .{lines.topLine.items});
        std.debug.print("CRR > {s}\n", .{lines.currentLine.items});
        std.debug.print("BOT > {s}\n", .{lines.bottomLine.items});
    }
};

pub fn nextLine(allocator: std.mem.Allocator, reader: std.fs.File.Reader) !std.ArrayList(u8) {
    var line = std.ArrayList(u8).init(allocator);
    reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    };
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

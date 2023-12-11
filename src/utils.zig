const std = @import("std");

/// Returns next line, but doesn't handle error.EndOfStream
pub fn nextLineOrEmpty(allocator: std.mem.Allocator, reader: std.fs.File.Reader) !std.ArrayList(u8) {
    var line = std.ArrayList(u8).init(allocator);
    reader.streamUntilDelimiter(line.writer(), '\n', null) catch |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    };
    return line;
}

/// Returns next line, but doesn't handle error.EndOfStream
pub fn nextLine(allocator: std.mem.Allocator, reader: std.fs.File.Reader) !std.ArrayList(u8) {
    var line = std.ArrayList(u8).init(allocator);
    try reader.streamUntilDelimiter(line.writer(), '\n', null);
    return line;
}

pub fn ParsedType(comptime T: type) type {
    return struct {
        number: T,
        length: usize,
    };
}
pub fn parseFirstInt(comptime T: type, allocator: std.mem.Allocator, str: []const u8) !ParsedType(T) {
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

    const num = try std.fmt.parseInt(T, intStr.items, 10);
    return ParsedType(T){
        .number = num,
        .length = len,
    };
}

pub inline fn isSymbol(char: u8) bool {
    return !isDigit(char) and char != '.';
}
pub inline fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

pub fn existsInList(comptime T: type, haysack: []const T, item: T) bool {
    for (haysack) |v| {
        if (v == item) {
            return true;
        }
    }

    return false;
}

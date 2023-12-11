const std = @import("std");
const utils = @import("utils.zig");
const expect = std.testing.expect;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("inputs/d5.txt", .{});
    const fileReader = file.reader();
    defer file.close();

    var challenge = try Challenge.init(allocator, fileReader);
    defer challenge.deinit();

    try challenge.solve();
}

const Challenge = struct {
    allocator: std.mem.Allocator,
    input: std.fs.File.Reader,

    pub fn init(allocator: std.mem.Allocator, input: std.fs.File.Reader) !Challenge {
        return .{
            .allocator = allocator,
            .input = input,
        };
    }

    pub fn solve(self: *Challenge) !void {
        var mappings = std.ArrayList(Mapping).init(self.allocator);
        defer mappings.deinit();

        var seeds = std.ArrayList(i64).init(self.allocator);
        defer seeds.deinit();

        // Parse first line for seeds
        var firstLine = try utils.nextLineOrEmpty(self.allocator, self.input);
        if (firstLine.items.len == 0) {
            return;
        }

        if (std.mem.indexOf(u8, firstLine.items, "seeds:") != null) {
            var i: usize = 0;
            while (i < firstLine.items.len) {
                const seed = try utils.parseFirstInt(i64, self.allocator, firstLine.items[i..]);
                try seeds.append(seed.number);
                i += seed.length;
            }
        }
        firstLine.deinit();

        var currentSrcCategory: ?Category = null;
        var currentDstCategory: ?Category = null;

        while (true) {
            var newLine = utils.nextLine(self.allocator, self.input) catch |err| switch (err) {
                error.EndOfStream => break,
                else => return err,
            };
            defer newLine.deinit();

            if (newLine.items.len == 0) {
                continue;
            }

            if (std.mem.indexOf(u8, newLine.items, "seed-to-soil") != null) {
                currentSrcCategory = Category.Seed;
                currentDstCategory = Category.Soil;
                continue;
            } else if (std.mem.indexOf(u8, newLine.items, "soil-to-fertilizer") != null) {
                currentSrcCategory = Category.Soil;
                currentDstCategory = Category.Fertilizer;
                continue;
            } else if (std.mem.indexOf(u8, newLine.items, "fertilizer-to-water") != null) {
                currentSrcCategory = Category.Fertilizer;
                currentDstCategory = Category.Water;
                continue;
            } else if (std.mem.indexOf(u8, newLine.items, "water-to-light") != null) {
                currentSrcCategory = Category.Water;
                currentDstCategory = Category.Light;
                continue;
            } else if (std.mem.indexOf(u8, newLine.items, "light-to-temperature") != null) {
                currentSrcCategory = Category.Light;
                currentDstCategory = Category.Temperature;
                continue;
            } else if (std.mem.indexOf(u8, newLine.items, "temperature-to-humidity") != null) {
                currentSrcCategory = Category.Temperature;
                currentDstCategory = Category.Humidity;
                continue;
            } else if (std.mem.indexOf(u8, newLine.items, "humidity-to-location") != null) {
                currentSrcCategory = Category.Humidity;
                currentDstCategory = Category.Location;
                continue;
            }

            const dstStart = try utils.parseFirstInt(i64, self.allocator, newLine.items);
            const srcStart = try utils.parseFirstInt(i64, self.allocator, newLine.items[dstStart.length..]);
            const rangeLen = try utils.parseFirstInt(i64, self.allocator, newLine.items[(dstStart.length + srcStart.length)..]);
            try mappings.append(Mapping{
                .sourceCategory = currentSrcCategory.?,
                .destinationCategory = currentDstCategory.?,
                .destinationStart = dstStart.number,
                .sourceStart = srcStart.number,
                .rangeLength = rangeLen.number,
            });
        }

        for (mappings.items) |m| {
            std.debug.print("{any}\n", .{m});
        }

        var locations = std.ArrayList(i64).init(self.allocator);
        defer locations.deinit();

        for (seeds.items) |seed| {
            const soil = try findMapping(mappings.items, seed, Category.Seed);
            const fertilizer = try findMapping(mappings.items, soil, Category.Soil);
            const water = try findMapping(mappings.items, fertilizer, Category.Fertilizer);
            const light = try findMapping(mappings.items, water, Category.Water);
            const temperature = try findMapping(mappings.items, light, Category.Light);
            const humidity = try findMapping(mappings.items, temperature, Category.Temperature);
            const location = try findMapping(mappings.items, humidity, Category.Humidity);
            try locations.append(location);
        }

        std.debug.print("MINIMUM: {d}\n", .{std.mem.min(i64, locations.items)});
    }

    pub fn deinit(self: *Challenge) void {
        _ = self;
    }
};

pub fn findMapping(mappings: []const Mapping, id: i64, srcCategory: Category) !i64 {
    std.debug.print("searching: src: {any} of {d}\n", .{ srcCategory, id });
    for (mappings) |m| {
        if (id >= m.sourceStart and id <= m.sourceEnd() and m.sourceCategory == srcCategory) {
            return m.destinationStart + id - m.sourceStart;
        }
    } else {
        return id;
    }
}

const Category = enum { Seed, Soil, Fertilizer, Water, Light, Temperature, Humidity, Location };
const Mapping = struct {
    sourceCategory: Category,
    destinationCategory: Category,
    sourceStart: i64,
    destinationStart: i64,
    rangeLength: i64,

    pub fn sourceEnd(self: *const Mapping) i64 {
        return self.sourceStart + self.rangeLength;
    }
    pub fn destinationEnd(self: *const Mapping) i64 {
        return self.destinationStart + self.rangeLength;
    }
};

test "Should solve without leaking memory or stuff" {
    var allocator = std.testing.allocator;

    const file = try std.fs.cwd().openFile("inputs/d5.txt", .{});
    const fileReader = file.reader();
    defer file.close();

    var challenge = try Challenge.init(allocator, fileReader);
    defer challenge.deinit();

    try challenge.solve();
}

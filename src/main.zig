const std = @import("std");
const Reader = std.io.Reader;
const Writer = std.io.Writer;
const zsta = @import("zsta");

const AddFn = *const fn (a: c_int, b: c_int) callconv(.c) c_int;
const HelloFn = *const fn (name: [*:0]const u8) callconv(.c) void;

pub fn main() !void {
    const libFileName = if (@import("builtin").os.tag == .macos) "./foo.dylib" else "./foo.so";

    var lib = try std.DynLib.open(libFileName);
    defer lib.close();

    const add = lib.lookup(AddFn, "add") orelse {
        return error.SymbolNotFound;
    };

    const hello = lib.lookup(HelloFn, "hello") orelse {
        return error.SymbolNotFound;
    };

    // Call C functions
    const result = add(2, 40);
    std.debug.print("2 + 40 = {}\n", .{result});
    hello("Zig");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var buf :[1024]u8 = undefined;
    var reader = std.fs.File.stdin().readerStreaming(&buf);
    var writer: std.Io.Writer.Allocating = .init(allocator);
    errdefer writer.deinit();
    // var running = true;
    while (true) {
        std.debug.print("enter line: \n", .{});
        const libName = try readLine(&reader.interface, &writer);
        if (std.mem.eql(u8, ":q", libName)) {
            break;
        }
        const funName = try readLine(&reader.interface, &writer);
        const res = try invoke(allocator,libName, funName);
        std.debug.print("{s} {s}(1,2) = {d}\n", .{libName, funName, res});
    }
}

fn readLine(reader: *Reader, writer: *Writer.Allocating) ![]u8 {
    const read = try reader.streamDelimiter(&writer.writer, '\n');
    if (read != 0) {
        _ = try reader.discard(.limited(1));
    }
    const res = try writer.toOwnedSlice();
    writer.clearRetainingCapacity();
    return res;
}

fn invoke(allocator: std.mem.Allocator, libName: []u8, funName: []u8) !c_int {
    var lib = try std.DynLib.open(libName);
    defer lib.close();
    const cFunName = try allocator.allocSentinel(u8, funName.len, 0);
    defer allocator.free(cFunName);

    std.mem.copyForwards(u8, cFunName[0..funName.len], funName);

    const cFunNameConst: [:0]const u8 = cFunName;

    const fun = lib.lookup(AddFn, cFunNameConst) orelse {
        return error.SymbolNotFound;
    };
    const result = fun(1, 2);
    return result;
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}

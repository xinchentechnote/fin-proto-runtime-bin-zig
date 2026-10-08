//! Basic example: encode a small message with a fixed char array, a scalar
//! and a checksum, print the wire bytes, then decode them back.

const std = @import("std");
const codec = @import("binary_codec");

const Logon = struct {
    sender_comp_id: []const u8,
    heart_bt_int: u16,
    checksum: u32,

    fn encode(self: *const Logon, buf: *codec.Buffer) !void {
        try codec.putCharArray(buf, self.sender_comp_id, 32);
        try buf.put(u16, self.heart_bt_int);
        try buf.put(u32, codec.computeChecksum(u32, "SSE_BIN", buf.written(), self.checksum));
    }

    fn decode(allocator: std.mem.Allocator, r: *codec.Reader) codec.DecodeError!Logon {
        _ = allocator;
        const sender_comp_id = try codec.getCharArray(r, 32);
        const heart_bt_int = try r.get(u16);
        const checksum = try r.get(u32);
        return .{ .sender_comp_id = sender_comp_id, .heart_bt_int = heart_bt_int, .checksum = checksum };
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const msg = Logon{ .sender_comp_id = "SENDER", .heart_bt_int = 30, .checksum = 0 };

    var buf = codec.Buffer.init(allocator, .big);
    defer buf.deinit();
    try msg.encode(&buf);

    std.debug.print("encoded {} bytes:", .{buf.len});
    for (buf.written()) |b| std.debug.print(" {x:0>2}", .{b});
    std.debug.print("\n", .{});

    var r = codec.Reader.init(buf.written(), .big);
    const decoded = try Logon.decode(allocator, &r);
    std.debug.print("decoded sender='{s}' heart_bt_int={} checksum={}\n", .{
        decoded.sender_comp_id, decoded.heart_bt_int, decoded.checksum,
    });
}

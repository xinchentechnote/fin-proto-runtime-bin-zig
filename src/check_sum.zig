//! Checksum services for fin-proto binary protocols.
//!
//! Mirrors `fin-proto-runtime-bin-rs/src/check_sum.rs`: the four algorithms
//! registered there by name are available here, keyed by the same string
//! literals used in the DSL `@calculatedFrom("...")` attribute:
//!
//! - `CRC16`    — CRC-16/MODBUS (init 0xFFFF, reflected poly 0xA001) -> u16
//! - `CRC32`    — CRC-32/ISO-HDLC (reflected poly 0xEDB88320)          -> u32
//! - `SSE_BIN`  — byte sum folded to the low 8 bits                    -> u32
//! - `SZSE_BIN` — i32 byte sum, remainder mod 256 (may be negative)    -> i32

const std = @import("std");

/// Tagged result of a checksum computation, mirroring `check_sum::Checksum`.
pub const Checksum = union(enum) {
    u8: u8,
    u16: u16,
    u32: u32,
    i8: i8,
    i16: i16,
    i32: i32,
};

/// Compute the named checksum over `input` and coerce it to `T`.
///
/// Returns `fallback` when the algorithm is unknown or its result does not
/// fit in `T` — the same defaulting behaviour the generated Rust code gets
/// from `CHECKSUM_SERVICE_CONTEXT.get(...).unwrap_or(self.field)`.
pub fn computeChecksum(comptime T: type, comptime algorithm: []const u8, input: []const u8, fallback: T) T {
    const sum = calcChecksum(algorithm, input) orelse return fallback;
    return checksumAs(T, sum) orelse fallback;
}

fn calcChecksum(comptime algorithm: []const u8, input: []const u8) ?Checksum {
    if (comptime std.mem.eql(u8, algorithm, "CRC16")) return .{ .u16 = crc16(input) };
    if (comptime std.mem.eql(u8, algorithm, "CRC32")) return .{ .u32 = crc32(input) };
    if (comptime std.mem.eql(u8, algorithm, "SSE_BIN")) return .{ .u32 = ssebin(input) };
    if (comptime std.mem.eql(u8, algorithm, "SZSE_BIN")) return .{ .i32 = szsebin(input) };
    return null;
}

fn checksumAs(comptime T: type, sum: Checksum) ?T {
    switch (@typeInfo(T)) {
        .int => {},
        else => @compileError("checksumAs: target type must be an integer"),
    }
    // only the variant matching the field type is accepted, mirroring the
    // generated Rust code's `Checksum::U32(v) => Some(v), _ => None` match
    switch (sum) {
        inline else => |v| {
            if (T == @TypeOf(v)) return v;
            return null;
        },
    }
}

/// CRC-16/MODBUS, the "CRC16" service.
pub fn crc16(input: []const u8) u16 {
    var crc: u16 = 0xFFFF;
    for (input) |b| {
        crc ^= @as(u16, b);
        var bit: u8 = 0;
        while (bit < 8) : (bit += 1) {
            if (crc & 0x0001 != 0) {
                crc = (crc >> 1) ^ 0xA001;
            } else {
                crc >>= 1;
            }
        }
    }
    return crc;
}

/// CRC-32/ISO-HDLC (the classic zlib CRC-32), the "CRC32" service.
pub fn crc32(input: []const u8) u32 {
    var crc: u32 = 0xFFFFFFFF;
    for (input) |b| {
        crc ^= @as(u32, b);
        var bit: u8 = 0;
        while (bit < 8) : (bit += 1) {
            if (crc & 0x00000001 != 0) {
                crc = (crc >> 1) ^ 0xEDB88320;
            } else {
                crc >>= 1;
            }
        }
    }
    return ~crc;
}

/// SSE binary checksum: byte sum folded to the low 8 bits, returned as u32.
pub fn ssebin(input: []const u8) u32 {
    var sum: u32 = 0;
    for (input) |b| sum = (sum + b) & 0xFF;
    return sum;
}

/// SZSE binary checksum: i32 byte sum reduced mod 256, returned as i32.
pub fn szsebin(input: []const u8) i32 {
    var sum: i32 = 0;
    for (input) |b| sum += @as(i32, b);
    return @rem(sum, 256);
}

test "checksum known vectors" {
    try std.testing.expectEqual(@as(u16, 0x4B37), crc16("123456789"));
    try std.testing.expectEqual(@as(u16, 0xFFFF), crc16(""));
    try std.testing.expectEqual(@as(u32, 0xCBF43926), crc32("123456789"));
    // byte sum of "123456789" is 0x1DD, folded to the low 8 bits
    try std.testing.expectEqual(@as(u32, 0xDD), ssebin("123456789"));
    try std.testing.expectEqual(@as(i32, 0xDD), szsebin("123456789"));
    try std.testing.expectEqual(@as(u32, 0), ssebin(""));
}

test "computeChecksum dispatches by name and falls back" {
    const input = "123456789";
    try std.testing.expectEqual(@as(u32, 0xCBF43926), computeChecksum(u32, "CRC32", input, 7));
    try std.testing.expectEqual(@as(u16, 0x4B37), computeChecksum(u16, "CRC16", input, 7));
    try std.testing.expectEqual(@as(u32, 0xDD), computeChecksum(u32, "SSE_BIN", input, 7));
    try std.testing.expectEqual(@as(i32, 0xDD), computeChecksum(i32, "SZSE_BIN", input, 7));
    // unknown algorithm and type mismatches fall back to the field value
    try std.testing.expectEqual(@as(u32, 7), computeChecksum(u32, "NOPE", input, 7));
    try std.testing.expectEqual(@as(u8, 7), computeChecksum(u8, "CRC32", input, 7));
    try std.testing.expectEqual(@as(i32, 7), computeChecksum(i32, "SSE_BIN", input, 7));
}

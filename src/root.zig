//! Root of the `binary_codec` module. Generated code imports this module as
//! `@import("binary_codec")`, so every public symbol of the codec and the
//! checksum services is re-exported here explicitly.

const codec = @import("binary_codec.zig");
const check_sum = @import("check_sum.zig");

// binary_codec.zig
pub const DecodeError = codec.DecodeError;
pub const Buffer = codec.Buffer;
pub const Reader = codec.Reader;
pub const putCharArray = codec.putCharArray;
pub const putCharArrayWithPad = codec.putCharArrayWithPad;
pub const getCharArray = codec.getCharArray;
pub const getCharArrayTrimPad = codec.getCharArrayTrimPad;
pub const putString = codec.putString;
pub const getString = codec.getString;
pub const putList = codec.putList;
pub const getList = codec.getList;
pub const putObjectList = codec.putObjectList;
pub const getObjectList = codec.getObjectList;
pub const putStringList = codec.putStringList;
pub const getStringList = codec.getStringList;
pub const putFixedStringList = codec.putFixedStringList;
pub const putFixedStringListWithPad = codec.putFixedStringListWithPad;
pub const getFixedStringList = codec.getFixedStringList;
pub const getFixedStringListTrimPad = codec.getFixedStringListTrimPad;

// check_sum.zig
pub const Checksum = check_sum.Checksum;
pub const computeChecksum = check_sum.computeChecksum;
pub const crc16 = check_sum.crc16;
pub const crc32 = check_sum.crc32;
pub const ssebin = check_sum.ssebin;
pub const szsebin = check_sum.szsebin;

test {
    _ = codec;
    _ = check_sum;
}

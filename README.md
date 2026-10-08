# fin-proto-runtime-bin-zig

fin-proto 二进制协议 Zig 运行时库(模块名 `binary_codec`),与
[fin-proto-runtime-bin-rs](https://github.com/xinchentechnote/fin-proto-runtime-bin-rs)
(crate `binary-codec`)语义对齐,供 [fin-protoc](https://github.com/xinchentechnote/fin-protoc)
生成的 Zig 消息代码依赖。

## 组成

- `src/binary_codec.zig`:`Buffer`(编码缓冲)/`Reader`(解码游标)、大/小端标量读写、
  定长字符数组(填充/去填充)、动态字符串、长度前缀列表(标量/字符串/定长字符串/嵌套对象)。
- `src/check_sum.zig`:`CRC16`(MODBUS)、`CRC32`(ISO-HDLC)、`SSE_BIN`(字节和 &0xFF)、
  `SZSE_BIN`(字节和 mod 256)四种校验和,按 `@calculatedFrom("...")` 的名字字符串分发。
- `src/root.zig`:模块根,显式再导出全部公共符号。

## 语义约定(与 Rust 版一致)

- 字节序由 `Buffer`/`Reader` 携带(DSL `LittleEndian` 选项),默认大端。
- 定长 `char[N]` 编码超长截断、不足补空格;解码去尾空格(`zchar`/`@leftPad` 等走显式填充参数)。
- 解码不拷贝字符串:定长/动态字符串返回输入缓冲的子切片,生命周期与输入一致;
  仅 `repeat` 字段的外层数组由 decode 分配,配套生成的 `deinit(allocator)` 负责释放。
- 解码失败统一返回 `DecodeError`(`UnexpectedEof` / `InvalidUtf8` / `UnknownMessageType` / `OutOfMemory`)。

## 使用

生成代码通过 `build.zig.zon` 的 path 依赖引入本包(参考 fin-proto-sse-bin-zig):

```zig
.dependencies = .{
    .binary_codec = .{ .path = "../fin-proto-runtime-bin-zig" },
},
```

```bash
zig build test      # 运行单元测试
zig build example   # 运行 examples/basic.zig
```

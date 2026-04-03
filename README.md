# PCIe SerDes PHY Behavior Model

## 目标

本项目用于实现一个面向仿真的 PCIe SerDes PHY 行为模型，用于联调现有 Verilog MAC。

第一版只关注最小数据通路，优先把编解码连接、并行环回和 TX 串化打通。

## 第一版范围

- 只实现本端 PHY
- 不接对端 VIP / BFM
- 复用现有 8b/10b codec，不重复实现编码器
- MAC 侧接口宽度为 `32-bit`
- 顶层不输入外部工作时钟，时钟由模型内部产生
- `pclk` 由内部 `serial_clk` 分频导出
- TX 路径为 `32-bit -> 40-bit encode -> serial_tx`
- RX 路径为 `TX 侧 40-bit 编码结果并行环回 -> decode -> 32-bit`
- `tx_code[39:0]` 作为调试观察口保留

## 第一版不包含

- RX 串并转换
- RX comma 对齐
- RX 位边界恢复
- 复杂 PIPE 控制语义
- 多 lane
- 电气空闲、功耗状态、速率切换
- 对端链路行为建模
- 真正的 TX 串行到 RX 串行闭环恢复

## 架构

```text
                  +----------------------+
                  |         MAC          |
                  |   32-bit PIPE side   |
                  +----------+-----------+
                             |
                             v
                 +------------------------+
                 |  pcie_phy_model_top    |
                 |------------------------|
                 |  tx_path               |
                 |  rx_path               |
                 |  internal 40b loopback |
                 +-----------+------------+
                             |
                             v
                         serial_tx
```

## 关键约定

- `tx_code[39]` 为最先发送的 bit
- `tx_code[0]` 为最后发送的 bit
- serializer 按 `MSB-first` 输出
- 第一版固定 `serial_clk : pclk = 40 : 1`
- TX 和 RX 使用同一时钟源
- RX 第一版直接使用 TX 编码后的并行 `40-bit` 数据，不从 `serial_tx` 恢复

## 当前状态

- 已建立最小骨架：
  - `rtl/pcie_phy_model_top.sv`
  - `rtl/tx_path.sv`
  - `rtl/rx_path.sv`
  - `rtl/serializer.sv`
- TX 已接入现有 encoder：
  - `rtl/enc_8b10b_4bytes.v`
  - `rtl/enc_8b10b.v`
- RX 仍为骨架，等待现有 decoder 接入
- 当前 serializer 已按 `MSB-first` 实现

## 目录

```text
serdes_phy_model/
├── README.md
└── rtl/
    ├── pcie_phy_model_top.sv
    ├── tx_path.sv
    ├── rx_path.sv
    ├── serializer.sv
    ├── enc_8b10b_4bytes.v
    └── enc_8b10b.v
```

## 下一步

- 接入现有 `40b -> 32b` decoder
- 完成 TX `40-bit` 并行环回到 RX decode 的联调
- 增加最小 testbench，验证：
  - 编码输出与解码输入位序一致
  - `rxdata/rxdatak` 能正确回读
  - `serial_tx` 的 bit 顺序符合约定

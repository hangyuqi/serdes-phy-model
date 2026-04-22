# SerDes PHY 验证环境说明（tb_new）

## 1. 用途

针对 `serdes_phy_model` 的简易 PCIe PHY 模型，提供一个轻量、手写 OOP 风格的 SystemVerilog 测试平台。通过**串行环回**（TX 串行口经可配置延迟回接到 RX 串行口）验证 TX 编码 / 序列化 与 RX 解串 / 字节对齐 / 解码 通路的端到端功能。

不依赖 UVM，仅用原生 SystemVerilog 类、interface、clocking block、plusargs。

## 2. 目录结构

```
tb_new/
├── Makefile              VCS 编译 + 仿真 + verdi 查看入口
├── rtl.f                 RTL 文件列表（被 Makefile 引用）
├── tb.f                  TB 文件列表
├── env/                  通用验证基础设施
│   ├── tb_top.sv         testbench 顶层模块
│   ├── phy_if.sv         DUT/TB 接口 + clocking block
│   ├── phy_trans.sv      基本激励 transaction
│   ├── pcie_ts_pkt.sv    PCIe TS1 / TS2 训练包生成器
│   ├── base_test.sv      测试基类（reset / stim / monitor / report）
│   └── phy_checker.sv    简易 scoreboard（exp_queue + 计数器）
├── tc/                   具体 testcase
│   ├── test_random_payload.sv
│   └── test_ts_loopback.sv
├── build/                VCS 编译产物（simv、csrc、daidir、comp.log）
└── run/<testname>/       每个 case 独立运行目录（fsdb、log、ucli.key）
```

## 3. 架构

```
           ┌──────────────────────────────────────────┐
           │               tb_top (module)            │
           │                                          │
           │  ┌──────────┐   serial_tx   ┌─────────┐  │
           │  │   DUT    │───────delay──▶│ loopback│  │
           │  │ (PHY)    │◀─serial_rx────│         │  │
           │  └────┬─────┘               └─────────┘  │
           │       │ vif (phy_if)                     │
           │       ▼                                  │
           │  ┌──────────────────────────────────┐    │
           │  │ test dispatcher (+TESTNAME)      │    │
           │  │   ├─ test_random_payload         │    │
           │  │   └─ test_ts_loopback            │    │
           │  └──────────────┬───────────────────┘    │
           └─────────────────┼────────────────────────┘
                             ▼
                    ┌────────────────┐
                    │   base_test    │
                    │  ├─ reset()    │
                    │  ├─ gen_stim() │──▶ exp_queue ──┐
                    │  └─ monitor_rx │◀── RX 采样 ────┤
                    └────────────────┘                │
                             │                        │
                             ▼                        │
                    ┌────────────────┐                │
                    │  phy_checker   │◀───────────────┘
                    │  exp_queue[$]  │
                    │  err_cnt / ... │
                    └────────────────┘
```

关键点：
- **无 driver/monitor 类**：激励与采样直接在 `base_test` 里通过 `vif.cb` 完成。
- **无 sequencer**：tc 继承 `base_test`，重写 `gen_stimulus()` 即可。
- **环回**：`tb_top` 内部 `serial_rx <= #loopback_delay serial_tx;`，`loopback_delay` 每个 case 随机化一次（100ps × [1,5]）。
- **时钟 `pclk` 由 DUT 输出**（`pcie_phy_model_top` 的 output），TB 不产生。

## 4. 核心文件说明

### 4.1 `env/phy_if.sv`

- 输入 `pclk`（由 DUT 驱动），包含 TX / RX 数据、valid、rst_n、rate、错误信号。
- 单个 clocking block `cb @(posedge pclk)`，采样/驱动偏移使用 RTL 宏 `PCS_PD`。
- 当前未定义 modport。

### 4.2 `env/phy_trans.sv`

- 随机 32 位 `data` + 4 位 `datak`。
- 约束 `k_char_c`: `datak inside {4'h0, 4'h1, 4'h3, 4'hF}`——四种常用合法 K 字节位置。

### 4.3 `env/pcie_ts_pkt.sv`

- 按 PCIe Gen1 TS1/TS2 结构打包出 32bit × N 拍的 beats。
- 字段：`link_num`、`lane_num`、`n_fts`、`rate_id`、`ts_id`，随机后通过辅助函数转为 `phy_trans` 序列。
- 约束 `default_c`：`link_num == 8'h01`，`lane_num == 8'h00`（其余随机）。

### 4.4 `env/base_test.sv`

执行序列（`run()` 内部）：
1. `reset()` — 拉低 `rst_n` 10 ns，再拉高并等 100 ns。
2. 轮询等待 DUT 内部 ready（最多 500 cycles）。
3. `fork gen_stimulus(); monitor_rx(); join_any`。
4. 附加 `repeat(100) @(vif.cb)` 作为排空。
5. `checker_inst.report()` → `$finish`。

`monitor_rx()`：`forever begin @(vif.cb); if(rx_valid) 比对 exp_queue 首项 end`。

### 4.5 `env/phy_checker.sv`

- 持有 `phy_trans exp_queue[$]`、`err_cnt`、`match_cnt`。
- `report()` 打印结果（带 ANSI 色码）。

### 4.6 `env/tb_top.sv`

- 实例化 DUT、串行环回、fsdb dump、test dispatcher（通过 `+TESTNAME=xxx` 字符串分发）。
- `+OUT_DIR=xxx` 决定 fsdb 输出路径。

### 4.7 `tc/*.sv`

- **`test_random_payload`**：100 拍随机 `(data, datak)`，每拍推进一次 clocking block；TX 与期望同时下发。
- **`test_ts_loopback`**：随机化 TS1 / TS2 包并连续发送若干组。

## 5. 仿真流程

### 5.1 编译

```bash
make comp                 # 仅编译，生成 build/simv
```

底层命令（简化）：
```
vcs -full64 -sverilog -debug_access+all -kdb -lca \
    -timescale=1ns/1ps \
    -f rtl.f -f tb.f -o build/simv
```

### 5.2 运行

```bash
make run TESTNAME=test_random_payload          # 随机 seed
make run TESTNAME=test_ts_loopback SEED=12345  # 固定 seed
```

运行目录为 `run/<TESTNAME>/`，生成 `tb.fsdb`、`sim.log`、`ucli.key`。

### 5.3 查看波形

```bash
make verdi TESTNAME=test_random_payload
```

### 5.4 常用 plusargs

| plusarg              | 含义                                  |
|----------------------|---------------------------------------|
| `+TESTNAME=xxx`      | 选择 tc，默认 `test_random_payload`   |
| `+OUT_DIR=xxx`       | fsdb 输出目录                         |
| `+ntb_random_seed=N` | VCS 随机种子（Makefile 变量 SEED）    |

## 6. 如何新增一个 testcase

1. 在 `tc/` 下新建 `test_xxx.sv`，`class test_xxx extends base_test`，重写 `gen_stimulus()`。
2. 在 `tb.f` 中加入该文件路径。
3. 在 `env/tb_top.sv` 的 dispatcher 里追加 `else if (test_name == "test_xxx")` 分支。
4. `make run TESTNAME=test_xxx` 即可。

## 7. 约束与已知局限

- **环回比对是严格 1:1**：实际 RX 经 byte aligner 会丢弃对齐前若干拍，`exp_queue` 当前不做前缀丢弃 / 对齐同步，因此对 stimulus 要求本身带稳定的 comma 周期，否则会出现前几拍 mismatch。
- **`join_any` 语义**：`monitor_rx` 为 `forever`，`gen_stimulus` 结束即触发 join_any；monitor 之后仍在背景跑，`$finish` 时整体终止。队列尾部未到达的数据不会被重新报错，但也可能被"沉默丢弃"。
- **无 watchdog**：任何挂死都需要手动 Ctrl-C。
- **无断言 / 无 covergroup**：协议合法性与覆盖率收集为空。
- **pclk 由 DUT 输出**：DUT 未工作前 `@(vif.cb)` 会等 DUT 内部起振。
- **时间单位**：`tb_top` 使用 `timeunit 1ns / timeprecision 1ps`；clocking block 采样偏移用 RTL 侧宏 `PCS_PD` 控制。
- **无 reset 类 / 无 factory**：当前规模够用，规模扩大后建议抽象。

## 8. 信号与错误约定

- `decode_err`：8b/10b 解码发现非法码。
- `disp_err`：running disparity 非法。
- 任一出现均由 `base_test` / `phy_checker` 累计为错误，不影响仿真继续（`$error` 不终止）。

## 9. 返回码与判定

- 最终结果来自 `phy_checker.report()`：
  - `err_cnt == 0 && match_cnt > 0` → PASSED。
  - 否则 → FAILED。
- 当前未用 `$fatal`，Makefile 未据此设置 shell 退出码；CI 需要 grep log 判定。

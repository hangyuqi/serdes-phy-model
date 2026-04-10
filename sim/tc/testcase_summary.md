# Testcase Summary — serdes_phy_model

## Architecture Overview

```
TX Path:  txdata/txdatak -> enc_8b10b_4bytes -> serializer -> serial_tx
                                                                 |
                                                        (external loopback)
                                                                 |
RX Path:  rxdata/rxdatak <- decoder_8b10b   <- deserializer <- serial_rx
```

Pipeline latency (serial loopback): **3 pclk edges**
- Encoder: 1 pclk (registered)
- Serializer + Deserializer: 1 pclk (40 serial_clk = 1 pclk period)
- Decoder (combinational) + RX output register: 1 pclk

---

## 1. smoke_test

**File**: `sim/tc/smoke_test.sv`

**Coverage**: TX path only (encoder + serializer)

| Phase | Test Point | Description |
|-------|-----------|-------------|
| Phase 1 | Reset | Assert `rst_n` for 200ns, release, wait for `pclk` toggling |
| Phase 2 | K-code encoding | Send K28.5 comma (`0xBCBCBCBC`, K=`4'b1111`), check `tx_code != 0` and `tx_code_valid == 1` |
| Phase 3 | D-code encoding & differentiation | Send data (`0x04030201`, K=`4'b0000`), check `tx_code != 0` and differs from Phase 2 comma encoding |
| Phase 4 | Serial output bit-level verification | Send `0xDEADBEEF`, capture 40-bit `serial_tx` MSB-first, compare with `tx_code`; then verify serializer returns to idle (`tx_active=0`, `serial_tx=0`) |
| Phase 5 | Continuous encoding stress | Send 8 random data words back-to-back, check every `tx_code != 0` |

**Goal**: Verify TX encoder produces valid non-zero encodings, K/D differentiation, serializer bit-level correctness, and idle behavior.

---

## 2. ts1_tx_test

**File**: `sim/tc/ts1_tx_test.sv`

**Coverage**: TX path only (encoder)

| Phase | Test Point | Description |
|-------|-----------|-------------|
| Phase 1 | Reset | Standard reset sequence |
| Phase 2 | TS1 ordered set encoding | Send 8 consecutive Gen1 TS1 ordered sets (4 words each = 32 words total), check each word's `tx_code != 0` |

**TS1 word definitions** (PAD replaces Link#/Lane#/N_FTS/Rate/Ctrl):

| Word | Content | K flags |
|------|---------|---------|
| W0 | `{PAD, PAD, PAD, COM}` | `4'b1111` |
| W1 | `{TS1_ID, TS1_ID, PAD, PAD}` | `4'b0011` |
| W2 | `{TS1_ID x4}` | `4'b0000` |
| W3 | `{TS1_ID x4}` | `4'b0000` |

**Goal**: Verify encoder can correctly encode a complete, realistic Gen1 TS1 ordered set stream without producing zero-valued `tx_code`.

---

## 3. ts1_single_word_loopback_test

**File**: `sim/tc/ts1_single_word_loopback_test.sv`

**Coverage**: TX + RX full serial loopback path

| Phase | Test Point | Description |
|-------|-----------|-------------|
| Phase 1 | Reset | Standard reset sequence |
| Phase 2 | TS1 serial loopback | Send 2 consecutive Gen1 TS1 ordered sets (8 words) back-to-back via `fork-join`; driver holds `tx_valid` high; checker waits 3 pclk pipeline fill then verifies each word |

**Check items per word**:
- `rx_valid == 1`
- `rxdata` matches expected TS1 word
- `rxdatak` matches expected K flags
- `decode_err == 0`
- `disp_err == 0`

**Goal**: End-to-end verification of the serial loopback path (encoder -> serializer -> external loopback -> deserializer -> decoder -> RX output register) with Gen1 TS1 data, confirming data integrity and no decode/disparity errors.

---

## 4. ts1_rx_decode_test

**File**: `sim/tc/ts1_rx_decode_test.sv`

**Coverage**: TX + RX full serial loopback path (stress)

| Phase | Test Point | Description |
|-------|-----------|-------------|
| Phase 1 | Reset | Standard reset sequence |
| Phase 2 | Multi-set TS1 loopback decode | Send 4 consecutive Gen1 TS1 ordered sets (16 words) back-to-back via `fork-join`; same per-word checks as loopback test; prints TS1 boundary markers every 4 words |

**Check items per word**: Same as `ts1_single_word_loopback_test`.

**Goal**: Stress test the RX decode path with a longer TS1 stream (4 ordered sets / 16 words), verifying the decoder's running disparity chain tracks correctly across multiple frames and no errors accumulate.

---

## Test Coverage Matrix

| Feature | smoke | ts1_tx | ts1_loopback | ts1_rx_decode |
|---------|:-----:|:------:|:------------:|:-------------:|
| Reset sequence | x | x | x | x |
| 8b/10b encoder (K-code) | x | x | x | x |
| 8b/10b encoder (D-code) | x | x | x | x |
| K/D encoding differentiation | x | | | |
| Serializer bit-level output | x | | | |
| Serializer idle behavior | x | | | |
| Continuous encoding | x | x | | |
| Serial loopback (TX->RX) | | | x | x |
| 10b/8b decoder correctness | | | x | x |
| Disparity chain (multi-frame) | | | x | x |
| TS1 ordered set format | | x | x | x |

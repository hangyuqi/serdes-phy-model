`timescale 1ns/1ps

module tb_top;

    // ----------------------------------------------------------------
    // Signal declarations
    // ----------------------------------------------------------------
    logic        rst_n;
    logic        rate;
    logic [31:0] txdata;
    logic [3:0]  txdatak;
    logic        tx_valid;

    logic [31:0] rxdata;
    logic [3:0]  rxdatak;
    logic        rx_valid;
    logic        decode_err;
    logic        disp_err;
    logic [39:0] tx_code;
    logic        tx_code_valid;
    logic        serial_tx;
    logic        serial_rx;
    logic        pclk;

    // ----------------------------------------------------------------
    // DUT
    // ----------------------------------------------------------------
    pcie_phy_model_top dut (
        .rst_n      (rst_n),
        .rate       (rate),
        .serial_rx  (serial_rx),
        .txdata     (txdata),
        .txdatak    (txdatak),
        .tx_valid   (tx_valid),
        .rxdata     (rxdata),
        .rxdatak    (rxdatak),
        .rx_valid   (rx_valid),
        .decode_err (decode_err),
        .disp_err   (disp_err),
        .tx_code    (tx_code),
        .tx_code_valid(tx_code_valid),
        .serial_tx  (serial_tx),
        .pclk       (pclk)
    );

    // Serial loopback with configurable link delay.
    // Tests set link_delay (realtime) before reset release to simulate physical channel latency.
    realtime link_delay = 0;
    always @(serial_tx) serial_rx <= #(link_delay) serial_tx;

    // ----------------------------------------------------------------
    // Test infrastructure
    // ----------------------------------------------------------------
    reg [8*64-1:0] tc_name;
    int            err_count;

    // Auto-generated: includes all tc/*.sv tasks and run_testcase()
    `include "tc_dispatch.svh"

    initial begin
        // Get testcase name from plusarg
        if (!$value$plusargs("tc=%s", tc_name))
            tc_name = "smoke_test";

        // FSDB dump is available in the VCS/Verdi flow, but not in Icarus.
`ifndef __ICARUS__
        $fsdbDumpfile({tc_name, ".fsdb"});
        $fsdbDumpvars(0, tb_top);
`endif

        // Initialize inputs
        rst_n    = 1'b0;
        rate     = 1'b0;
        txdata   = 32'd0;
        txdatak  = 4'd0;
        tx_valid = 1'b0;
        err_count = 0;

        $display("========================================");
        $display("[INFO] Testcase: %s", tc_name);
        $display("========================================");

        // Dispatch testcase
        run_testcase();

        // Final report
        $display("========================================");
        if (err_count == 0)
            $display("[PASS] %s — 0 errors", tc_name);
        else
            $display("[FAIL] %s — %0d error(s)", tc_name, err_count);
        $display("========================================");

        #100ns;
        $finish;
    end

    // Timeout watchdog
    initial begin
        #1000000ns;
        $display("[ERROR] Simulation timeout!");
        $finish;
    end

endmodule

module tb_top;
    timeunit 1ns;
    timeprecision 1ps;

    logic pclk; 
    logic serial_tx, serial_rx;

    phy_if vif(pclk);

    // 串行环回
    always @(serial_tx) begin
        #( $urandom_range(1, 5) * 100ps ); 
        serial_rx <= serial_tx;
    end

    pcie_phy_dut u_dut (
        .rst_n      (vif.rst_n),
        .rate       (vif.rate),
        .serial_rx  (serial_rx),
        .txdata     (vif.txdata),
        .txdatak    (vif.txdatak),
        .tx_valid   (vif.tx_valid),
        .rxdata     (vif.rxdata),
        .rxdatak    (vif.rxdatak),
        .rx_valid   (vif.rx_valid),
        .decode_err (vif.decode_err),
        .disp_err   (vif.disp_err),
        .serial_tx  (serial_tx),
        .pclk       (pclk)
    );

    initial begin
        $fsdbDumpfile("tb.fsdb");
        $fsdbDumpvars(0, tb_top);
    end

    // Test 启动分发器
    initial begin
        base_test t;
        string test_name;
        
        if(!$value$plusargs("TESTNAME=%s", test_name)) begin
            test_name = "test_random_payload"; // default
        end

        $display("\n===================================================");
        $display(" [TB_TOP] Starting Execution of %s", test_name);
        $display("===================================================\n");

        if (test_name == "test_random_payload") begin
            test_random_payload t_rand = new(vif);
            t = t_rand;
        end else if (test_name == "test_ts_loopback") begin
            test_ts_loopback t_ts = new(vif);
            t = t_ts;
        end else begin
            $error("Unknown TESTNAME: %s, falling back to base_test", test_name);
            t = new(vif);
        end
        
        t.run();
        $finish;
    end
endmodule
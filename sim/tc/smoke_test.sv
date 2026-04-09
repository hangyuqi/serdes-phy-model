task smoke_test();
    logic [39:0] tx_code_comma;
    logic [39:0] tx_code_data;
    logic [39:0] serial_captured;

    $display("[INFO] === smoke_test start ===");

    // ----------------------------------------------------------
    // Phase 1: Reset
    // ----------------------------------------------------------
    rst_n = 1'b0;
    #200ns;
    rst_n = 1'b1;
    $display("[INFO] Reset released");

    // Wait for pclk to start toggling
    @(posedge pclk);
    @(posedge pclk);

    // ----------------------------------------------------------
    // Phase 2: Send K28.5 comma (4 identical K-code bytes)
    // ----------------------------------------------------------
    @(posedge pclk);
    #`PCS_PD;
    txdata   = 32'hBCBC_BCBC;  // K28.5 = 8'hBC
    txdatak  = 4'b1111;
    tx_valid = 1'b1;
    @(posedge pclk);
    #`PCS_PD;
    tx_valid = 1'b0;

    // Wait 1 pclk for encoder pipeline (registered output)
    @(posedge pclk);

    // Check: tx_code should be non-zero
    if (tx_code === 40'd0) begin
        $display("[ERROR] Phase 2: K28.5 encoded tx_code is all zeros");
        err_count++;
    end else begin
        $display("[INFO] Phase 2: K28.5 tx_code = 0x%010h", tx_code);
    end

    // Check: tx_code_valid should be high
    if (dut.tx_code_valid !== 1'b1) begin
        $display("[ERROR] Phase 2: tx_code_valid not asserted after K28.5");
        err_count++;
    end

    tx_code_comma = tx_code;

    // ----------------------------------------------------------
    // Phase 3: Send data pattern D1.0, D2.0, D3.0, D4.0
    // ----------------------------------------------------------
    @(posedge pclk);
    #`PCS_PD;
    txdata   = 32'h0403_0201;  // byte0=01, byte1=02, byte2=03, byte3=04
    txdatak  = 4'b0000;
    tx_valid = 1'b1;
    @(posedge pclk);
    #`PCS_PD;
    tx_valid = 1'b0;

    @(posedge pclk);

    if (tx_code === 40'd0) begin
        $display("[ERROR] Phase 3: Data encoded tx_code is all zeros");
        err_count++;
    end else begin
        $display("[INFO] Phase 3: Data tx_code = 0x%010h", tx_code);
    end

    // Encoding of data should differ from K28.5 comma
    if (tx_code === tx_code_comma) begin
        $display("[ERROR] Phase 3: Data tx_code same as K28.5 — encoding suspect");
        err_count++;
    end else begin
        $display("[INFO] Phase 3: Data tx_code differs from comma — OK");
    end

    tx_code_data = tx_code;

    // ----------------------------------------------------------
    // Phase 4: Verify serial_tx MSB-first output
    //   Capture 40 serial_clk cycles of serial_tx and compare
    //   with the tx_code that the serializer is currently shifting.
    // ----------------------------------------------------------
    // Send another data word so tx_code is stable for serializer to load
    @(posedge pclk);
    #`PCS_PD;
    txdata   = 32'hDEAD_BEEF;
    txdatak  = 4'b0000;
    tx_valid = 1'b1;
    @(posedge pclk);
    #`PCS_PD;
    tx_valid = 1'b0;
    @(posedge pclk);
    // tx_code now has the encoding of DEADBEEF

    // Wait for serializer to load this word (bit_count reaches WIDTH-1)
    wait (dut.u_tx_path.u_serializer.bit_count == 6'd39);
    @(posedge dut.serial_clk);
    // Serializer just loaded tx_code into shift_reg.
    // Now capture 40 bits MSB-first.
    begin
        logic [39:0] expected_code;
        expected_code = tx_code;

        for (int i = 39; i >= 0; i--) begin
            @(posedge dut.serial_clk);
            serial_captured[i] = serial_tx;
        end

        if (serial_captured !== expected_code) begin
            $display("[ERROR] Phase 4: serial_tx mismatch");
            $display("  expected: 0x%010h", expected_code);
            $display("  captured: 0x%010h", serial_captured);
            err_count++;
        end else begin
            $display("[INFO] Phase 4: serial_tx matches tx_code — MSB-first verified");
        end
    end

    repeat (2) @(posedge dut.serial_clk);
    #1;
    if (dut.u_tx_path.u_serializer.tx_active !== 1'b0 || serial_tx !== 1'b0) begin
        $display("[ERROR] Phase 4: serializer did not return to idle after valid deassert");
        err_count++;
    end else begin
        $display("[INFO] Phase 4: serializer returns to idle when no new valid word arrives");
    end

    // ----------------------------------------------------------
    // Phase 5: Continuous encoding — send several words
    // ----------------------------------------------------------
    for (int i = 0; i < 8; i++) begin
        @(posedge pclk);
        #`PCS_PD;
        txdata   = $urandom;
        txdatak  = 4'b0000;
        tx_valid = 1'b1;
        @(posedge pclk);
        #`PCS_PD;
        tx_valid = 1'b0;
        @(posedge pclk);
        if (tx_code === 40'd0) begin
            $display("[ERROR] Phase 5: tx_code zero on iteration %0d", i);
            err_count++;
        end
    end
    $display("[INFO] Phase 5: Continuous encoding — 8 words sent");

    // Let simulation run a bit more for waveform observation
    repeat (20) @(posedge pclk);

    $display("[INFO] === smoke_test end ===");
endtask

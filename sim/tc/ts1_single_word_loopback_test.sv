task ts1_single_word_loopback_test();
    // Single 32-bit TS1-like word:
    //   symbol0 = COM, symbol1 = PAD, symbol2 = PAD, symbol3 = TS1_ID
    // Byte0 is the first symbol presented to the encoder.
    localparam logic [7:0] COM    = 8'hBC;  // K28.5
    localparam logic [7:0] PAD    = 8'hF7;  // K23.7
    localparam logic [7:0] TS1_ID = 8'h4A;  // D10.2

    localparam logic [31:0] TS1_WORD = {TS1_ID, PAD, PAD, COM};
    localparam logic [3:0]  TS1_K    = 4'b0111;

    logic [39:0] encoded_ts1_word;

    $display("[INFO] === ts1_single_word_loopback_test start ===");

    // ----------------------------------------------------------
    // Phase 1: Reset
    // ----------------------------------------------------------
    rst_n = 1'b0;
    #200ns;
    rst_n = 1'b1;
    $display("[INFO] Reset released");

    @(posedge pclk);
    @(posedge pclk);

    // ----------------------------------------------------------
    // Phase 2: Send one 32-bit TS1 word into the TX encoder
    // ----------------------------------------------------------
    @(posedge pclk);
    #`PCS_PD;
    txdata   = TS1_WORD;
    txdatak  = TS1_K;
    tx_valid = 1'b1;

    // Encoder output becomes valid on the next pclk.
    @(posedge pclk);
    #`PCS_PD;

    if (tx_code === 40'd0) begin
        $display("[ERROR] TS1 single word: encoded tx_code is zero");
        err_count++;
    end else begin
        $display("[INFO] TS1 single word: tx_code = 0x%010h", tx_code);
    end

    if (dut.tx_code_valid !== 1'b1) begin
        $display("[ERROR] TS1 single word: tx_code_valid not asserted");
        err_count++;
    end

    encoded_ts1_word = tx_code;

    tx_valid = 1'b0;

    // ----------------------------------------------------------
    // Phase 3: RX decodes the looped-back 40-bit code on next pclk
    // ----------------------------------------------------------
    @(posedge pclk);
    #1;

    if (rx_valid !== 1'b1) begin
        $display("[ERROR] TS1 single word: rx_valid not asserted");
        err_count++;
    end

    if (rxdata !== TS1_WORD) begin
        $display("[ERROR] TS1 single word: rxdata mismatch exp=0x%08h got=0x%08h",
                 TS1_WORD, rxdata);
        err_count++;
    end else begin
        $display("[INFO] TS1 single word: rxdata = 0x%08h — OK", rxdata);
    end

    if (rxdatak !== TS1_K) begin
        $display("[ERROR] TS1 single word: rxdatak mismatch exp=4'b%04b got=4'b%04b",
                 TS1_K, rxdatak);
        err_count++;
    end else begin
        $display("[INFO] TS1 single word: rxdatak = 4'b%04b — OK", rxdatak);
    end

    if (decode_err) begin
        $display("[ERROR] TS1 single word: decode_err asserted");
        err_count++;
    end

    if (disp_err) begin
        $display("[ERROR] TS1 single word: disp_err asserted");
        err_count++;
    end

    if (!decode_err && !disp_err) begin
        $display("[INFO] TS1 single word: 40b loopback decode passed (tx_code=0x%010h)",
                 encoded_ts1_word);
    end

    repeat (10) @(posedge pclk);

    $display("[INFO] === ts1_single_word_loopback_test end ===");
endtask

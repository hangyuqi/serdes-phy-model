task ts1_tx_test();
    // PCIe TS1 Ordered Set symbol definitions
    localparam logic [7:0] COM    = 8'hBC;  // K28.5
    localparam logic [7:0] PAD    = 8'hF7;  // K23.7
    localparam logic [7:0] TS1_ID = 8'h4A;  // D10.2

    // TS1 ordered set: 16 symbols, sent as 4 x 32-bit words
    //   Word 0: COM,    PAD,    PAD,    PAD      (all K)
    //   Word 1: PAD,    PAD,    TS1_ID, TS1_ID   (2K + 2D)
    //   Word 2: TS1_ID, TS1_ID, TS1_ID, TS1_ID   (all D)
    //   Word 3: TS1_ID, TS1_ID, TS1_ID, TS1_ID   (all D)
    localparam logic [31:0] TS1_W0 = {PAD,    PAD,    PAD,    COM};
    localparam logic [3:0]  TS1_K0 = 4'b1111;
    localparam logic [31:0] TS1_W1 = {TS1_ID, TS1_ID, PAD,    PAD};
    localparam logic [3:0]  TS1_K1 = 4'b0011;
    localparam logic [31:0] TS1_W2 = {TS1_ID, TS1_ID, TS1_ID, TS1_ID};
    localparam logic [3:0]  TS1_K2 = 4'b0000;
    localparam logic [31:0] TS1_W3 = {TS1_ID, TS1_ID, TS1_ID, TS1_ID};
    localparam logic [3:0]  TS1_K3 = 4'b0000;

    int num_ts1 = 8;  // number of consecutive TS1 ordered sets to send

    $display("[INFO] === ts1_tx_test start ===");

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
    // Phase 2: Send consecutive TS1 ordered sets
    // ----------------------------------------------------------
    for (int i = 0; i < num_ts1; i++) begin
        // Word 0: COM + 3x PAD
        @(posedge pclk);
        #`PCS_PD;
        txdata   = TS1_W0;
        txdatak  = TS1_K0;
        tx_valid = 1'b1;
        @(posedge pclk);
        #`PCS_PD;
        tx_valid = 1'b0;
        @(posedge pclk);

        if (tx_code === 40'd0) begin
            $display("[ERROR] TS1[%0d] Word0 (COM+PAD): tx_code is zero", i);
            err_count++;
        end else begin
            $display("[INFO] TS1[%0d] Word0 (COM+PAD): tx_code = 0x%010h", i, tx_code);
        end

        // Word 1: 2x PAD + 2x TS1_ID
        @(posedge pclk);
        #`PCS_PD;
        txdata   = TS1_W1;
        txdatak  = TS1_K1;
        tx_valid = 1'b1;
        @(posedge pclk);
        #`PCS_PD;
        tx_valid = 1'b0;
        @(posedge pclk);

        if (tx_code === 40'd0) begin
            $display("[ERROR] TS1[%0d] Word1 (PAD+TS1_ID): tx_code is zero", i);
            err_count++;
        end else begin
            $display("[INFO] TS1[%0d] Word1 (PAD+TS1_ID): tx_code = 0x%010h", i, tx_code);
        end

        // Word 2: 4x TS1_ID
        @(posedge pclk);
        #`PCS_PD;
        txdata   = TS1_W2;
        txdatak  = TS1_K2;
        tx_valid = 1'b1;
        @(posedge pclk);
        #`PCS_PD;
        tx_valid = 1'b0;
        @(posedge pclk);

        if (tx_code === 40'd0) begin
            $display("[ERROR] TS1[%0d] Word2 (TS1_ID x4): tx_code is zero", i);
            err_count++;
        end else begin
            $display("[INFO] TS1[%0d] Word2 (TS1_ID x4): tx_code = 0x%010h", i, tx_code);
        end

        // Word 3: 4x TS1_ID
        @(posedge pclk);
        #`PCS_PD;
        txdata   = TS1_W3;
        txdatak  = TS1_K3;
        tx_valid = 1'b1;
        @(posedge pclk);
        #`PCS_PD;
        tx_valid = 1'b0;
        @(posedge pclk);

        if (tx_code === 40'd0) begin
            $display("[ERROR] TS1[%0d] Word3 (TS1_ID x4): tx_code is zero", i);
            err_count++;
        end else begin
            $display("[INFO] TS1[%0d] Word3 (TS1_ID x4): tx_code = 0x%010h", i, tx_code);
        end

        $display("[INFO] TS1[%0d] ordered set complete", i);
    end

    // Let simulation run for waveform observation
    repeat (20) @(posedge pclk);

    $display("[INFO] === ts1_tx_test end ===");
endtask

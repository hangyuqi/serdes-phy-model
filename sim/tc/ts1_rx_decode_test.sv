task ts1_rx_decode_test();
    // PCIe TS1 Ordered Set symbol definitions
    localparam logic [7:0] COM    = 8'hBC;  // K28.5
    localparam logic [7:0] PAD    = 8'hF7;  // K23.7
    localparam logic [7:0] TS1_ID = 8'h4A;  // D10.2

    // TS1 ordered set: 16 symbols, sent as 4 x 32-bit words
    localparam logic [31:0] TS1_W0 = {PAD,    PAD,    PAD,    COM};
    localparam logic [3:0]  TS1_K0 = 4'b1111;
    localparam logic [31:0] TS1_W1 = {TS1_ID, TS1_ID, PAD,    PAD};
    localparam logic [3:0]  TS1_K1 = 4'b0011;
    localparam logic [31:0] TS1_W2 = {TS1_ID, TS1_ID, TS1_ID, TS1_ID};
    localparam logic [3:0]  TS1_K2 = 4'b0000;
    localparam logic [31:0] TS1_W3 = {TS1_ID, TS1_ID, TS1_ID, TS1_ID};
    localparam logic [3:0]  TS1_K3 = 4'b0000;

    int num_ts1 = 4;  // number of consecutive TS1 ordered sets
    int total_words;

    // Expected value arrays
    logic [31:0] exp_data [0:15];
    logic [3:0]  exp_k    [0:15];

    total_words = num_ts1 * 4;

    for (int i = 0; i < num_ts1; i++) begin
        exp_data[i*4+0] = TS1_W0;  exp_k[i*4+0] = TS1_K0;
        exp_data[i*4+1] = TS1_W1;  exp_k[i*4+1] = TS1_K1;
        exp_data[i*4+2] = TS1_W2;  exp_k[i*4+2] = TS1_K2;
        exp_data[i*4+3] = TS1_W3;  exp_k[i*4+3] = TS1_K3;
    end

    $display("[INFO] === ts1_rx_decode_test start ===");
    $display("[INFO] Sending %0d TS1 ordered sets (%0d words total)", num_ts1, total_words);

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
    // Phase 2: Drive TS1 data back-to-back (tx_valid held high)
    //          and check rxdata with pipeline delay
    //
    // Pipeline (serial loopback): txdata driven at EdgeN+PCS_PD
    //           -> tx_code valid after EdgeN+1 (encoder registered)
    //           -> deserialized data after EdgeN+2 (serial loopback)
    //           -> rxdata valid after EdgeN+3 (decoder + rx_path registered)
    // ----------------------------------------------------------
    fork
        // --- Driver: feed TS1 words continuously ---
        begin
            for (int i = 0; i < total_words; i++) begin
                @(posedge pclk);
                #`PCS_PD;
                txdata   = exp_data[i];
                txdatak  = exp_k[i];
                tx_valid = 1'b1;
            end
            @(posedge pclk);
            #`PCS_PD;
            tx_valid = 1'b0;
        end

        // --- Checker: verify rxdata after 3-edge pipeline ---
        begin
            // Wait 3 posedges for pipeline to fill (serial loopback adds 1 cycle)
            @(posedge pclk);
            @(posedge pclk);
            @(posedge pclk);

            for (int i = 0; i < total_words; i++) begin
                @(posedge pclk);
                #1;  // let non-blocking assignments settle

                if (rx_valid !== 1'b1) begin
                    $display("[ERROR] Word[%0d]: rx_valid not asserted", i);
                    err_count++;
                end

                // Data check
                if (rxdata !== exp_data[i]) begin
                    $display("[ERROR] Word[%0d]: rxdata mismatch — exp=0x%08h got=0x%08h",
                             i, exp_data[i], rxdata);
                    err_count++;
                end else begin
                    $display("[INFO]  Word[%0d]: rxdata=0x%08h — OK", i, rxdata);
                end

                // K-code check
                if (rxdatak !== exp_k[i]) begin
                    $display("[ERROR] Word[%0d]: rxdatak mismatch — exp=4'b%04b got=4'b%04b",
                             i, exp_k[i], rxdatak);
                    err_count++;
                end

                // Error flag check
                if (decode_err) begin
                    $display("[ERROR] Word[%0d]: decode_err asserted", i);
                    err_count++;
                end
                if (disp_err) begin
                    $display("[ERROR] Word[%0d]: disp_err asserted", i);
                    err_count++;
                end

                // TS1 boundary marker
                if ((i % 4) == 3)
                    $display("[INFO]  TS1[%0d] ordered set decode complete", i / 4);
            end
        end
    join

    // Let simulation run for waveform observation
    repeat (20) @(posedge pclk);

    $display("[INFO] === ts1_rx_decode_test end ===");
endtask

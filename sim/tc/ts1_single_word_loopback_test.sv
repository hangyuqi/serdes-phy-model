task ts1_single_word_loopback_test();
    // Gen1 TS1 Ordered Set: 16 symbols, sent as 4 x 32-bit words.
    // Non-COM / non-TS1_ID fields (Link#, Lane#, N_FTS, Rate, Ctrl)
    // are all replaced with PAD (K23.7).
    localparam logic [7:0] COM    = 8'hBC;  // K28.5
    localparam logic [7:0] PAD    = 8'hF7;  // K23.7
    localparam logic [7:0] TS1_ID = 8'h4A;  // D10.2

    // Word 0: COM + 3x PAD          (all K)
    localparam logic [31:0] TS1_W0 = {PAD,    PAD,    PAD,    COM};
    localparam logic [3:0]  TS1_K0 = 4'b1111;
    // Word 1: 2x PAD + 2x TS1_ID    (2K + 2D)
    localparam logic [31:0] TS1_W1 = {TS1_ID, TS1_ID, PAD,    PAD};
    localparam logic [3:0]  TS1_K1 = 4'b0011;
    // Word 2: 4x TS1_ID             (all D)
    localparam logic [31:0] TS1_W2 = {TS1_ID, TS1_ID, TS1_ID, TS1_ID};
    localparam logic [3:0]  TS1_K2 = 4'b0000;
    // Word 3: 4x TS1_ID             (all D)
    localparam logic [31:0] TS1_W3 = {TS1_ID, TS1_ID, TS1_ID, TS1_ID};
    localparam logic [3:0]  TS1_K3 = 4'b0000;

    // ------------------------------------------------------------
    // User-configurable parameters (also overridable via plusargs:
    //   +num_ts1=30  +link_delay=13)
    // ------------------------------------------------------------
    int num_ts1;
    int link_delay_cycles;
    int total_words;

    // TS1 is a 4-word repeating pattern
    logic [31:0] ts1_word [0:3];
    logic [3:0]  ts1_k    [0:3];

    // --- All declarations above, executable statements below ---

    if (!$value$plusargs("num_ts1=%d", num_ts1))
        num_ts1 = 20;
    if (!$value$plusargs("link_delay=%d", link_delay_cycles))
        link_delay_cycles = 7;

    ts1_word[0] = TS1_W0;  ts1_k[0] = TS1_K0;
    ts1_word[1] = TS1_W1;  ts1_k[1] = TS1_K1;
    ts1_word[2] = TS1_W2;  ts1_k[2] = TS1_K2;
    ts1_word[3] = TS1_W3;  ts1_k[3] = TS1_K3;

    total_words = num_ts1 * 4;

    // Configure physical link delay (1 serial_clk cycle = 400ps)
    link_delay = link_delay_cycles * 400ps;

    $display("[INFO] === ts1_single_word_loopback_test start ===");
    $display("[INFO] Sending %0d TS1 ordered sets (%0d words), link delay = %0d serial_clk cycles",
             num_ts1, total_words, link_delay_cycles);

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
    // Phase 2: Drive TS1 and check RX with byte-alignment
    // ----------------------------------------------------------
    fork
        // --- Driver: feed TS1 words continuously ---
        begin
            for (int i = 0; i < total_words; i++) begin
                @(posedge pclk);
                #`PCS_PD;
                txdata   = ts1_word[i % 4];
                txdatak  = ts1_k[i % 4];
                tx_valid = 1'b1;
            end
            @(posedge pclk);
            #`PCS_PD;
            tx_valid = 1'b0;
        end

        // --- Checker: wait for alignment, sync to COM, verify ---
        begin
            int phase;
            int words_checked;
            int words_to_check;
            int wait_cnt;

            // 1) Wait for rx_valid (byte alignment achieved + pipeline filled)
            wait_cnt = 0;
            while (!rx_valid) begin
                @(posedge pclk);
                #1;
                wait_cnt++;
                if (wait_cnt > 100) begin
                    $display("[ERROR] Timed out waiting for rx_valid after %0d pclk cycles", wait_cnt);
                    err_count++;
                    disable fork;
                end
            end
            $display("[INFO] rx_valid asserted after %0d pclk cycles", wait_cnt);

            // 2) Synchronize: find COM word (TS1 word 0) to determine phase
            wait_cnt = 0;
            while (!(rxdata === ts1_word[0] && rxdatak === ts1_k[0])) begin
                @(posedge pclk);
                #1;
                wait_cnt++;
                if (wait_cnt > total_words) begin
                    $display("[ERROR] COM word not found in received stream");
                    err_count++;
                    disable fork;
                end
            end
            $display("[INFO] COM word detected after %0d extra cycles — byte alignment verified", wait_cnt);

            // 3) Verify received TS1 pattern (leave 4-TS1 margin for pipeline drain)
            words_to_check = (num_ts1 - 4) * 4;
            if (words_to_check < 4) words_to_check = 4;

            phase = 0;
            words_checked = 0;

            while (words_checked < words_to_check && rx_valid) begin
                if (rxdata !== ts1_word[phase]) begin
                    $display("[ERROR] Word[%0d]: rxdata mismatch — exp=0x%08h got=0x%08h",
                             words_checked, ts1_word[phase], rxdata);
                    err_count++;
                end else begin
                    $display("[INFO]  Word[%0d]: rxdata=0x%08h — OK", words_checked, rxdata);
                end

                if (rxdatak !== ts1_k[phase]) begin
                    $display("[ERROR] Word[%0d]: rxdatak mismatch — exp=4'b%04b got=4'b%04b",
                             words_checked, ts1_k[phase], rxdatak);
                    err_count++;
                end

                if (decode_err) begin
                    $display("[ERROR] Word[%0d]: decode_err asserted", words_checked);
                    err_count++;
                end
                if (disp_err) begin
                    $display("[ERROR] Word[%0d]: disp_err asserted", words_checked);
                    err_count++;
                end

                if (phase == 3)
                    $display("[INFO]  TS1[%0d] loopback complete", words_checked / 4);

                phase = (phase + 1) % 4;
                words_checked++;

                @(posedge pclk);
                #1;
            end

            $display("[INFO] Verified %0d words (%0d complete TS1 sets)", words_checked, words_checked / 4);
            if (words_checked == 0) begin
                $display("[ERROR] No valid words verified after alignment");
                err_count++;
            end
        end
    join

    repeat (10) @(posedge pclk);

    $display("[INFO] === ts1_single_word_loopback_test end ===");
endtask

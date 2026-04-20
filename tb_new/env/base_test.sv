class base_test;
    virtual phy_if vif;
    phy_checker    checker_inst;
    
    function new(virtual phy_if vif);
        this.vif = vif;
        checker_inst = new();
    endfunction

    virtual task run();
        $display("[%0t] [TEST] Starting Test...", $time);
        reset_phase();
        wait_ready_phase();
        main_phase();
        checker_inst.report();
    endtask

    virtual task reset_phase();
        $display("[%0t] [TEST] Entering Reset Phase...", $time);
        vif.tx_valid <= 0;
        vif.txdata   <= 0;
        vif.txdatak  <= 0;
        vif.rate     <= 0;
        
        vif.rst_n <= 1;
        #10ns; 
        vif.rst_n <= 0; 
        #100ns;
        vif.rst_n <= 1; 
        $display("[%0t] [TEST] Reset Phase completed.", $time);
    endtask

    virtual task wait_ready_phase();
        $display("[%0t] [TEST] Waiting for PHY PLL/CDR lock and ready...", $time);
        repeat(500) @(vif.cb); 
        $display("[%0t] [TEST] PHY is ready for stimulus.", $time);
    endtask

    virtual task main_phase();
        fork
            gen_stimulus();
            monitor_rx();
        join_any 
        repeat(100) @(vif.cb); 
    endtask

    virtual task gen_stimulus();
        $display("[%0t] [TEST] Default gen_stimulus (Empty).", $time);
    endtask

    virtual task monitor_rx();
        phy_trans exp_tr;
        forever begin
            @(vif.cb);
            if(vif.cb.rx_valid) begin
                if(checker_inst.exp_queue.size() > 0) begin
                    exp_tr = checker_inst.exp_queue.pop_front();
                    if(vif.cb.rxdata !== exp_tr.data || vif.cb.rxdatak !== exp_tr.datak) begin
                        $error("[%0t] Data Mismatch! EXP DATA:%h K:%h | ACT DATA:%h K:%h", 
                               $time, exp_tr.data, exp_tr.datak, vif.cb.rxdata, vif.cb.rxdatak);
                        checker_inst.err_cnt++;
                    end else begin
                        checker_inst.match_cnt++;
                    end
                end else begin
                    $error("[%0t] Unexpected RX data received!", $time);
                    checker_inst.err_cnt++;
                end

                if(vif.cb.decode_err || vif.cb.disp_err) begin
                    $error("[%0t] PHY 8b/10b Decode or Disparity Error detected!", $time);
                    checker_inst.err_cnt++;
                end
            end
        end
    endtask
endclass
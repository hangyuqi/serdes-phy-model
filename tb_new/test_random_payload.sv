class test_random_payload extends base_test;
    
    function new(virtual phy_if vif);
        super.new(vif);
    endfunction

    virtual task gen_stimulus();
        phy_trans tr = new();
        $display("[%0t] [TEST] Starting random payload stimulus...", $time);
        
        repeat(100) begin
            assert(tr.randomize());
            @(vif.cb);
            vif.cb.tx_valid <= 1;
            vif.cb.txdata   <= tr.data;
            vif.cb.txdatak  <= tr.datak;
            
            // 复制对象以避免引用覆盖
            begin
                phy_trans exp_tr = new();
                exp_tr.data  = tr.data;
                exp_tr.datak = tr.datak;
                checker_inst.exp_queue.push_back(exp_tr);
            end
        end
        
        @(vif.cb);
        vif.cb.tx_valid <= 0; 
    endtask
endclass
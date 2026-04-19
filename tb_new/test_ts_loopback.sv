class test_ts_loopback extends base_test;
    
    function new(virtual phy_if vif);
        super.new(vif);
    endfunction

    virtual task gen_stimulus();
        pcie_ts_pkt ts_pkt;
        phy_trans   beat_q[$];
        
        $display("[%0t] [TEST] Sending 1024 consecutive TS1 Ordered Sets...", $time);
        
        repeat(1024) begin
            ts_pkt = new();
            assert(ts_pkt.randomize() with { ts_type == pcie_ts_pkt::TS1; }); 
            ts_pkt.pack_to_phy_trans(beat_q);
            
            while(beat_q.size() > 0) begin
                phy_trans tr = beat_q.pop_front();
                @(vif.cb);
                vif.cb.tx_valid <= 1;
                vif.cb.txdata   <= tr.data;
                vif.cb.txdatak  <= tr.datak;
                
                checker_inst.exp_queue.push_back(tr);
            end
        end
        
        @(vif.cb);
        vif.cb.tx_valid <= 0;
    endtask
endclass
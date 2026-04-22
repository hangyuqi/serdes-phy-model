class pcie_ts_pkt;
    typedef enum bit {TS1=0, TS2=1} ts_type_e;
    rand ts_type_e ts_type;

    bit [7:0] symbol_0; 
    rand bit [7:0] link_num;   
    rand bit [7:0] lane_num;   
    rand bit [7:0] n_fts;      
    rand bit [7:0] rate_id;    
    rand bit [7:0] trn_ctrl;   

    function new();
        symbol_0 = 8'hBC; // K28.5 COM
    endfunction

    constraint default_c {
        link_num == 8'h01; 
        lane_num == 8'h00; 
        n_fts    inside {8'h10, 8'h20, 8'hFF}; 
    }

    function void pack_to_phy_trans(ref phy_trans q[$]);
        phy_trans beat0, beat1, beat2, beat3;
        bit [7:0] ts_id = (ts_type == TS1) ? 8'h4A : 8'h45;
        
        // beat0 = new();
        // beat0.data = {n_fts, lane_num, link_num, symbol_0};
        // beat0.datak = 4'b0001; 

        // beat1 = new();
        // beat1.data = {ts_id, ts_id, trn_ctrl, rate_id};
        // beat1.datak = 4'b0000;

        // beat2 = new();
        // beat2.data = {ts_id, ts_id, ts_id, ts_id};
        // beat2.datak = 4'b0000;

        // beat3 = new();
        // beat3.data = {ts_id, ts_id, ts_id, ts_id};
        // beat3.datak = 4'b0000;

        beat0 = new();
        beat0.data = {symbol_0, link_num, lane_num, n_fts};
        beat0.datak = 4'b1000; 

        beat1 = new();
        beat1.data = {rate_id, trn_ctrl, ts_id, ts_id};
        beat1.datak = 4'b0000;

        beat2 = new();
        beat2.data = {ts_id, ts_id, ts_id, ts_id};
        beat2.datak = 4'b0000;

        beat3 = new();
        beat3.data = {ts_id, ts_id, ts_id, ts_id};
        beat3.datak = 4'b0000;

        q.push_back(beat0);
        q.push_back(beat1);
        q.push_back(beat2);
        q.push_back(beat3);
    endfunction
endclass
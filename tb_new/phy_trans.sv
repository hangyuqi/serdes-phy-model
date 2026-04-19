class phy_trans;
    rand bit [31:0] data;
    rand bit [3:0]  datak;
    
    constraint k_char_c {
        datak inside {4'h0, 4'h1, 4'h3, 4'hF}; 
    }
endclass
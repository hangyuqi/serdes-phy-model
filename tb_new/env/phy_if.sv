interface phy_if(input logic pclk);
    logic        rst_n;  // 由 Test 驱动
    logic        rate;
    
    // Tx Parallel
    logic [31:0] txdata;
    logic [3:0]  txdatak;
    logic        tx_valid;
    
    // Rx Parallel
    logic [31:0] rxdata;
    logic [3:0]  rxdatak;
    logic        rx_valid;
    
    // Error indicators
    logic        decode_err;
    logic        disp_err;
    
    clocking cb @(posedge pclk);
        default input #1ns output #1ns;
        output txdata, txdatak, tx_valid, rate;
        input  rxdata, rxdatak, rx_valid, decode_err, disp_err;
    endclocking
endinterface
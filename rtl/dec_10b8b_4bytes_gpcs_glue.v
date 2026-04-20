`include "rtl_timescale.v" 
module dec_10b8b_4bytes_gpcs_glue
(
  input                             clk40,
  input                             clk40_rst_n,
  input                             rx8b10ben,

  input                [39:0]       din,
  input                             din_vld,
  input                [3:0]        din_comma,
  input                             dout_bit_swp_en,
  input                             dout_bytes_swp_en,
  input                             dec_rx_com_det,

  input         [7:0]               dout_40_u0_wire,
  input                             dout_40_k_u0_wire,
  input                             rx_disp_err_40_u0_wire,
  input                             rx_code_err_40_u0_wire,

  input         [7:0]               dout_40_u1_wire,
  input                             dout_40_k_u1_wire,
  input                             rx_disp_err_40_u1_wire,
  input                             rx_code_err_40_u1_wire,

  input         [7:0]               dout_40_u2_wire,
  input                             dout_40_k_u2_wire,
  input                             rx_disp_err_40_u2_wire,
  input                             rx_code_err_40_u2_wire,

  input         [7:0]               dout_40_u3_wire,
  input                             dout_40_k_u3_wire,
  input                             rx_disp_err_40_u3_wire,
  input                             rx_code_err_40_u3_wire, 

  input                             disparity_out_40_u3,
  output        reg                 disparity_out_40_u3_dly,

  output        reg                 dout_vld, 
  output        reg    [31:0]       dout,
  output        reg    [3:0]        dout_k,
  output        reg    [3:0]        dout_comma,
  output        reg    [3:0]        rx_disp_err,
  output        reg    [3:0]        rx_code_err
);

  wire          [31:0]              dout_mx;
  wire          [3:0]               dout_k_mx;
  wire          [3:0]               rx_disp_err_mx;
  wire          [3:0]               rx_code_err_mx;
  wire          [3:0]               dout_comma_mx ;
  wire          [7:0]               dout_8b_1st_swp;
  wire          [7:0]               dout_8b_2nd_swp;
  wire          [7:0]               dout_8b_3rd_swp;
  wire          [7:0]               dout_8b_4th_swp;
  reg                               disp_set;
  wire	                            rx0_code_err, rx1_code_err, rx2_code_err, rx3_code_err;
  wire	                            rx0_disp_err, rx1_disp_err, rx2_disp_err, rx3_disp_err;
  wire                              disp_mismatch;
  wire          [3:0]               dec_err_in;
  wire          [3:0]               disp_err_in;
  wire          [7:0]               qual_rx0_data_8b10b;
  wire          [7:0]               qual_rx1_data_8b10b;
  wire          [7:0]               qual_rx2_data_8b10b;
  wire          [7:0]               qual_rx3_data_8b10b;
  wire                              qual_rx0_datak_8b10b;
  wire                              qual_rx1_datak_8b10b;
  wire                              qual_rx2_datak_8b10b;
  wire                              qual_rx3_datak_8b10b;

// GPCS GLUE
//Swap the bits - 8-bits in, 8-bits out
function automatic [7:0] bitswap_8b_data_out;
 input [7:0] bitswap_8b_data_in;
 integer i;
 begin
  for (i=0; i<8; i=i+1)
      bitswap_8b_data_out[i] = bitswap_8b_data_in[(7-i)];
 end
endfunction

assign dout_8b_1st_swp[7:0] = dout_bit_swp_en ? bitswap_8b_data_out(qual_rx0_data_8b10b) : qual_rx0_data_8b10b;
assign dout_8b_2nd_swp[7:0] = dout_bit_swp_en ? bitswap_8b_data_out(qual_rx1_data_8b10b) : qual_rx1_data_8b10b;
assign dout_8b_3rd_swp[7:0] = dout_bit_swp_en ? bitswap_8b_data_out(qual_rx2_data_8b10b) : qual_rx2_data_8b10b;
assign dout_8b_4th_swp[7:0] = dout_bit_swp_en ? bitswap_8b_data_out(qual_rx3_data_8b10b) : qual_rx3_data_8b10b;

assign dout_mx        = dout_bytes_swp_en ? {dout_8b_1st_swp, dout_8b_2nd_swp, dout_8b_3rd_swp, dout_8b_4th_swp}
                                          : {dout_8b_4th_swp, dout_8b_3rd_swp, dout_8b_2nd_swp, dout_8b_1st_swp};
assign dout_k_mx      = dout_bytes_swp_en ? {qual_rx0_datak_8b10b, qual_rx1_datak_8b10b, qual_rx2_datak_8b10b, qual_rx3_datak_8b10b}
                                          : {qual_rx3_datak_8b10b, qual_rx2_datak_8b10b, qual_rx1_datak_8b10b, qual_rx0_datak_8b10b};
assign rx_disp_err_mx = dout_bytes_swp_en ? {disp_err_in[0], disp_err_in[1], disp_err_in[2], disp_err_in[3]}
                                          : disp_err_in[3:0];
assign rx_code_err_mx = dout_bytes_swp_en ? {dec_err_in[0], dec_err_in[1], dec_err_in[2], dec_err_in[3]}
                                          : dec_err_in[3:0];
assign dout_comma_mx  = dout_bytes_swp_en ? {din_comma[0],din_comma[1],din_comma[2],din_comma[3]} : din_comma[3:0] ;

assign rx0_disp_err = rx_disp_err_40_u0_wire ;
assign rx0_code_err = rx_code_err_40_u0_wire ;

assign rx1_disp_err = rx_disp_err_40_u1_wire ;
assign rx1_code_err = rx_code_err_40_u1_wire ;

assign rx2_disp_err = rx_disp_err_40_u2_wire ;
assign rx2_code_err = rx_code_err_40_u2_wire ;

assign rx3_disp_err = rx_disp_err_40_u3_wire ;
assign rx3_code_err = rx_code_err_40_u3_wire ;

always @(posedge clk40 or negedge clk40_rst_n)
begin
  if(~clk40_rst_n) begin
    dout        <= #`PCS_PD  32'd0;
    dout_k      <= #`PCS_PD  4'd0;
    dout_comma  <= #`PCS_PD  4'd0;
    dout_vld    <= #`PCS_PD  1'b0;
    rx_code_err <= #`PCS_PD  4'd0;
    rx_disp_err <= #`PCS_PD  4'd0;
  end else begin
    dout        <= #`PCS_PD  dout_mx;
    dout_k      <= #`PCS_PD  dout_k_mx;
    dout_comma  <= #`PCS_PD  dout_comma_mx;
    dout_vld    <= #`PCS_PD  din_vld;
    rx_code_err <= #`PCS_PD  rx_code_err_mx;
    rx_disp_err <= #`PCS_PD  rx_disp_err_mx;
  end
end

assign disp_mismatch = rx0_disp_err | rx1_disp_err | rx2_disp_err | rx3_disp_err; 
  
always @(posedge clk40 or negedge clk40_rst_n) begin
if (~clk40_rst_n)
  disp_set <= #`PCS_PD  1'b0;    
else
  disp_set <= #`PCS_PD  din_vld & (disp_set | (dec_rx_com_det && ~(rx0_code_err || rx1_code_err || rx2_code_err || rx3_code_err)) | disp_mismatch);
end

assign qual_rx0_data_8b10b = dout_40_u0_wire;
assign qual_rx1_data_8b10b = dout_40_u1_wire;
assign qual_rx2_data_8b10b = dout_40_u2_wire;
assign qual_rx3_data_8b10b = dout_40_u3_wire;

assign qual_rx0_datak_8b10b = !rx8b10ben ? 1'b0 : (dout_40_k_u0_wire);
assign qual_rx1_datak_8b10b = !rx8b10ben ? 1'b0 : (dout_40_k_u1_wire);
assign qual_rx2_datak_8b10b = !rx8b10ben ? 1'b0 : (dout_40_k_u2_wire);
assign qual_rx3_datak_8b10b = !rx8b10ben ? 1'b0 : (dout_40_k_u3_wire);

assign dec_err_in  = {(rx8b10ben & rx3_code_err), (rx8b10ben & rx2_code_err),
                      (rx8b10ben & rx1_code_err), (rx8b10ben & rx0_code_err)};
assign disp_err_in = {(rx8b10ben & disp_set & rx3_disp_err), (rx8b10ben & disp_set & rx2_disp_err),
                      (rx8b10ben & disp_set & rx1_disp_err), (rx8b10ben & disp_set & rx0_disp_err)};

//==================================================================================
//40->32bit decoder
//==================================================================================
always @(posedge clk40 or negedge clk40_rst_n)
begin
  if (clk40_rst_n == 1'b0)
    disparity_out_40_u3_dly <= #`PCS_PD  1'b0;
  else if (rx8b10ben)
    disparity_out_40_u3_dly <= #`PCS_PD  (din_vld & disparity_out_40_u3);
end

endmodule

`include "../../RTL/rtl_timescale.v" 
module dec_10b8b_4bytes_pipe_glue
(
  input                             rxusrclk,          
  input                             rxusrclk_pcs_rstn,
  input                             rxusrclk_rx8b10ben,

  input                [39:0]       din,
  input                             din_vld,
  input                             dout_bit_swp_en,
  input                             dout_bytes_swp_en,
  input                             dec_rx_com_det,
  input                             din_freeze,
  input                [7:0]        dec_kcode_edb_reg,
  input                             pcie_idle_sts,
  input                             buf_uflow,
  input                             buf_uflow_pre,
  input                             buf_oflow_pre,

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

  output        reg                 dout_vld_pipe,
  output        reg    [31:0]       dout_pipe,
  output        reg    [3:0]        dout_k_pipe,
  output        reg    [3:0]        rx_disp_err_pipe,
  output        reg    [3:0]        rx_code_err_pipe  

);

  wire          [31:0]              dout_mx;
  wire          [3:0]               dout_k_mx;
  wire          [3:0]               rx_disp_err_mx;
  wire          [3:0]               rx_code_err_mx;

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

assign rx0_disp_err = rx_disp_err_40_u0_wire & ~din_freeze & ~buf_uflow_pre & ~buf_oflow_pre;
assign rx0_code_err = rx_code_err_40_u0_wire & ~din_freeze;

assign rx1_disp_err = rx_disp_err_40_u1_wire & ~din_freeze & ~buf_uflow_pre & ~buf_oflow_pre;
assign rx1_code_err = rx_code_err_40_u1_wire & ~din_freeze;

assign rx2_disp_err = rx_disp_err_40_u2_wire & ~din_freeze & ~buf_uflow_pre & ~buf_oflow_pre;
assign rx2_code_err = rx_code_err_40_u2_wire & ~din_freeze;

assign rx3_disp_err = rx_disp_err_40_u3_wire & ~din_freeze & ~buf_uflow_pre & ~buf_oflow_pre;
assign rx3_code_err = rx_code_err_40_u3_wire & ~din_freeze;

//to maintain the same cycle rx status, 8b10b decoder data dff put outside
always @(*)
begin
  dout_pipe        = dout_mx;
  dout_k_pipe      = dout_k_mx;
  dout_vld_pipe    = din_vld;
  rx_code_err_pipe = rx_code_err_mx;
  rx_disp_err_pipe = rx_disp_err_mx;
end

assign disp_mismatch = rx0_disp_err | rx1_disp_err | rx2_disp_err | rx3_disp_err; 
  
always @(posedge rxusrclk or negedge rxusrclk_pcs_rstn) begin
if (~rxusrclk_pcs_rstn)
  disp_set <= #`PCS_PD  1'b0;    
else
  disp_set <= #`PCS_PD  (din_vld && din_freeze) ? disp_set : din_vld & (disp_set | (dec_rx_com_det && ~(rx0_code_err || rx1_code_err || rx2_code_err || rx3_code_err)) | disp_mismatch);
end

/////////////////////////////////////////////
// Post-Buffer PCIe Gen1/2 EIOS detection
/////////////////////////////////////////////
parameter KCODE_10B_COMMA = 10'h0FA; 
parameter KCODE_10B_IDLE  = 10'h0F3; 

wire [3:0] idl_det_int = (din_vld && din_freeze) ? 4'd0 :
                         {((din[39:30] == KCODE_10B_IDLE) || (din[39:30] == ~KCODE_10B_IDLE)),
                          ((din[29:20] == KCODE_10B_IDLE) || (din[29:20] == ~KCODE_10B_IDLE)),
                          ((din[19:10] == KCODE_10B_IDLE) || (din[19:10] == ~KCODE_10B_IDLE)),
                          ((din[9:0]   == KCODE_10B_IDLE) || (din[9:0]   == ~KCODE_10B_IDLE))};

wire [3:0] com_det_int = (din_vld && din_freeze) ? 4'd0 :
                         {((din[39:30] == KCODE_10B_COMMA) || (din[39:30] == ~KCODE_10B_COMMA)),
                          ((din[29:20] == KCODE_10B_COMMA) || (din[29:20] == ~KCODE_10B_COMMA)),
                          ((din[19:10] == KCODE_10B_COMMA) || (din[19:10] == ~KCODE_10B_COMMA)),
                          ((din[9:0]   == KCODE_10B_COMMA) || (din[9:0]   == ~KCODE_10B_COMMA))};

reg [3:0] com_det_int_s1;
reg [3:0] idl_det_int_s1;

always @(posedge rxusrclk or negedge rxusrclk_pcs_rstn) begin
if (~rxusrclk_pcs_rstn) begin
  com_det_int_s1 <= #`PCS_PD  4'd0;
  idl_det_int_s1 <= #`PCS_PD  4'd0;
end else begin
  com_det_int_s1 <= #`PCS_PD  (din_vld && din_freeze) ? com_det_int_s1 : com_det_int;
  idl_det_int_s1 <= #`PCS_PD  (din_vld && din_freeze) ? idl_det_int_s1 : idl_det_int;
 end
end

wire eios_det_int_a;

assign eios_det_int_a = (com_det_int[3]    & idl_det_int[2]    & idl_det_int[1]    & idl_det_int[0]) ||
                        (com_det_int_s1[0] & idl_det_int[3]    & idl_det_int[2]    & idl_det_int[1]) ||  
                        (com_det_int_s1[1] & idl_det_int_s1[0] & idl_det_int[3]    & idl_det_int[2]) ||  
                        (com_det_int_s1[2] & idl_det_int_s1[1] & idl_det_int_s1[0] & idl_det_int[3]);

reg eios_det_int_s1;
 
always @(posedge rxusrclk or negedge rxusrclk_pcs_rstn) begin
if (~rxusrclk_pcs_rstn)
  eios_det_int_s1 <= #`PCS_PD  1'd0;
else
  eios_det_int_s1 <= #`PCS_PD  eios_det_int_a;
end
 
wire eios_det_int = (eios_det_int_a | eios_det_int_s1);

// Insert EDB (PCIe) or SUB (USB) in place of badly decoded word or whenever the elastic buffer reports
// an underflow. We'll also drive an EDB/SUB on the upper bits when we're in narrow
// mode to make sure nobody uses that data. Finally, we'll drive the entire
// interface to EDB/SUB when the lane isn't in P0.
// uflow is asserted for both rx0 and rx1, therefore, we should replace the
// both output words with EDB/SUB. 
wire drv_edb_rx0_8b10b = (pcie_idle_sts | (rx0_code_err & ~eios_det_int) | buf_uflow);
wire drv_edb_rx1_8b10b = (pcie_idle_sts | (rx1_code_err & ~eios_det_int) | buf_uflow);
wire drv_edb_rx2_8b10b = (pcie_idle_sts | (rx2_code_err & ~eios_det_int) | buf_uflow);
wire drv_edb_rx3_8b10b = (pcie_idle_sts | (rx3_code_err & ~eios_det_int) | buf_uflow);

assign qual_rx0_data_8b10b = drv_edb_rx0_8b10b ? dec_kcode_edb_reg : dout_40_u0_wire;
assign qual_rx1_data_8b10b = drv_edb_rx1_8b10b ? dec_kcode_edb_reg : dout_40_u1_wire;
assign qual_rx2_data_8b10b = drv_edb_rx2_8b10b ? dec_kcode_edb_reg : dout_40_u2_wire;
assign qual_rx3_data_8b10b = drv_edb_rx3_8b10b ? dec_kcode_edb_reg : dout_40_u3_wire;

assign qual_rx0_datak_8b10b = !rxusrclk_rx8b10ben ? 1'b0 : (dout_40_k_u0_wire | drv_edb_rx0_8b10b);
assign qual_rx1_datak_8b10b = !rxusrclk_rx8b10ben ? 1'b0 : (dout_40_k_u1_wire | drv_edb_rx1_8b10b);
assign qual_rx2_datak_8b10b = !rxusrclk_rx8b10ben ? 1'b0 : (dout_40_k_u2_wire | drv_edb_rx2_8b10b);
assign qual_rx3_datak_8b10b = !rxusrclk_rx8b10ben ? 1'b0 : (dout_40_k_u3_wire | drv_edb_rx3_8b10b);

assign dec_err_in  = {(rxusrclk_rx8b10ben & rx3_code_err & ~eios_det_int), (rxusrclk_rx8b10ben & rx2_code_err & ~eios_det_int),
                      (rxusrclk_rx8b10ben & rx1_code_err & ~eios_det_int), (rxusrclk_rx8b10ben & rx0_code_err & ~eios_det_int)};
assign disp_err_in = {(rxusrclk_rx8b10ben & disp_set & rx3_disp_err & ~eios_det_int), (rxusrclk_rx8b10ben & disp_set & rx2_disp_err & ~eios_det_int),
                      (rxusrclk_rx8b10ben & disp_set & rx1_disp_err & ~eios_det_int), (rxusrclk_rx8b10ben & disp_set & rx0_disp_err & ~eios_det_int)};

//==================================================================================
//40->32bit decoder
//==================================================================================
always @(posedge rxusrclk or negedge rxusrclk_pcs_rstn)
begin
  if (rxusrclk_pcs_rstn == 1'b0)
    disparity_out_40_u3_dly <= #`PCS_PD  1'b0;
  else if (rxusrclk_rx8b10ben)
    disparity_out_40_u3_dly <= #`PCS_PD  (din_vld && din_freeze) ? disparity_out_40_u3_dly : (din_vld & disparity_out_40_u3);
end

endmodule

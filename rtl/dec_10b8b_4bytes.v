//-----------------------------------------------------------------------------
// Project       : at0012v1
//-----------------------------------------------------------------------------
// File          : dec_10b8b_4bytes.v
// Author        : chongzhang
// Created       : 2021.03
// Last modified : 2021.03
//-----------------------------------------------------------------------------
// Description :
// at0012v1 10b8b decoder for 4bytes
//-----------------------------------------------------------------------------
// Copyright (c) 2021 by anlogic This model is the confidential and
// proprietary property of anlogic and the possession or use of this
// file requires a written license from anlogic.
//------------------------------------------------------------------------------


`include "rtl_timescale.v" 
module dec_10b8b_4bytes
(
  input                             clk40,
  input                             clk40_rst_n,
  input                             rx8b10ben,

  input                             rxusrclk,          
  input                             rxusrclk_pcs_rstn,
  input                             rxusrclk_rx8b10ben,

  input                [39:0]       din,
  input                             din_vld,
  input                [3:0]        din_comma,
  input                             dout_bit_swp_en,
  input                             dout_bytes_swp_en,

  input                             pipe_prot_en,
  input                             dec_rx_com_det,
  input                             din_freeze,
  input                [7:0]        dec_kcode_edb_reg,
  input                             pcie_idle_sts,
  input                             buf_uflow,
  input                             buf_uflow_pre,
  input                             buf_oflow_pre,

  output        reg                 dout_vld_pipe,
  output        reg    [31:0]       dout_pipe,
  output        reg    [3:0]        dout_k_pipe,
  output        reg    [3:0]        rx_disp_err_pipe,
  output        reg    [3:0]        rx_code_err_pipe,

  output        reg                 dout_vld, 
  output        reg    [31:0]       dout,
  output        reg    [3:0]        dout_k,
  output        reg    [3:0]        dout_comma,
  output        reg    [3:0]        rx_disp_err,
  output        reg    [3:0]        rx_code_err
);

//  wire          [31:0]              dout_mx;
//  wire          [3:0]               dout_k_mx;
//  wire          [3:0]               rx_disp_err_mx;
//  wire          [3:0]               rx_code_err_mx;
//  wire          [3:0]               dout_comma_mx ;

  //wire                              disparity_in_40_u0;
  wire                              disparity_out_40_u0;
  wire          [7:0]               dout_40_u0_wire;
  wire                              dout_40_k_u0_wire;
  wire                              rx_disp_err_40_u0_wire;
  wire                              rx_code_err_40_u0_wire;

  //wire                              disparity_in_40_u1;
  wire                              disparity_out_40_u1;
  wire          [7:0]               dout_40_u1_wire;
  wire                              dout_40_k_u1_wire;
  wire                              rx_disp_err_40_u1_wire;
  wire                              rx_code_err_40_u1_wire;

  //wire                              disparity_in_40_u2;
  wire                              disparity_out_40_u2;
  wire          [7:0]               dout_40_u2_wire;
  wire                              dout_40_k_u2_wire;
  wire                              rx_disp_err_40_u2_wire;
  wire                              rx_code_err_40_u2_wire;

  //wire                              disparity_in_40_u3;
  wire                              disparity_out_40_u3;
  wire          [7:0]               dout_40_u3_wire;
  wire                              dout_40_k_u3_wire;
  wire                              rx_disp_err_40_u3_wire;
  wire                              rx_code_err_40_u3_wire;

//  wire          [7:0]               dout_8b_1st_swp;
//  wire          [7:0]               dout_8b_2nd_swp;
//  wire          [7:0]               dout_8b_3rd_swp;
//  wire          [7:0]               dout_8b_4th_swp;

  //reg           [7:0]               dout_40_u0_r;
  //reg           [7:0]               dout_40_u1_r;
  //reg           [7:0]               dout_40_u2_r;
  //reg           [7:0]               dout_40_u3_r;

//  reg                               disparity_out_40_u3_dly;
  wire                               disparity_out_40_u3_dly_mx;
  wire                               disparity_out_40_u3_dly_pipe;
  wire                               disparity_out_40_u3_dly_gpcs;
  //reg           [3:0]               dout_40_k;
  //reg           [3:0]               rx_disp_err_40;
  //reg           [3:0]               rx_code_err_40;
//  reg                               disp_set;

//  wire	                            rx0_code_err, rx1_code_err, rx2_code_err, rx3_code_err;
//  wire	                            rx0_disp_err, rx1_disp_err, rx2_disp_err, rx3_disp_err;
//  wire                              disp_mismatch;
//  wire          [3:0]               dec_err_in;
//  wire          [3:0]               disp_err_in;
//  wire          [7:0]               qual_rx0_data_8b10b;
//  wire          [7:0]               qual_rx1_data_8b10b;
//  wire          [7:0]               qual_rx2_data_8b10b;
//  wire          [7:0]               qual_rx3_data_8b10b;
//  wire                              qual_rx0_datak_8b10b;
//  wire                              qual_rx1_datak_8b10b;
//  wire                              qual_rx2_datak_8b10b;
//  wire                              qual_rx3_datak_8b10b;

////Swap the bits - 8-bits in, 8-bits out
//function automatic [7:0] bitswap_8b_data_out;
// input [7:0] bitswap_8b_data_in;
// integer i;
// begin
//  for (i=0; i<8; i=i+1)
//      bitswap_8b_data_out[i] = bitswap_8b_data_in[(7-i)];
// end
//endfunction
//
//assign dout_8b_1st_swp[7:0] = dout_bit_swp_en ? bitswap_8b_data_out(qual_rx0_data_8b10b) : qual_rx0_data_8b10b;
//assign dout_8b_2nd_swp[7:0] = dout_bit_swp_en ? bitswap_8b_data_out(qual_rx1_data_8b10b) : qual_rx1_data_8b10b;
//assign dout_8b_3rd_swp[7:0] = dout_bit_swp_en ? bitswap_8b_data_out(qual_rx2_data_8b10b) : qual_rx2_data_8b10b;
//assign dout_8b_4th_swp[7:0] = dout_bit_swp_en ? bitswap_8b_data_out(qual_rx3_data_8b10b) : qual_rx3_data_8b10b;
//
//assign dout_mx        = dout_bytes_swp_en ? {dout_8b_1st_swp, dout_8b_2nd_swp, dout_8b_3rd_swp, dout_8b_4th_swp}
//                                          : {dout_8b_4th_swp, dout_8b_3rd_swp, dout_8b_2nd_swp, dout_8b_1st_swp};
//assign dout_k_mx      = dout_bytes_swp_en ? {qual_rx0_datak_8b10b, qual_rx1_datak_8b10b, qual_rx2_datak_8b10b, qual_rx3_datak_8b10b}
//                                          : {qual_rx3_datak_8b10b, qual_rx2_datak_8b10b, qual_rx1_datak_8b10b, qual_rx0_datak_8b10b};
//assign rx_disp_err_mx = dout_bytes_swp_en ? {disp_err_in[0], disp_err_in[1], disp_err_in[2], disp_err_in[3]}
//                                          : disp_err_in[3:0];
//assign rx_code_err_mx = dout_bytes_swp_en ? {dec_err_in[0], dec_err_in[1], dec_err_in[2], dec_err_in[3]}
//                                          : dec_err_in[3:0];
//assign dout_comma_mx  = dout_bytes_swp_en ? {din_comma[0],din_comma[1],din_comma[2],din_comma[3]} : din_comma[3:0] ;
//
//assign rx0_disp_err = rx_disp_err_40_u0_wire & ~din_freeze & ~buf_uflow_pre & ~buf_oflow_pre;
//assign rx0_code_err = rx_code_err_40_u0_wire & ~din_freeze;
//
//assign rx1_disp_err = rx_disp_err_40_u1_wire & ~din_freeze & ~buf_uflow_pre & ~buf_oflow_pre;
//assign rx1_code_err = rx_code_err_40_u1_wire & ~din_freeze;
//
//assign rx2_disp_err = rx_disp_err_40_u2_wire & ~din_freeze & ~buf_uflow_pre & ~buf_oflow_pre;
//assign rx2_code_err = rx_code_err_40_u2_wire & ~din_freeze;
//
//assign rx3_disp_err = rx_disp_err_40_u3_wire & ~din_freeze & ~buf_uflow_pre & ~buf_oflow_pre;
//assign rx3_code_err = rx_code_err_40_u3_wire & ~din_freeze;
//
//always @(posedge clk40 or negedge clk40_rst_n)
//begin
//  if(~clk40_rst_n) begin
//    dout        <= #`PCS_PD  32'd0;
//    dout_k      <= #`PCS_PD  4'd0;
//    dout_comma  <= #`PCS_PD  4'd0;
//    dout_vld    <= #`PCS_PD  1'b0;
//    rx_code_err <= #`PCS_PD  4'd0;
//    rx_disp_err <= #`PCS_PD  4'd0;
//  end else begin
//    dout        <= #`PCS_PD  dout_mx;
//    dout_k      <= #`PCS_PD  dout_k_mx;
//    dout_comma  <= #`PCS_PD  dout_comma_mx;
//    dout_vld    <= #`PCS_PD  din_vld;
//    rx_code_err <= #`PCS_PD  rx_code_err_mx;
//    rx_disp_err <= #`PCS_PD  rx_disp_err_mx;
//  end
//end
//
////to maintain the same cycle rx status, 8b10b decoder data dff put outside
//always @(*)
//begin
//  dout_pipe        = dout_mx;
//  dout_k_pipe      = dout_k_mx;
//  dout_vld_pipe    = din_vld;
//  rx_code_err_pipe = rx_code_err_mx;
//  rx_disp_err_pipe = rx_disp_err_mx;
//end
//
//assign disp_mismatch = rx0_disp_err | rx1_disp_err | rx2_disp_err | rx3_disp_err; 
//  
//always @(posedge clk40 or negedge clk40_rst_n) begin
//if (~clk40_rst_n)
//  disp_set <= #`PCS_PD  1'b0;    
//else
//  disp_set <= #`PCS_PD  (din_vld && din_freeze) ? disp_set : din_vld & (disp_set | (dec_rx_com_det && ~(rx0_code_err || rx1_code_err || rx2_code_err || rx3_code_err)) | disp_mismatch);
//end
//
//
//
///////////////////////////////////////////////
//// Post-Buffer PCIe Gen1/2 EIOS detection
///////////////////////////////////////////////
//parameter KCODE_10B_COMMA = 10'h0FA; 
//parameter KCODE_10B_IDLE  = 10'h0F3; 
//
//wire [3:0] idl_det_int = (din_vld && din_freeze) ? 4'd0 :
//                         {((din[39:30] == KCODE_10B_IDLE) || (din[39:30] == ~KCODE_10B_IDLE)),
//                          ((din[29:20] == KCODE_10B_IDLE) || (din[29:20] == ~KCODE_10B_IDLE)),
//                          ((din[19:10] == KCODE_10B_IDLE) || (din[19:10] == ~KCODE_10B_IDLE)),
//                          ((din[9:0]   == KCODE_10B_IDLE) || (din[9:0]   == ~KCODE_10B_IDLE))};
//
//wire [3:0] com_det_int = (din_vld && din_freeze) ? 4'd0 :
//                         {((din[39:30] == KCODE_10B_COMMA) || (din[39:30] == ~KCODE_10B_COMMA)),
//                          ((din[29:20] == KCODE_10B_COMMA) || (din[29:20] == ~KCODE_10B_COMMA)),
//                          ((din[19:10] == KCODE_10B_COMMA) || (din[19:10] == ~KCODE_10B_COMMA)),
//                          ((din[9:0]   == KCODE_10B_COMMA) || (din[9:0]   == ~KCODE_10B_COMMA))};
//
//reg [3:0] com_det_int_s1;
//reg [3:0] idl_det_int_s1;
//
//always @(posedge clk40 or negedge clk40_rst_n) begin
//if (~clk40_rst_n) begin
//  com_det_int_s1 <= #`PCS_PD  4'd0;
//  idl_det_int_s1 <= #`PCS_PD  4'd0;
//end else begin
//  com_det_int_s1 <= #`PCS_PD  (din_vld && din_freeze) ? com_det_int_s1 : com_det_int;
//  idl_det_int_s1 <= #`PCS_PD  (din_vld && din_freeze) ? idl_det_int_s1 : idl_det_int;
// end
//end
//
//wire eios_det_int_a;
//
//assign eios_det_int_a = (com_det_int[3]    & idl_det_int[2]    & idl_det_int[1]    & idl_det_int[0]) ||
//                        (com_det_int_s1[0] & idl_det_int[3]    & idl_det_int[2]    & idl_det_int[1]) ||  
//                        (com_det_int_s1[1] & idl_det_int_s1[0] & idl_det_int[3]    & idl_det_int[2]) ||  
//                        (com_det_int_s1[2] & idl_det_int_s1[1] & idl_det_int_s1[0] & idl_det_int[3]);
//
//reg eios_det_int_s1;
// 
//always @(posedge clk40 or negedge clk40_rst_n) begin
//if (~clk40_rst_n)
//  eios_det_int_s1 <= #`PCS_PD  1'd0;
//else
//  eios_det_int_s1 <= #`PCS_PD  eios_det_int_a;
//end
// 
//wire eios_det_int = (eios_det_int_a | eios_det_int_s1) && pipe_prot_en;
//
//// Insert EDB (PCIe) or SUB (USB) in place of badly decoded word or whenever the elastic buffer reports
//// an underflow. We'll also drive an EDB/SUB on the upper bits when we're in narrow
//// mode to make sure nobody uses that data. Finally, we'll drive the entire
//// interface to EDB/SUB when the lane isn't in P0.
//// uflow is asserted for both rx0 and rx1, therefore, we should replace the
//// both output words with EDB/SUB. 
//wire drv_edb_rx0_8b10b = pipe_prot_en ? (pcie_idle_sts | (rx0_code_err & ~eios_det_int) | buf_uflow) : 1'b0;
//wire drv_edb_rx1_8b10b = pipe_prot_en ? (pcie_idle_sts | (rx1_code_err & ~eios_det_int) | buf_uflow) : 1'b0;
//wire drv_edb_rx2_8b10b = pipe_prot_en ? (pcie_idle_sts | (rx2_code_err & ~eios_det_int) | buf_uflow) : 1'b0;
//wire drv_edb_rx3_8b10b = pipe_prot_en ? (pcie_idle_sts | (rx3_code_err & ~eios_det_int) | buf_uflow) : 1'b0;
//
//assign qual_rx0_data_8b10b = drv_edb_rx0_8b10b ? dec_kcode_edb_reg : dout_40_u0_wire;
//assign qual_rx1_data_8b10b = drv_edb_rx1_8b10b ? dec_kcode_edb_reg : dout_40_u1_wire;
//assign qual_rx2_data_8b10b = drv_edb_rx2_8b10b ? dec_kcode_edb_reg : dout_40_u2_wire;
//assign qual_rx3_data_8b10b = drv_edb_rx3_8b10b ? dec_kcode_edb_reg : dout_40_u3_wire;
//
//assign qual_rx0_datak_8b10b = !rx8b10ben ? 1'b0 : (dout_40_k_u0_wire | drv_edb_rx0_8b10b);
//assign qual_rx1_datak_8b10b = !rx8b10ben ? 1'b0 : (dout_40_k_u1_wire | drv_edb_rx1_8b10b);
//assign qual_rx2_datak_8b10b = !rx8b10ben ? 1'b0 : (dout_40_k_u2_wire | drv_edb_rx2_8b10b);
//assign qual_rx3_datak_8b10b = !rx8b10ben ? 1'b0 : (dout_40_k_u3_wire | drv_edb_rx3_8b10b);
//
//assign dec_err_in  = {(rx8b10ben & rx3_code_err & ~eios_det_int), (rx8b10ben & rx2_code_err & ~eios_det_int),
//                      (rx8b10ben & rx1_code_err & ~eios_det_int), (rx8b10ben & rx0_code_err & ~eios_det_int)};
//assign disp_err_in = {(rx8b10ben & disp_set & rx3_disp_err & ~eios_det_int), (rx8b10ben & disp_set & rx2_disp_err & ~eios_det_int),
//                      (rx8b10ben & disp_set & rx1_disp_err & ~eios_det_int), (rx8b10ben & disp_set & rx0_disp_err & ~eios_det_int)};
//
////==================================================================================
////40->32bit decoder
////==================================================================================
//always @(posedge clk40 or negedge clk40_rst_n)
//begin
//  if (clk40_rst_n == 1'b0)
//    disparity_out_40_u3_dly <= #`PCS_PD  1'b0;
//  else if (rx8b10ben)
//    disparity_out_40_u3_dly <= #`PCS_PD  (din_vld && din_freeze) ? disparity_out_40_u3_dly : (din_vld & disparity_out_40_u3);
//end

// PIPE GLUE
 dec_10b8b_4bytes_pipe_glue u4_dec_10b8b_4bytes_pipe_glue
(
  .rxusrclk                                (rxusrclk),          
  .rxusrclk_pcs_rstn                       (rxusrclk_pcs_rstn),
  .rxusrclk_rx8b10ben                      (rxusrclk_rx8b10ben),
  .din                                     (din),
  .din_vld                                 (din_vld),
  .dout_bit_swp_en                         (dout_bit_swp_en),
  .dout_bytes_swp_en                       (dout_bytes_swp_en),  
  .dec_rx_com_det                          (dec_rx_com_det),
  .din_freeze                              (din_freeze),
  .dec_kcode_edb_reg                       (dec_kcode_edb_reg),
  .pcie_idle_sts                           (pcie_idle_sts),
  .buf_uflow                               (buf_uflow),
  .buf_uflow_pre                           (buf_uflow_pre),
  .buf_oflow_pre                           (buf_oflow_pre),

  .dout_40_u0_wire                         (dout_40_u0_wire),
  .dout_40_k_u0_wire                       (dout_40_k_u0_wire),
  .rx_disp_err_40_u0_wire                  (rx_disp_err_40_u0_wire),
  .rx_code_err_40_u0_wire                  (rx_code_err_40_u0_wire),

  .dout_40_u1_wire                         (dout_40_u1_wire),
  .dout_40_k_u1_wire                       (dout_40_k_u1_wire),
  .rx_disp_err_40_u1_wire                  (rx_disp_err_40_u1_wire),
  .rx_code_err_40_u1_wire                  (rx_code_err_40_u1_wire),

  .dout_40_u2_wire                         (dout_40_u2_wire),
  .dout_40_k_u2_wire                       (dout_40_k_u2_wire),
  .rx_disp_err_40_u2_wire                  (rx_disp_err_40_u2_wire),
  .rx_code_err_40_u2_wire                  (rx_code_err_40_u2_wire),

  .dout_40_u3_wire                         (dout_40_u3_wire),
  .dout_40_k_u3_wire                       (dout_40_k_u3_wire),
  .rx_disp_err_40_u3_wire                  (rx_disp_err_40_u3_wire),
  .rx_code_err_40_u3_wire                  (rx_code_err_40_u3_wire), 

  .disparity_out_40_u3                     (disparity_out_40_u3),
  .disparity_out_40_u3_dly                 (disparity_out_40_u3_dly_pipe),

  .dout_vld_pipe                           (dout_vld_pipe),
  .dout_pipe                               (dout_pipe),
  .dout_k_pipe                             (dout_k_pipe),
  .rx_disp_err_pipe                        (rx_disp_err_pipe),
  .rx_code_err_pipe                        (rx_code_err_pipe)
  
);

// GPCS GLUE
 dec_10b8b_4bytes_gpcs_glue u5_dec_10b8b_4bytes_gpcs_glue
(
  .clk40                                   (clk40),
  .clk40_rst_n                             (clk40_rst_n),
  .rx8b10ben                               (rx8b10ben),
  
  .din                                     (din),
  .din_vld                                 (din_vld),
  .din_comma                               (din_comma),
  .dout_bit_swp_en                         (dout_bit_swp_en),
  .dout_bytes_swp_en                       (dout_bytes_swp_en),
  
  .dec_rx_com_det                          (dec_rx_com_det),
  .dout_40_u0_wire                         (dout_40_u0_wire),
  .dout_40_k_u0_wire                       (dout_40_k_u0_wire),
  .rx_disp_err_40_u0_wire                  (rx_disp_err_40_u0_wire),
  .rx_code_err_40_u0_wire                  (rx_code_err_40_u0_wire),

  .dout_40_u1_wire                         (dout_40_u1_wire),
  .dout_40_k_u1_wire                       (dout_40_k_u1_wire),
  .rx_disp_err_40_u1_wire                  (rx_disp_err_40_u1_wire),
  .rx_code_err_40_u1_wire                  (rx_code_err_40_u1_wire),

  .dout_40_u2_wire                         (dout_40_u2_wire),
  .dout_40_k_u2_wire                       (dout_40_k_u2_wire),
  .rx_disp_err_40_u2_wire                  (rx_disp_err_40_u2_wire),
  .rx_code_err_40_u2_wire                  (rx_code_err_40_u2_wire),

  .dout_40_u3_wire                         (dout_40_u3_wire),
  .dout_40_k_u3_wire                       (dout_40_k_u3_wire),
  .rx_disp_err_40_u3_wire                  (rx_disp_err_40_u3_wire),
  .rx_code_err_40_u3_wire                  (rx_code_err_40_u3_wire), 

  .disparity_out_40_u3                     (disparity_out_40_u3),
  .disparity_out_40_u3_dly                 (disparity_out_40_u3_dly_gpcs),

  .dout_vld                                (dout_vld),
  .dout                                    (dout),
  .dout_k                                  (dout_k),
  .dout_comma                              (dout_comma),
  .rx_disp_err                             (rx_disp_err),
  .rx_code_err                             (rx_code_err)

);

  assign disparity_out_40_u3_dly_mx = pipe_prot_en ? disparity_out_40_u3_dly_pipe : disparity_out_40_u3_dly_gpcs; 


//****************************************************************************
//DECODER U0
//****************************************************************************
//always @(posedge clk40 or negedge clk40_rst_n)
//begin
//  if(clk40_rst_n == 1'b0) begin
//    dout_40_u0_r      <= #`PCS_PD  8'd0;
//    dout_40_k[0]      <= #`PCS_PD  1'd0;
//    rx_code_err_40[0] <= #`PCS_PD  1'd0;
//    rx_disp_err_40[0] <= #`PCS_PD  1'd0;
//  end else begin
//    dout_40_u0_r      <= #`PCS_PD  dout_40_u0_wire;
//    dout_40_k[0]      <= #`PCS_PD  dout_40_k_u0_wire;
//    rx_code_err_40[0] <= #`PCS_PD  rx_code_err_40_u0_wire;
//    rx_disp_err_40[0] <= #`PCS_PD  rx_disp_err_40_u0_wire;
//  end
//end

dec_10b8b     u0_4bytes_dec_10b8b  
( 
  .din                         ( din[9:0]                      ),
  .disparity_in                ( disparity_out_40_u3_dly_mx    ),
  .disparity_out               ( disparity_out_40_u0           ),
  .dout                        ( dout_40_u0_wire               ),
  .dout_k                      ( dout_40_k_u0_wire             ),
  .rx_disp_err                 ( rx_disp_err_40_u0_wire        ),
  .rx_code_err                 ( rx_code_err_40_u0_wire        )    
);

//****************************************************************************
//DECODER U1
//**************************************************************************** 
//always @(posedge clk40 or negedge clk40_rst_n)
//begin
//  if(clk40_rst_n == 1'b0) begin
//    dout_40_u1_r      <= #`PCS_PD  8'd0;
//    dout_40_k[1]      <= #`PCS_PD  1'd0;
//    rx_code_err_40[1] <= #`PCS_PD  1'd0;
//    rx_disp_err_40[1] <= #`PCS_PD  1'd0;
//  end else begin
//    dout_40_u1_r      <= #`PCS_PD  dout_40_u1_wire;
//    dout_40_k[1]      <= #`PCS_PD  dout_40_k_u1_wire;
//    rx_code_err_40[1] <= #`PCS_PD  rx_code_err_40_u1_wire;
//    rx_disp_err_40[1] <= #`PCS_PD  rx_disp_err_40_u1_wire;
//  end
//end

dec_10b8b     u1_4bytes_dec_10b8b  
( 
  .din                         ( din[19:10]                    ),
  .disparity_in                ( disparity_out_40_u0           ),
  .disparity_out               ( disparity_out_40_u1           ),
  .dout                        ( dout_40_u1_wire               ),
  .dout_k                      ( dout_40_k_u1_wire             ),
  .rx_disp_err                 ( rx_disp_err_40_u1_wire        ),
  .rx_code_err                 ( rx_code_err_40_u1_wire        )
);

//****************************************************************************
//DECODER U2
//****************************************************************************
//always @(posedge clk40 or negedge clk40_rst_n)
//begin
//  if(clk40_rst_n == 1'b0) begin
//    dout_40_u2_r      <= #`PCS_PD  8'd0;
//    dout_40_k[2]      <= #`PCS_PD  1'd0;
//    rx_code_err_40[2] <= #`PCS_PD  1'd0;
//    rx_disp_err_40[2] <= #`PCS_PD  1'd0;
//  end else begin
//    dout_40_u2_r      <= #`PCS_PD  dout_40_u2_wire;
//    dout_40_k[2]      <= #`PCS_PD  dout_40_k_u2_wire;
//    rx_code_err_40[2] <= #`PCS_PD  rx_code_err_40_u2_wire;
//    rx_disp_err_40[2] <= #`PCS_PD  rx_disp_err_40_u2_wire;
//  end
//end

dec_10b8b     u2_4bytes_dec_10b8b  
( 
  .din                         ( din[29:20]                    ),
  .disparity_in                ( disparity_out_40_u1           ),
  .disparity_out               ( disparity_out_40_u2           ),
  .dout                        ( dout_40_u2_wire               ),
  .dout_k                      ( dout_40_k_u2_wire             ),
  .rx_disp_err                 ( rx_disp_err_40_u2_wire        ),
  .rx_code_err                 ( rx_code_err_40_u2_wire        )
);

//****************************************************************************
//DECODER U3
//**************************************************************************** 
//always @(posedge clk40 or negedge clk40_rst_n)
//begin
//  if(clk40_rst_n == 1'b0) begin
//    dout_40_u3_r      <= #`PCS_PD  8'd0;
//    dout_40_k[3]      <= #`PCS_PD  1'd0;
//    rx_code_err_40[3] <= #`PCS_PD  1'd0;
//    rx_disp_err_40[3] <= #`PCS_PD  1'd0;
//  end else begin
//    dout_40_u3_r      <= #`PCS_PD  dout_40_u3_wire;
//    dout_40_k[3]      <= #`PCS_PD  dout_40_k_u3_wire;
//    rx_code_err_40[3] <= #`PCS_PD  rx_code_err_40_u3_wire;
//    rx_disp_err_40[3] <= #`PCS_PD  rx_disp_err_40_u3_wire;
//  end
//end

dec_10b8b     u3_4bytes_dec_10b8b  
( 
  .din                         ( din[39:30]                    ),
  .disparity_in                ( disparity_out_40_u2           ),
  .disparity_out               ( disparity_out_40_u3           ),
  .dout                        ( dout_40_u3_wire               ),
  .dout_k                      ( dout_40_k_u3_wire             ),
  .rx_disp_err                 ( rx_disp_err_40_u3_wire        ),
  .rx_code_err                 ( rx_code_err_40_u3_wire        )
);

endmodule

//-----------------------------------------------------------------------------
// Project       : at0012v1
//-----------------------------------------------------------------------------
// File          : enc_8b10b_4bytes.v
// Author        : chongzhang
// Created       : 2021.03
// Last modified : 2021.03
//-----------------------------------------------------------------------------
// Description :
// at0012v1 8b10b encode 4bytes
// Modified from AL006
//-----------------------------------------------------------------------------
// Copyright (c) 2021 by anlogic This model is the confidential and
// proprietary property of anlogic and the possession or use of this
// file requires a written license from anlogic.
//-----------------------------------------------------------------------------


`include "../../RTL/rtl_timescale.v" 
module enc_8b10b_4bytes
(
  input                           clk40,
  input                           clk40_rst_n,
  input                           tx8b10ben,  // tie 1 always on

  input                           din_bit_swp,  // unuse now
  input                           din_bytes_swp, // unuse now
  input                           dout_bit_swp, // unuse now
  input                           dout_bytes_swp, // unuse now

  input           [2:0]           pcs_lane_rate, // unuse now
  input           [1:0]           pcs_lane_protocol, // unuse now
  input                           lane_tx_elecidle, // unuse now
  input                           lane_tx_compliance, // unuse now
  input                           oob_mode, // unuse now

  input           [31:0]          din,
  input           [3:0]           din_k,
  input                           din_vld,

  input           [3:0]           run_disp_ctrl0, // unuse now
  input           [3:0]           run_disp_ctrl1, // unuse now

  output          [39:0]          dout,
  output   reg                    dout_vld
);

  parameter                      PROTOCOL_SATA = 2'b10;
  
  parameter                      SATA_PIPE_RATE_G1 = 3'b000;
  parameter                      SATA_PIPE_RATE_G2 = 3'b001;
  parameter                      SATA_PIPE_RATE_G3 = 3'b010;

  localparam                     WIDTH_40B = 40;

  reg                            prev_disp_40;
  wire                           curr_disp_40;

  reg                            disp_orig_40_u0;
  reg                            disp_orig_40_u1;
  reg                            disp_orig_40_u2;
  reg                            disp_orig_40_u3;

  //reg             [9:0]          data0_40_10b;
  //reg             [9:0]          data1_40_10b;
  //reg             [9:0]          data2_40_10b;
  //reg             [9:0]          data3_40_10b;

  wire            [9:0]          dout0_40;
  wire            [9:0]          dout1_40;
  wire            [9:0]          dout2_40;
  wire            [9:0]          dout3_40;

  wire            [9:0]          dout0_40_swp;
  wire            [9:0]          dout1_40_swp;
  wire            [9:0]          dout2_40_swp;
  wire            [9:0]          dout3_40_swp;  

  wire                           disparity_in_40_u0;
  wire                           disparity_in_40_u1;
  wire                           disparity_in_40_u2;
  wire                           disparity_in_40_u3;

  wire                           disparity_out_40_u0;
  wire                           disparity_out_40_u1;
  wire                           disparity_out_40_u2;
  wire                           disparity_out_40_u3;

  wire            [31:0]         din_4bytes_swp;
  wire            [3:0]          din_4kbytes_swp;

  wire            [7:0]          din_8b_1st_swp;
  wire            [7:0]          din_8b_2nd_swp;
  wire            [7:0]          din_8b_3rd_swp;
  wire            [7:0]          din_8b_4th_swp;

  wire            [9:0]          dout_10b_1st_swp;
  wire            [9:0]          dout_10b_2nd_swp;
  wire            [9:0]          dout_10b_3rd_swp;
  wire            [9:0]          dout_10b_4th_swp;

  wire            [39:0]         gend_a_pcs_tx_data, gend_b_pcs_tx_data;
  wire            [39:0]         genq_a_pcs_tx_data, 
                                 genq_b_pcs_tx_data,
                                 genq_c_pcs_tx_data,
                                 genq_d_pcs_tx_data;

  wire            [39:0]         sym_enc_temp_data;
  reg             [39:0]         sym_enc_temp_data_muxed;
  reg             [39:0]         sym_enc_out_data;

  wire                           prot_sata;
  wire                           enc_en;

  //input data swap
  //to be suited to many protocol, swap 8-bit input data, also 2byte/4byte
  //Swap the bits - 10-bits in, 10-bits out
  function automatic [9:0] bitswap_10b_data_out;
   input [9:0] bitswap_10b_data_in;
   integer i;
   begin
    for (i=0; i<10; i=i+1)
        bitswap_10b_data_out[i] = bitswap_10b_data_in[(9-i)];
   end
  endfunction

  //Swap the bits - 8-bits in, 8-bits out
  function automatic [7:0] bitswap_8b_data_out;
   input [7:0] bitswap_8b_data_in;
   integer i;
   begin
    for (i=0; i<8; i=i+1)
        bitswap_8b_data_out[i] = bitswap_8b_data_in[(7-i)];
   end
  endfunction

  assign din_8b_1st_swp[7:0] = din_bit_swp ? bitswap_8b_data_out(din[7:0])   : din[7:0];
  assign din_8b_2nd_swp[7:0] = din_bit_swp ? bitswap_8b_data_out(din[15:8])  : din[15:8];
  assign din_8b_3rd_swp[7:0] = din_bit_swp ? bitswap_8b_data_out(din[23:16]) : din[23:16];
  assign din_8b_4th_swp[7:0] = din_bit_swp ? bitswap_8b_data_out(din[31:24]) : din[31:24];
 
  assign din_4bytes_swp  = din_bytes_swp ? {din_8b_1st_swp, din_8b_2nd_swp, din_8b_3rd_swp, din_8b_4th_swp} 
                                         : {din_8b_4th_swp, din_8b_3rd_swp, din_8b_2nd_swp, din_8b_1st_swp};
  assign din_4kbytes_swp = din_bytes_swp ? {din_k[0], din_k[1], din_k[2], din_k[3]} 
                                         : din_k[3:0];

  //encoder output selection
  assign dout_10b_1st_swp[9:0] = sym_enc_out_data[9:0];
  assign dout_10b_2nd_swp[9:0] = sym_enc_out_data[19:10];
  assign dout_10b_3rd_swp[9:0] = sym_enc_out_data[29:20];
  assign dout_10b_4th_swp[9:0] = sym_enc_out_data[39:30];
  
  //select 2-byte or 4-byte
  assign dout = dout_bytes_swp ? {dout_10b_1st_swp, dout_10b_2nd_swp, dout_10b_3rd_swp, dout_10b_4th_swp} 
                               : {dout_10b_4th_swp, dout_10b_3rd_swp, dout_10b_2nd_swp, dout_10b_1st_swp};
    
  // Four parallel 8b10b encoders are used to convert incoming
  // byte(s) into 10-bit word(s).  Encoders are fully combinational.
  assign prot_sata = (pcs_lane_protocol == PROTOCOL_SATA);
  assign enc_en = tx8b10ben;

  reg [1:0] sample_count;
  always @(posedge clk40 or negedge clk40_rst_n) begin
    if (~clk40_rst_n) begin
      sample_count <= #`PCS_PD  2'd0;
    end else if (prot_sata) begin 
      if (oob_mode==1'b0) begin
        sample_count <= #`PCS_PD  2'd0; 
      end else begin 
        sample_count <= #`PCS_PD  sample_count + 2'd1;
      end 
    end
  end

  assign dout0_40_swp[9:0] = dout_bit_swp ? bitswap_10b_data_out(dout0_40[9:0]) : dout0_40[9:0] ;
  assign dout1_40_swp[9:0] = dout_bit_swp ? bitswap_10b_data_out(dout1_40[9:0]) : dout1_40[9:0] ;
  assign dout2_40_swp[9:0] = dout_bit_swp ? bitswap_10b_data_out(dout2_40[9:0]) : dout2_40[9:0] ;
  assign dout3_40_swp[9:0] = dout_bit_swp ? bitswap_10b_data_out(dout3_40[9:0]) : dout3_40[9:0] ;

  assign sym_enc_temp_data = {dout3_40_swp, dout2_40_swp, dout1_40_swp, dout0_40_swp};

  // SATA Gen2, in OOB mode, doubling each bit!
  genvar                      gend_i;
  generate 
    for (gend_i = 0; gend_i < WIDTH_40B/2; 
         gend_i = gend_i + 1) begin: gend_loop
      assign gend_a_pcs_tx_data[((gend_i+1)*2)-1:gend_i*2] = 
        {2{sym_enc_temp_data[WIDTH_40B/2 + gend_i]}};// MSB
      assign gend_b_pcs_tx_data[((gend_i+1)*2)-1:gend_i*2] = 
        {2{sym_enc_temp_data[gend_i]}};// LSB
    end
  endgenerate
   
  // SATA Gen3, in OOB mode, quadrupling each bit!
  genvar                      genq_i;
  generate 
    for (genq_i = 0; genq_i < WIDTH_40B/4; 
         genq_i = genq_i + 1) begin: genq_loop
      assign genq_a_pcs_tx_data[((genq_i+1)*4)-1:genq_i*4] = 
        {4{sym_enc_temp_data[3*WIDTH_40B/4 + genq_i]}};//MSB
      assign genq_b_pcs_tx_data[((genq_i+1)*4)-1:genq_i*4] = 
        {4{sym_enc_temp_data[2*WIDTH_40B/4 + genq_i]}};
      assign genq_c_pcs_tx_data[((genq_i+1)*4)-1:genq_i*4] = 
        {4{sym_enc_temp_data[WIDTH_40B/4 + genq_i]}};
      assign genq_d_pcs_tx_data[((genq_i+1)*4)-1:genq_i*4] = 
        {4{sym_enc_temp_data[genq_i]}};// LSB
    end
  endgenerate

  always @* begin
    if (oob_mode) begin 
      case (pcs_lane_rate)
        // Gen1: Simplest case. Simply register
        SATA_PIPE_RATE_G1: begin 
           sym_enc_temp_data_muxed = sym_enc_temp_data; 
        end
        // Gen2: Select between gen2_a or gen2_b word based on 
        //       even or odd sample_count 
        SATA_PIPE_RATE_G2: begin 
           case(sample_count[0])
             1'b0: sym_enc_temp_data_muxed = gend_b_pcs_tx_data;
             // 1'b1: sym_enc_temp_data_muxed = gend_b_pcs_tx_data;
             default: sym_enc_temp_data_muxed = gend_a_pcs_tx_data;
           endcase // case (sample_count[0])
        end
        // Gen3: Selects A, B, C or D phase based on sample_count
        SATA_PIPE_RATE_G3: begin 
           case(sample_count)
             2'b00:   sym_enc_temp_data_muxed = genq_d_pcs_tx_data;
             2'b01:   sym_enc_temp_data_muxed = genq_c_pcs_tx_data;
             2'b10:   sym_enc_temp_data_muxed = genq_b_pcs_tx_data;
             //2'b11: sym_enc_temp_data_muxed = genq_d_pcs_tx_data;
             default: sym_enc_temp_data_muxed = genq_a_pcs_tx_data;
           endcase // case(sample_count)
        end
        default: begin
          sym_enc_temp_data_muxed = sym_enc_temp_data; 
        end
      endcase // case(pcs_lane_rate)
    end else begin 
      sym_enc_temp_data_muxed = sym_enc_temp_data;
    end 
  end

  always @(posedge clk40 or negedge clk40_rst_n)
  begin
    if (clk40_rst_n == 1'b0)
      sym_enc_out_data <= #`PCS_PD  40'd0;
    else
      sym_enc_out_data <= #`PCS_PD  sym_enc_temp_data_muxed;
  end		

  always @(posedge clk40 or negedge clk40_rst_n)
  begin
    if (clk40_rst_n == 1'b0)
      dout_vld <= #`PCS_PD  1'b0;
    else
      dout_vld <= #`PCS_PD  (oob_mode || din_vld);
  end		

//==================================================================================
//32->40bit encoder
//==================================================================================
//****************************************************************************
//ENCODER U0
//****************************************************************************
// When tx_compliance is asserted, we need 
// to force the disparity to negative on the current data.
assign curr_disp_40 = !lane_tx_compliance && prev_disp_40;

always @(posedge clk40 or negedge clk40_rst_n)
begin
  if (clk40_rst_n == 1'b0)
     prev_disp_40 <= #`PCS_PD  1'b0;
  else if (enc_en & din_vld &
           (~oob_mode || 
            (oob_mode & 
             ((pcs_lane_rate==SATA_PIPE_RATE_G3 && sample_count==2'd3) || 
              (pcs_lane_rate==SATA_PIPE_RATE_G2 && sample_count[0]==1'b1) || 
               pcs_lane_rate==SATA_PIPE_RATE_G1))))
     prev_disp_40 <= #`PCS_PD  disparity_out_40_u3;
end

always @(posedge clk40 or negedge clk40_rst_n)
begin
  if (clk40_rst_n == 1'b0)
    disp_orig_40_u0 <= #`PCS_PD  1'b0;
  else
    disp_orig_40_u0 <= #`PCS_PD  disparity_out_40_u0;
end		

//disparity used
assign disparity_in_40_u0 = ({run_disp_ctrl1[0], run_disp_ctrl0[0]} == 2'b00) ? curr_disp_40 :
                            ({run_disp_ctrl1[0], run_disp_ctrl0[0]} == 2'b01) ? ~curr_disp_40 :
                            ({run_disp_ctrl1[0], run_disp_ctrl0[0]} == 2'b10) ? 1'b0 :
                            ({run_disp_ctrl1[0], run_disp_ctrl0[0]} == 2'b11) ? 1'b1 : disp_orig_40_u0;

enc_8b10b u0_4bytes_enc_8b10b
(
  .din                    (  din_4bytes_swp[7:0]   ),
  .din_k                  (  din_4kbytes_swp[0]    ),
  .disparity_in           (  disparity_in_40_u0    ),
  .disparity_out          (  disparity_out_40_u0   ),
  .dout                   (  dout0_40              )
);
//****************************************************************************
//ENCODER U1
//****************************************************************************
always @(posedge clk40 or negedge clk40_rst_n)
  begin
    if (clk40_rst_n == 1'b0)
      disp_orig_40_u1 <= #`PCS_PD  1'b0;
    else
      disp_orig_40_u1 <= #`PCS_PD  disparity_out_40_u1;
  end		

//disparity used
assign disparity_in_40_u1 = ({run_disp_ctrl1[1], run_disp_ctrl0[1]} == 2'b00) ? disparity_out_40_u0 :
                            ({run_disp_ctrl1[1], run_disp_ctrl0[1]} == 2'b01) ? ~disparity_out_40_u0 :
                            ({run_disp_ctrl1[1], run_disp_ctrl0[1]} == 2'b10) ? 1'b0 :
                            ({run_disp_ctrl1[1], run_disp_ctrl0[1]} == 2'b11) ? 1'b1 : disp_orig_40_u1;

enc_8b10b u1_4bytes_enc_8b10b
(
  .din                    (  din_4bytes_swp[15:8]  ),
  .din_k                  (  din_4kbytes_swp[1]    ),
  .disparity_in           (  disparity_in_40_u1    ),
  .disparity_out          (  disparity_out_40_u1   ),
  .dout                   (  dout1_40              )
);

//****************************************************************************
//ENCODER U2
//****************************************************************************
always @(posedge clk40 or negedge clk40_rst_n)
  begin
    if (clk40_rst_n == 1'b0)
      disp_orig_40_u2 <= #`PCS_PD  1'b0;
    else
      disp_orig_40_u2 <= #`PCS_PD  disparity_out_40_u2;
  end		

//disparity used
assign disparity_in_40_u2 = ({run_disp_ctrl1[2], run_disp_ctrl0[2]} == 2'b00) ? disparity_out_40_u1 :
                            ({run_disp_ctrl1[2], run_disp_ctrl0[2]} == 2'b01) ? ~disparity_out_40_u1 :
                            ({run_disp_ctrl1[2], run_disp_ctrl0[2]} == 2'b10) ? 1'b0 :
                            ({run_disp_ctrl1[2], run_disp_ctrl0[2]} == 2'b11) ? 1'b1 : disp_orig_40_u2;

enc_8b10b u2_4bytes_enc_8b10b
(
  .din                    (  din_4bytes_swp[23:16] ),
  .din_k                  (  din_4kbytes_swp[2]    ),
  .disparity_in           (  disparity_in_40_u2    ),
  .disparity_out          (  disparity_out_40_u2   ),
  .dout                   (  dout2_40              )
);

//****************************************************************************
//ENCODER U3
//****************************************************************************
always @(posedge clk40 or negedge clk40_rst_n)
  begin
    if (clk40_rst_n == 1'b0)
      disp_orig_40_u3 <= #`PCS_PD  1'b0;
    else
      disp_orig_40_u3 <= #`PCS_PD  disparity_out_40_u3;
  end		

//disparity used
assign disparity_in_40_u3 = ({run_disp_ctrl1[3], run_disp_ctrl0[3]} == 2'b00) ? disparity_out_40_u2 :
                            ({run_disp_ctrl1[3], run_disp_ctrl0[3]} == 2'b01) ? ~disparity_out_40_u2 :
                            ({run_disp_ctrl1[3], run_disp_ctrl0[3]} == 2'b10) ? 1'b0 :
                            ({run_disp_ctrl1[3], run_disp_ctrl0[3]} == 2'b11) ? 1'b1 : disp_orig_40_u3;

enc_8b10b u3_4bytes_enc_8b10b
(
  .din                    (  din_4bytes_swp[31:24] ),
  .din_k                  (  din_4kbytes_swp[3]    ),
  .disparity_in           (  disparity_in_40_u3    ),
  .disparity_out          (  disparity_out_40_u3   ),
  .dout                   (  dout3_40              )
);

endmodule

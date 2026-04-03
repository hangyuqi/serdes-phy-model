//-----------------------------------------------------------------------------
// Project       : at0012v1
//-----------------------------------------------------------------------------
// File          : enc_8b10b.v
// Author        : chongzhang
// Created       : 2021.03
// Last modified : 2021.03
//-----------------------------------------------------------------------------
// Description :
// at0012v1 8b10b encode fully combinational logic
//-----------------------------------------------------------------------------
// Copyright (c) 2021 by anlogic This model is the confidential and
// proprietary property of anlogic and the possession or use of this
// file requires a written license from anlogic.
//------------------------------------------------------------------------------


`include "../../RTL/rtl_timescale.v" 
module enc_8b10b
(
  input           [7:0]       din,
  input                       din_k,
  input                       disparity_in,
  output                      disparity_out,
  output   wire   [9:0]       dout
);

    //wire err;
    wire [2:0]          data_8b_fgh = {din[5], din[6], din[7]};
    wire [4:0]          data_8b_abcde = {din[0], din[1],
                                         din[2], din[3], din[4]};

    wire                en_04 = (data_8b_abcde[4:1] == 4'b0000);
    wire                en_13 = ((data_8b_abcde[4:1] == 4'b0001) ||
                                 (data_8b_abcde[4:1] == 4'b0010) ||
                                 (data_8b_abcde[4:1] == 4'b0100) ||
                                 (data_8b_abcde[4:1] == 4'b1000));
    wire                en_22 = ((data_8b_abcde[4:1] == 4'b0011) ||
                                 (data_8b_abcde[4:1] == 4'b0101) ||
                                 (data_8b_abcde[4:1] == 4'b0110) ||
                                 (data_8b_abcde[4:1] == 4'b1001) ||
                                 (data_8b_abcde[4:1] == 4'b1010) ||
                                 (data_8b_abcde[4:1] == 4'b1100));
    wire                en_31 = ((data_8b_abcde[4:1] == 4'b1110) ||
                                 (data_8b_abcde[4:1] == 4'b1101) ||
                                 (data_8b_abcde[4:1] == 4'b1011) ||
                                 (data_8b_abcde[4:1] == 4'b0111));
    wire                en_40 = (data_8b_abcde[4:1] == 4'b1111);
    wire                d_in = data_8b_abcde[1];
    wire                e_in = data_8b_abcde[0];

    wire [5:0]          data_10b_abcdei_pre = {data_8b_abcde, 1'b0};

    wire [5:0]          force_10b_abcdei = {// bit 'a'
                                            1'b0,

                                            // bit 'b'
                                            en_04,

                                            // bit 'c'
                                            en_04 ||
                                            (en_13 && d_in && e_in),

                                            // bit 'd'
                                            1'b0,

                                            // bit 'e'
                                            (en_13 && !e_in),

                                            // bit 'i'
                                            (en_22 && !e_in) ||
                                            (en_04 && e_in) ||
                                            (en_13 && !d_in && e_in) ||
                                            (en_22 && din_k) ||
                                            (en_40 && e_in)};

    wire [5:0]          clear_10b_abcdei = {// bit 'a'
                                            1'b0,

                                            // bit 'b'
                                            en_40,

                                            // bit 'c'
                                            1'b0,

                                            // bit 'd'
                                            en_40,

                                            // bit 'e'
                                            (en_13 && d_in && e_in),

                                            // bit 'i'
                                            1'b0};

    wire [5:0]          data_10b_abcdei_init = (data_10b_abcdei_pre | force_10b_abcdei) & ~clear_10b_abcdei;

    wire                disp_6b_neg = ((!en_22 && !en_31 && !e_in) ||
                                       (en_13 && d_in && e_in));
    wire                disp_6b_pos = ((!en_22 && !en_13 & e_in) ||
                                       din_k);
    wire                compl_6b = disparity_in ? (disp_6b_pos || (data_8b_abcde == 5'b11100)) : disp_6b_neg;

    wire [5:0]          data_10b_abcdei = data_10b_abcdei_init ^ {6{compl_6b}};
    wire                disp_post_6b = disparity_in ^ (disp_6b_neg | disp_6b_pos);


    // 3b/4b encoder
    //
    // Generate some controls which are specific to the 3b/4b portion of the encoder
    //
    wire                f_in = data_8b_fgh[2];
    wire                g_in = data_8b_fgh[1];
    wire                h_in = data_8b_fgh[0];
    wire                e_out = data_10b_abcdei[1];
    wire                i_out = data_10b_abcdei[0];
    wire                en_alt7 = ((data_8b_fgh == 3'b111) &&
                                   (din_k ||
                                    (e_out && i_out && !disp_post_6b) ||
                                    (!e_out && !i_out && disp_post_6b)));

    // The "typical" encoding from FGH->fghj is simply to copy the original bits
    // and tack on a zero.  Generate that value here and we'll modify it as necessary.
    //
    wire [3:0]          data_10b_fghj_pre = {data_8b_fgh, 1'b0};


    // Generate a set of bits to be forced to one based on the 3b/4b input controls
    //
    wire [3:0]          force_10b_fghj = {// bit 'f'
                                          1'b0,

                                          // bit 'g'
                                          (data_8b_fgh == 3'b000),

                                          // bit 'h'
                                          1'b0,

                                          // bit 'j'
                                          (f_in ^ g_in) & !h_in};

    // Generate the output of the 3b/4b encoding table, without taking the current running disparity
    // into account.
    //
    wire [3:0]          data_10b_fghj_init = en_alt7 ? 4'b0111 : (data_10b_fghj_pre | force_10b_fghj);

    // Generate some terms which indicate whether or not to invert the 6b data based on the current
    // running disparity
    //
    wire                disp_4b_neg = (!f_in & !g_in);
    wire                disp_4b_pos = (f_in & g_in & h_in);
    wire                compl_if_pos = f_in & g_in;
    wire                compl_if_neg = disp_4b_neg || ((f_in ^ g_in) && din_k);
    wire                compl_4b = disp_post_6b ? compl_if_pos : compl_if_neg;

    // Generate final 4b encoding and calculate post-4b disparity (i.e. the final disparity)
    //
    wire [3:0]          data_10b_fghj = data_10b_fghj_init ^ {4{compl_4b}};
    assign              disparity_out = disp_post_6b ^ (disp_4b_neg | disp_4b_pos);


    // The only error that the encoder can generate is due to illegal k-code requests.  The only
    // valid k-codes are K28.X (where X can be 0-7), and K23.7, K27.7, K29.7, and K30.7.  Verify
    // validity of incoming data here
    //
    //wire                k_valid = ((data_8b_abcde == 5'b00111) || // Any K28 is OK
    //                               ((data_8b_fgh == 3'b111) && e_in && en_31)); // K23/27/29/30.7 is OK

    // Finally assign to the outputs
    //
    //assign              err = din_k && !k_valid;
    assign              dout = {data_10b_abcdei, data_10b_fghj};

endmodule


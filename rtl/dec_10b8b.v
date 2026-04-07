//-----------------------------------------------------------------------------
// Project       : at0012v1
//-----------------------------------------------------------------------------
// File          : dec_10b8b.v
// Author        : chongzhang
// Created       : 2021.03
// Last modified : 2021.03
//-----------------------------------------------------------------------------
// Description :
// at0012v1 10b8b decoder
//-----------------------------------------------------------------------------
// Copyright (c) 2021 by anlogic This model is the confidential and
// proprietary property of anlogic and the possession or use of this
// file requires a written license from anlogic.
//-----------------------------------------------------------------------------

`include "../../RTL/rtl_timescale.v"

module dec_10b8b
(
  input                [9:0]        din,
  input                             disparity_in,

  output                            disparity_out,
  output               [7:0]        dout,
  output        	                dout_k,
  output        	                rx_disp_err,
  output        	                rx_code_err  
);

    wire [5:0]          data_10b_abcdei = din[9:4];
    wire [3:0]          data_10b_fghj = din[3:0];

    wire                p_13 = ((data_10b_abcdei[5:2] == 4'b0001) ||
                                (data_10b_abcdei[5:2] == 4'b0010) ||
                                (data_10b_abcdei[5:2] == 4'b0100) ||
                                (data_10b_abcdei[5:2] == 4'b1000));
    wire                p_22 = ((data_10b_abcdei[5:2] == 4'b0011) ||
                                (data_10b_abcdei[5:2] == 4'b0101) ||
                                (data_10b_abcdei[5:2] == 4'b0110) ||
                                (data_10b_abcdei[5:2] == 4'b1001) ||
                                (data_10b_abcdei[5:2] == 4'b1010) ||
                                (data_10b_abcdei[5:2] == 4'b1100));
    wire                p_31 = ((data_10b_abcdei[5:2] == 4'b1110) ||
                                (data_10b_abcdei[5:2] == 4'b1101) ||
                                (data_10b_abcdei[5:2] == 4'b1011) ||
                                (data_10b_abcdei[5:2] == 4'b0111));

    wire                a_in = data_10b_abcdei[5];
    wire                b_in = data_10b_abcdei[4];
    wire                c_in = data_10b_abcdei[3];
    wire                d_in = data_10b_abcdei[2];
    wire                e_in = data_10b_abcdei[1];
    wire                i_in = data_10b_abcdei[0];
    wire                e_eq_i = (e_in == i_in);

    wire [4:0]          data_8b_abcde_pre = data_10b_abcdei[5:1];

    wire [4:0]          compl_8b_abcde = {// bit 'A'
                                          ((data_10b_abcdei[5:2] == 4'b1001) && e_eq_i) ||
                                          (p_31 && i_in) ||
                                          (data_10b_abcdei == 6'b000111) ||
                                          ((data_10b_abcdei[5:2] == 4'b0101) && e_eq_i) ||
                                          (p_13 && !e_in) ||
                                          (a_in && b_in && e_in && i_in) ||
                                          (data_10b_abcdei[3:0] == 4'b0000)
                                          ,

                                          // bit 'B'
                                          ((data_10b_abcdei[5:2] == 4'b0110) && e_eq_i) ||
                                          (p_31 && i_in) ||
                                          (data_10b_abcdei == 6'b000111) ||
                                          ((data_10b_abcdei[5:2] == 4'b1010) && e_eq_i) ||
                                          (p_13 && !e_in) ||
                                          (a_in && b_in && e_in && i_in) ||
                                          (data_10b_abcdei[3:0] == 4'b0000)
                                          ,

                                          // bit 'C'
                                          ((data_10b_abcdei[5:2] == 4'b0110) && e_eq_i) ||
                                          (p_31 && i_in) ||
                                          (data_10b_abcdei == 6'b000111) ||
                                          ((data_10b_abcdei[5:2] == 4'b0101) && e_eq_i) ||
                                          (p_13 && !e_in) ||
                                          (!a_in && !b_in && !e_in && !i_in) ||
                                          (data_10b_abcdei[3:0] == 4'b0000)
                                          ,

                                          // bit 'D'
                                          ((data_10b_abcdei[5:2] == 4'b1001) && e_eq_i) ||
                                          (p_31 && i_in) ||
                                          (data_10b_abcdei == 6'b000111) ||
                                          ((data_10b_abcdei[5:2] == 4'b1010) && e_eq_i) ||
                                          (p_13 && !e_in) ||
                                          (a_in && b_in && e_in && i_in) ||
                                          (data_10b_abcdei[3:0] == 4'b0000)
                                          ,

                                          // bit 'E'
                                          ((data_10b_abcdei[5:2] == 4'b1001) && e_eq_i) ||
                                          (p_13 && !i_in) ||
                                          (data_10b_abcdei == 6'b000111) ||
                                          ((data_10b_abcdei[5:2] == 4'b0101) && e_eq_i) ||
                                          (p_13 && !e_in) ||
                                          (!a_in && !b_in && !e_in && !i_in) ||
                                          (data_10b_abcdei[3:0] == 4'b0000)
                                          };

    wire [4:0]          data_8b_abcde = data_8b_abcde_pre ^ compl_8b_abcde;

    wire                disp_6b_neg = ((p_22 && !e_in && !i_in) ||
                                       (p_13 && !i_in) ||
                                       (p_13 && !e_in));
    wire                disp_6b_pos = ((p_22 && e_in && i_in) ||
                                       (p_31 && i_in) ||
                                       (p_31 && e_in));
    wire                disp_6b_err_if_rd_neg = disp_6b_neg || (data_10b_abcdei == 6'b000111);
    wire                disp_6b_err_if_rd_pos = disp_6b_pos || (data_10b_abcdei == 6'b111000);

    wire                disp_6b_err = disparity_in ? disp_6b_err_if_rd_pos : disp_6b_err_if_rd_neg;
    wire                disp_post_5b = (disp_6b_err ?
                                        (disp_6b_pos || (data_10b_abcdei == 6'b000111)) :
                                        disparity_in ^ (disp_6b_neg || disp_6b_pos));

    // 4b/3b decoder
    //
    // Generate some controls which are specific to the 3b/4b portion of the encoder
    //
    wire                f_in = data_10b_fghj[3];
    wire                g_in = data_10b_fghj[2];
    wire                h_in = data_10b_fghj[1];
    wire                j_in = data_10b_fghj[0];

    wire [2:0]          data_8b_fgh_pre = data_10b_fghj[3:1];
    
    wire                flip_fgh = ((!c_in && !d_in && !e_in && !i_in && (h_in != j_in)) ||
                                    (data_10b_fghj == 4'b0011) ||
                                    (f_in && g_in && j_in) ||
                                    (!f_in && !g_in && !h_in));

    wire [2:0]          compl_8b_fgh = {// bit 'F'
                                        ((f_in && h_in && j_in) ||
                                         flip_fgh ||
                                         (g_in && h_in && j_in))
                                        ,

                                        // bit 'G'
                                        ((!f_in && !h_in && !j_in) ||
                                         flip_fgh ||
                                         (!g_in && !h_in && !j_in))
                                        ,

                                        // bit 'H'
                                        ((f_in && h_in && j_in) ||
                                         flip_fgh ||
                                         (!g_in && !h_in && !j_in))
                                        };

    // Generate the output of the 4b/3b decoding table
    //
    wire [2:0]          data_8b_fgh = data_8b_fgh_pre ^ compl_8b_fgh;

    // Generate some terms which indicate the disparity of the received 4b data
    //
    wire                disp_4b_neg = ((!f_in && !h_in && !j_in) ||
                                       (!f_in && !g_in && !j_in) ||
                                       (!f_in && !g_in && !h_in) ||
                                       (!g_in && !h_in && !j_in));

    wire                disp_4b_pos = ((f_in && h_in && j_in) ||
                                       (f_in && g_in && j_in) ||
                                       (f_in && g_in && h_in) ||
                                       (g_in && h_in && j_in));
    wire                disp_4b_err_if_rd_neg = disp_4b_neg || (data_10b_fghj == 4'b0011);
    wire                disp_4b_err_if_rd_pos = disp_4b_pos || (data_10b_fghj == 4'b1100);


    // Calculate disparity error as well as post-6b/5b disparity
    //
    wire                disp_4b_err  = disp_post_5b ? disp_4b_err_if_rd_pos : disp_4b_err_if_rd_neg;
    wire                disp_post_3b = (disp_4b_err ?
                                        (disp_4b_pos || (data_10b_fghj == 4'b0011)) :
                                        disp_post_5b ^ (disp_4b_neg || disp_4b_pos));
    // Calculate coding errors
    //
    wire                ghj_equiv = (g_in == h_in) && (h_in == j_in);
    assign              rx_code_err  = ((data_10b_abcdei[5:2] == 4'b1111) ||
                                     (data_10b_abcdei[5:2] == 4'b0000) ||
                                     (p_13 && !e_in && !i_in) ||
                                     (p_31 && e_in && i_in) ||
                                     (data_10b_fghj == 4'b0000) ||
                                     (data_10b_fghj == 4'b1111) ||
                                     (disp_6b_pos && (data_10b_fghj == 4'b1100)) ||
                                     (disp_6b_neg && (data_10b_fghj == 4'b0011)) ||
                                     (disp_4b_err_if_rd_pos && (data_10b_abcdei == 6'b000111)) ||
                                     (disp_4b_err_if_rd_neg && (data_10b_abcdei == 6'b111000)) ||
                                     (c_in && d_in && e_in && i_in && !f_in && !g_in && !h_in) ||
                                     (!c_in && !d_in && !e_in && !i_in && f_in && g_in && h_in) ||
                                     (e_eq_i && (e_in == f_in) && (e_in == g_in) && (e_in == h_in)) ||
                                     (!e_eq_i && (e_in == g_in) && ghj_equiv) ||
                                     (e_eq_i && (e_in != g_in) && ghj_equiv &&
                                      !((c_in == d_in) && (d_in == e_in))) ||
                                     (!p_31 && e_in && !i_in && !g_in && !h_in && !j_in) ||
                                     (!p_13 && !e_in && i_in && g_in && h_in && j_in) ||
                                     (disp_6b_neg && disp_4b_neg) ||
                                     (disp_6b_pos && disp_4b_pos));

    // Generate final outputs
    //
    // Swizzle data around from ABCDE/FGH to HGFEDCBA
    //
    assign              dout = {data_8b_fgh[0],
                                data_8b_fgh[1],
                                data_8b_fgh[2],
                                data_8b_abcde[0],
                                data_8b_abcde[1],
                                data_8b_abcde[2],
                                data_8b_abcde[3],
                                data_8b_abcde[4]};
    assign              dout_k = (!c_in && !d_in && !e_in && !i_in) ||
                                 (c_in && d_in && e_in && i_in) ||
                                 (p_13 && !e_in && i_in && g_in && h_in && j_in) ||
                                 (p_31 && e_in && !i_in && !g_in && !h_in && !j_in);
    assign              rx_disp_err = disp_6b_err || disp_4b_err;
    assign              disparity_out = disp_post_3b;

endmodule


module decoder_8b10b_40to32 (
    input         pclk,
    input         rst_n,
    input  [39:0] rx_code,
    input         data_valid_in,
    output [31:0] rxdata,
    output [3:0]  rxdatak,
    output        decode_err,
    output        disp_err,
    output        data_valid_out
);

    // Disparity chain wires
    wire disparity_out_u0;
    wire disparity_out_u1;
    wire disparity_out_u2;
    wire disparity_out_u3;

    // Disparity feedback register: previous cycle's u3 output feeds u0's input
    reg disparity_prev;

    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n)
            disparity_prev <= #`PCS_PD 1'b0;
        else if (data_valid_in)
            disparity_prev <= #`PCS_PD disparity_out_u3;
    end

    // Per-lane decode outputs
    wire [7:0] dout_u0, dout_u1, dout_u2, dout_u3;
    wire       dout_k_u0, dout_k_u1, dout_k_u2, dout_k_u3;
    wire       rx_disp_err_u0, rx_disp_err_u1, rx_disp_err_u2, rx_disp_err_u3;
    wire       rx_code_err_u0, rx_code_err_u1, rx_code_err_u2, rx_code_err_u3;

    //------------------------------------------------------------------------
    // DECODER U0: rx_code[9:0]
    //------------------------------------------------------------------------
    dec_10b8b u0_dec (
        .din           (rx_code[9:0]),
        .disparity_in  (disparity_prev),
        .disparity_out (disparity_out_u0),
        .dout          (dout_u0),
        .dout_k        (dout_k_u0),
        .rx_disp_err   (rx_disp_err_u0),
        .rx_code_err   (rx_code_err_u0)
    );

    //------------------------------------------------------------------------
    // DECODER U1: rx_code[19:10]
    //------------------------------------------------------------------------
    dec_10b8b u1_dec (
        .din           (rx_code[19:10]),
        .disparity_in  (disparity_out_u0),
        .disparity_out (disparity_out_u1),
        .dout          (dout_u1),
        .dout_k        (dout_k_u1),
        .rx_disp_err   (rx_disp_err_u1),
        .rx_code_err   (rx_code_err_u1)
    );

    //------------------------------------------------------------------------
    // DECODER U2: rx_code[29:20]
    //------------------------------------------------------------------------
    dec_10b8b u2_dec (
        .din           (rx_code[29:20]),
        .disparity_in  (disparity_out_u1),
        .disparity_out (disparity_out_u2),
        .dout          (dout_u2),
        .dout_k        (dout_k_u2),
        .rx_disp_err   (rx_disp_err_u2),
        .rx_code_err   (rx_code_err_u2)
    );

    //------------------------------------------------------------------------
    // DECODER U3: rx_code[39:30]
    //------------------------------------------------------------------------
    dec_10b8b u3_dec (
        .din           (rx_code[39:30]),
        .disparity_in  (disparity_out_u2),
        .disparity_out (disparity_out_u3),
        .dout          (dout_u3),
        .dout_k        (dout_k_u3),
        .rx_disp_err   (rx_disp_err_u3),
        .rx_code_err   (rx_code_err_u3)
    );

    //------------------------------------------------------------------------
    // Combine 4-lane outputs: {u3, u2, u1, u0}
    //------------------------------------------------------------------------
    assign rxdata      = {dout_u3, dout_u2, dout_u1, dout_u0};
    assign rxdatak     = {dout_k_u3, dout_k_u2, dout_k_u1, dout_k_u0};
    assign decode_err  = rx_code_err_u0 | rx_code_err_u1 | rx_code_err_u2 | rx_code_err_u3;
    assign disp_err    = rx_disp_err_u0 | rx_disp_err_u1 | rx_disp_err_u2 | rx_disp_err_u3;
    assign data_valid_out = data_valid_in;

endmodule

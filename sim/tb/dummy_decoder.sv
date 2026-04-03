module decoder_8b10b_40to32 (
    input  [39:0] rx_code,
    output [31:0] rxdata,
    output [3:0]  rxdatak,
    output        decode_err,
    output        disp_err
);

    // Placeholder: outputs all zeros until real decoder is integrated
    assign rxdata     = 32'd0;
    assign rxdatak    = 4'd0;
    assign decode_err = 1'b0;
    assign disp_err   = 1'b0;

endmodule

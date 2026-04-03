module rx_path (
    input  logic        pclk,
    input  logic        rst_n,
    input  logic [39:0] rx_code,
    input  logic        rx_code_valid,
    output logic [31:0] rxdata,
    output logic [3:0]  rxdatak,
    output logic        decode_err,
    output logic        disp_err
);

    logic [31:0] decoded_rx_data;
    logic [3:0]  decoded_rx_datak;
    logic        decoded_err_raw;
    logic        disp_err_raw;

    // Assumption for the first scaffold:
    // - external decoder module name: decoder_8b10b_40to32
    // - port names below may need to be adjusted to match the existing codec
    decoder_8b10b_40to32 u_decoder (
        .rx_code    (rx_code),
        .rxdata     (decoded_rx_data),
        .rxdatak    (decoded_rx_datak),
        .decode_err (decoded_err_raw),
        .disp_err   (disp_err_raw)
    );

    always_ff @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            rxdata      <= '0;
            rxdatak     <= '0;
            decode_err  <= 1'b0;
            disp_err    <= 1'b0;
        end else if (rx_code_valid) begin
            rxdata      <= decoded_rx_data;
            rxdatak     <= decoded_rx_datak;
            decode_err  <= decoded_err_raw;
            disp_err    <= disp_err_raw;
        end
    end

endmodule

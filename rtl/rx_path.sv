module rx_path (
    input  logic        pclk,
    input  logic        serial_clk,
    input  logic        rst_n,
    input  logic        serial_rx,
    output logic [31:0] rxdata,
    output logic [3:0]  rxdatak,
    output logic        rx_valid,
    output logic        decode_err,
    output logic        disp_err
);

    logic [39:0] rx_code_deser;
    logic [39:0] rx_code_aligned;
    logic        byte_aligned;
    logic [31:0] decoded_rx_data;
    logic [3:0]  decoded_rx_datak;
    logic        decoded_err_raw;
    logic        disp_err_raw;
    logic        decoded_valid;

    deserializer #(
        .WIDTH(40)
    ) u_deserializer (
        .serial_clk    (serial_clk),
        .pclk          (pclk),
        .rst_n         (rst_n),
        .serial_rx     (serial_rx),
        .parallel_data (rx_code_deser)
    );

    byte_aligner u_byte_aligner (
        .pclk     (pclk),
        .rst_n    (rst_n),
        .data_in  (rx_code_deser),
        .data_out (rx_code_aligned),
        .aligned  (byte_aligned)
    );

    decoder_8b10b_40to32 u_decoder (
        .pclk           (pclk),
        .rst_n          (rst_n),
        .rx_code        (rx_code_aligned),
        .data_valid_in  (byte_aligned),
        .rxdata         (decoded_rx_data),
        .rxdatak        (decoded_rx_datak),
        .decode_err     (decoded_err_raw),
        .disp_err       (disp_err_raw),
        .data_valid_out (decoded_valid)
    );

    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            rxdata      <= #`PCS_PD '0;
            rxdatak     <= #`PCS_PD '0;
            rx_valid    <= #`PCS_PD 1'b0;
            decode_err  <= #`PCS_PD 1'b0;
            disp_err    <= #`PCS_PD 1'b0;
        end else begin
            rx_valid    <= #`PCS_PD decoded_valid;

            if (decoded_valid) begin
                rxdata      <= #`PCS_PD decoded_rx_data;
                rxdatak     <= #`PCS_PD decoded_rx_datak;
                decode_err  <= #`PCS_PD decoded_err_raw;
                disp_err    <= #`PCS_PD disp_err_raw;
            end else begin
                decode_err  <= #`PCS_PD 1'b0;
                disp_err    <= #`PCS_PD 1'b0;
            end
        end
    end

endmodule

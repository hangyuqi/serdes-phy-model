module tx_path (
    input  logic        pclk,
    input  logic        serial_clk,
    input  logic        rst_n,
    input  logic [31:0] txdata,
    input  logic [3:0]  txdatak,
    input  logic        tx_valid,
    output logic [39:0] tx_code,
    output logic        tx_code_valid,
    output logic        serial_tx
);

    logic [39:0] encoded_tx_code;
    logic        encoded_tx_code_valid;

    // The copied codec wrapper already exposes a 32-bit to 40-bit interface.
    // Unused protocol / OOB controls are tied off for the first PCIe PHY model cut.
    enc_8b10b_4bytes u_encoder (
        .clk40              (pclk),
        .clk40_rst_n        (rst_n),
        .tx8b10ben          (1'b1),
        .din_bit_swp        (1'b0),
        .din_bytes_swp      (1'b0),
        .dout_bit_swp       (1'b0),
        .dout_bytes_swp     (1'b0),
        .pcs_lane_rate      (3'b000),
        .pcs_lane_protocol  (2'b00),
        .lane_tx_elecidle   (1'b0),
        .lane_tx_compliance (1'b0),
        .oob_mode           (1'b0),
        .din                (txdata),
        .din_k              (txdatak),
        .din_vld            (tx_valid),
        .run_disp_ctrl0     (4'b0000),
        .run_disp_ctrl1     (4'b0000),
        .dout               (encoded_tx_code),
        .dout_vld           (encoded_tx_code_valid)
    );

    assign tx_code       = encoded_tx_code;
    assign tx_code_valid = encoded_tx_code_valid;

    serializer #(
        .WIDTH(40)
    ) u_serializer (
        .serial_clk    (serial_clk),
        .rst_n         (rst_n),
        .parallel_data (tx_code),
        .serial_tx     (serial_tx)
    );

endmodule

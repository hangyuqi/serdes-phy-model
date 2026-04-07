module pcie_phy_model_top #(
    parameter realtime SERIAL_CLK_HALF_PERIOD = 200ps,
    parameter int  PCLK_DIV               = 40
) (
    input  logic        rst_n,
    input  logic        rate,
    input  logic [31:0] txdata,
    input  logic [3:0]  txdatak,
    input  logic        tx_valid,
    output logic [31:0] rxdata,
    output logic [3:0]  rxdatak,
    output logic        decode_err,
    output logic        disp_err,
    output logic [39:0] tx_code,
    output logic        serial_tx,
    output logic        pclk
);

    localparam int PCLK_DIV_W = (PCLK_DIV <= 1) ? 1 : $clog2(PCLK_DIV);

    logic                  serial_clk;
    logic [PCLK_DIV_W-1:0] pclk_div_count;
    logic                  tx_code_valid;
    logic                  rate_unused;

    assign rate_unused = rate;

    initial begin
        if ((PCLK_DIV < 2) || ((PCLK_DIV % 2) != 0)) begin
            $error("PCLK_DIV must be an even number greater than or equal to 2.");
        end

        serial_clk = 1'b0;
        forever #(SERIAL_CLK_HALF_PERIOD) serial_clk = ~serial_clk;
    end

    always_ff @(posedge serial_clk or negedge rst_n) begin
        if (!rst_n) begin
            // Make the first pclk rising edge happen on the first serial_clk edge
            // after reset release, then repeat every 40 serial clocks.
            pclk_div_count <= (PCLK_DIV / 2) - 1;
            pclk           <= 1'b0;
        end else if (pclk_div_count == (PCLK_DIV / 2) - 1) begin
            pclk_div_count <= '0;
            pclk           <= ~pclk;
        end else begin
            pclk_div_count <= pclk_div_count + 1'b1;
        end
    end

    tx_path u_tx_path (
        .pclk         (pclk),
        .serial_clk   (serial_clk),
        .rst_n        (rst_n),
        .txdata       (txdata),
        .txdatak      (txdatak),
        .tx_valid     (tx_valid),
        .tx_code      (tx_code),
        .tx_code_valid(tx_code_valid),
        .serial_tx    (serial_tx)
    );

    rx_path u_rx_path (
        .pclk         (pclk),
        .rst_n        (rst_n),
        .rx_code      (tx_code),
        .rx_code_valid(tx_code_valid),
        .rxdata       (rxdata),
        .rxdatak      (rxdatak),
        .decode_err   (decode_err),
        .disp_err     (disp_err)
    );

endmodule

module serializer #(
    parameter int WIDTH = 40
) (
    input  logic             serial_clk,
    input  logic             rst_n,
    input  logic [WIDTH-1:0] parallel_data,
    input  logic             data_valid,
    output logic             serial_tx
);

    localparam int BIT_CNT_W = (WIDTH <= 1) ? 1 : $clog2(WIDTH);

    logic [WIDTH-1:0]     shift_reg;
    logic [BIT_CNT_W-1:0] bit_count;
    logic                 tx_active;

    assign serial_tx = shift_reg[WIDTH-1];

    always_ff @(posedge serial_clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= '0;
            bit_count <= '0;
            tx_active <= 1'b0;
        end else if (!tx_active) begin
            // Stay idle until valid encoded data arrives
            if (data_valid) begin
                shift_reg <= parallel_data;
                bit_count <= '0;
                tx_active <= 1'b1;
            end
        end else if (bit_count == WIDTH - 1) begin
            // Load a new 40-bit code word and start shifting out from MSB.
            shift_reg <= parallel_data;
            bit_count <= '0;
        end else begin
            shift_reg <= {shift_reg[WIDTH-2:0], 1'b0};
            bit_count <= bit_count + 1'b1;
        end
    end

endmodule

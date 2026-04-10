module deserializer #(
    parameter int WIDTH = 40
) (
    input  logic             serial_clk,
    input  logic             pclk,
    input  logic             rst_n,
    input  logic             serial_rx,
    output logic [WIDTH-1:0] parallel_data
);

    logic [WIDTH-1:0] shift_reg;
    logic [WIDTH-1:0] parallel_data_tmp;
    logic             pclk_d;
    logic             frame_done;

    // Detect pclk rising edge in serial_clk domain
    always_ff @(posedge serial_clk or negedge rst_n) begin
        if (!rst_n)
            pclk_d <= 1'b0;
        else
            pclk_d <= pclk;
    end

    assign frame_done = pclk & ~pclk_d;

    // Free-running shift register: always shifting after reset
    always_ff @(posedge serial_clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= '0;
        else
            shift_reg <= {shift_reg[WIDTH-2:0], serial_rx};
    end

    // Snapshot shift register at pclk rising edge (serial_clk domain)
    always_ff @(posedge serial_clk or negedge rst_n) begin
        if (!rst_n)
            parallel_data_tmp <= '0;
        else if (frame_done)
            parallel_data_tmp <= {shift_reg[WIDTH-2:0], serial_rx};
    end

    // Transfer to pclk domain
    always_ff @(posedge pclk or negedge rst_n) begin
        if (!rst_n)
            parallel_data <= #`PCS_PD '0;
        else
            parallel_data <= #`PCS_PD parallel_data_tmp;
    end

endmodule

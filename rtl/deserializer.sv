module deserializer #(
    parameter int WIDTH = 40
) (
    input  logic             serial_clk,
    input  logic             pclk,
    input  logic             rst_n,
    input  logic             serial_rx,
    output logic [WIDTH-1:0] parallel_data,
    output logic             data_valid
);

    logic [WIDTH-1:0] shift_reg;
    logic             pclk_d;
    logic             frame_done;

    // Detect pclk rising edge in serial_clk domain (1-cycle latency).
    // This aligns the capture to the serializer's frame boundary:
    //   pclk rises at serial_clk edge N  -> serializer loads new data
    //   serial_clk edge N+1              -> first serial bit available
    //   serial_clk edge N+2              -> frame_done fires, captures previous frame
    always_ff @(posedge serial_clk or negedge rst_n) begin
        if (!rst_n)
            pclk_d <= 1'b0;
        else
            pclk_d <= pclk;
    end

    assign frame_done = pclk & ~pclk_d;

    // Free-running shift register: shift in serial_rx on every serial_clk
    always_ff @(posedge serial_clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= '0;
        else
            shift_reg <= {shift_reg[WIDTH-2:0], serial_rx};
    end

    // Capture parallel data on frame boundary and hold until next frame.
    // data_valid deasserts for all-zero frames (idle line).
    always_ff @(posedge serial_clk or negedge rst_n) begin
        if (!rst_n) begin
            parallel_data <= '0;
            data_valid    <= 1'b0;
        end else if (frame_done) begin
            parallel_data <= {shift_reg[WIDTH-2:0], serial_rx};
            data_valid    <= |{shift_reg[WIDTH-2:0], serial_rx};
        end
    end

endmodule

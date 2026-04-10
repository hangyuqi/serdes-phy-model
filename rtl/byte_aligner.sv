module byte_aligner (
    input  logic        pclk,
    input  logic        rst_n,
    input  logic [39:0] data_in,
    output logic [39:0] data_out,
    output logic        aligned
);

    // K28.5 (COM) 8b10b encoded patterns
    // K28.5 RD-: abcdei=001111 fghj=1010
    // K28.5 RD+: abcdei=110000 fghj=0101
    localparam logic [9:0] COM_RDN = 10'b0011111010;
    localparam logic [9:0] COM_RDP = 10'b1100000101;

    logic [39:0] data_prev;
    logic [79:0] data_cat;
    logic [3:0]  bit_offset;
    logic        locked;

    // {prev, curr} forms an 80-bit window covering two consecutive frames
    // data_cat[0]  = data_in[0]  = newest bit
    // data_cat[79] = data_prev[39] = oldest bit
    assign data_cat = {data_prev, data_in};

    // Buffer previous frame
    always_ff @(posedge pclk or negedge rst_n) begin
        if (!rst_n)
            data_prev <= #`PCS_PD '0;
        else
            data_prev <= #`PCS_PD data_in;
    end

    // ---------------------------------------------------------------
    // COM pattern detection at each of 10 possible bit offsets
    // For offset k, the 4 symbol positions are:
    //   sym0 = data_cat[k +: 10]
    //   sym1 = data_cat[k+10 +: 10]
    //   sym2 = data_cat[k+20 +: 10]
    //   sym3 = data_cat[k+30 +: 10]
    // ---------------------------------------------------------------
    logic [9:0] com_match;

    genvar k;
    generate
        for (k = 0; k < 10; k++) begin : g_com_detect
            logic [9:0] sym0, sym1, sym2, sym3;
            assign sym0 = data_cat[k      +: 10];
            assign sym1 = data_cat[k + 10 +: 10];
            assign sym2 = data_cat[k + 20 +: 10];
            assign sym3 = data_cat[k + 30 +: 10];

            assign com_match[k] = (sym0 == COM_RDN) | (sym0 == COM_RDP) |
                                  (sym1 == COM_RDN) | (sym1 == COM_RDP) |
                                  (sym2 == COM_RDN) | (sym2 == COM_RDP) |
                                  (sym3 == COM_RDN) | (sym3 == COM_RDP);
        end
    endgenerate

    // Priority encoder: select lowest matching offset
    logic [3:0] detected_offset;
    logic       com_detected;

    always_comb begin
        detected_offset = '0;
        com_detected    = 1'b0;
        for (int i = 0; i < 10; i++) begin
            if (com_match[i] && !com_detected) begin
                detected_offset = i[3:0];
                com_detected    = 1'b1;
            end
        end
    end

    // Lock alignment on first COM detection
    always_ff @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            bit_offset <= #`PCS_PD '0;
            locked     <= #`PCS_PD 1'b0;
        end else if (!locked && com_detected) begin
            bit_offset <= #`PCS_PD detected_offset;
            locked     <= #`PCS_PD 1'b1;
        end
    end

    // First detection uses combinational detected_offset (bit_offset not yet registered);
    // subsequent cycles use the locked bit_offset.
    logic [3:0] active_offset;
    assign active_offset = locked ? bit_offset : detected_offset;

    // Registered output: data_out and aligned sample the pre-edge data_cat,
    // so the first aligned output corresponds to the frame where COM was found.
    always_ff @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= #`PCS_PD '0;
            aligned  <= #`PCS_PD 1'b0;
        end else if (locked || com_detected) begin
            data_out <= #`PCS_PD data_cat[active_offset +: 40];
            aligned  <= #`PCS_PD 1'b1;
        end
    end

endmodule

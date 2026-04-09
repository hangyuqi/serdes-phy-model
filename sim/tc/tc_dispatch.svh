// Auto-generated from tc/*.sv — do not edit
`include "smoke_test.sv"
`include "ts1_rx_decode_test.sv"
`include "ts1_single_word_loopback_test.sv"
`include "ts1_tx_test.sv"

task run_testcase();
    case (tc_name)
        "smoke_test": smoke_test();
        "ts1_rx_decode_test": ts1_rx_decode_test();
        "ts1_single_word_loopback_test": ts1_single_word_loopback_test();
        "ts1_tx_test": ts1_tx_test();
        default: begin
            $display("[ERROR] Unknown testcase: %s", tc_name);
            err_count++;
        end
    endcase
endtask

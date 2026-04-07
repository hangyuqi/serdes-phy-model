// Auto-generated from tc/*.sv — do not edit
`include "smoke_test.sv"
`include "ts1_tx_test.sv"

task run_testcase(string name);
    case (name)
        "smoke_test": smoke_test();
        "ts1_tx_test": ts1_tx_test();
        default: begin
            $display("[ERROR] Unknown testcase: %s", name);
            err_count++;
        end
    endcase
endtask

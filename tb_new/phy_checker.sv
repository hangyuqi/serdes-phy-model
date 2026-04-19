class phy_checker;
    phy_trans exp_queue[$];
    int match_cnt, err_cnt;

    function new();
        match_cnt = 0;
        err_cnt = 0;
    endfunction

    function void report();
        $display("\n===================================================");
        $display("                   TEST REPORT                     ");
        $display("===================================================");
        $display(" Matches Found : %0d", match_cnt);
        $display(" Errors Found  : %0d", err_cnt);
        if(err_cnt == 0 && match_cnt > 0)
            $display(" RESULT        : [\033[32m PASSED \033[0m]"); 
        else
            $display(" RESULT        : [\033[31m FAILED \033[0m]"); 
        $display("===================================================\n");
    endfunction
endclass
// 包含头文件路径
+incdir+./env
+incdir+../rtl
+incdir+./tc

// 验证环境文件
./env/phy_if.sv
./env/phy_trans.sv
./env/pcie_ts_pkt.sv
./env/phy_checker.sv
./env/base_test.sv

// 测试用例文件
./tc/test_random_payload.sv
./tc/test_ts_loopback.sv

// 验证顶层
./env/tb_top.sv
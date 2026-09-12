set_property PACKAGE_PIN Y18 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -name gclk1 -period 20.000 [get_ports clk]

set_property PACKAGE_PIN F20 [get_ports resetn]
set_property IOSTANDARD LVCMOS33 [get_ports resetn]

# seg_dig[7:0] = {DP, G, F, E, D, C, B, A} 
set_property PACKAGE_PIN J5 [get_ports {seg_dig[0]}] 
set_property PACKAGE_PIN M3 [get_ports {seg_dig[1]}] 
set_property PACKAGE_PIN J6 [get_ports {seg_dig[2]}] 
set_property PACKAGE_PIN H5 [get_ports {seg_dig[3]}] 
set_property PACKAGE_PIN G4 [get_ports {seg_dig[4]}] 
set_property PACKAGE_PIN K6 [get_ports {seg_dig[5]}] 
set_property PACKAGE_PIN K3 [get_ports {seg_dig[6]}] 
set_property PACKAGE_PIN H4 [get_ports {seg_dig[7]}] 

set_property IOSTANDARD LVCMOS33 [get_ports {seg_dig[*]}]

set_property PACKAGE_PIN M2  [get_ports {seg_sel[0]}] 
set_property PACKAGE_PIN N4  [get_ports {seg_sel[1]}] 
set_property PACKAGE_PIN L5  [get_ports {seg_sel[2]}] 
set_property PACKAGE_PIN L4  [get_ports {seg_sel[3]}] 
set_property PACKAGE_PIN M16 [get_ports {seg_sel[4]}] 
set_property PACKAGE_PIN M17 [get_ports {seg_sel[5]}] 

set_property IOSTANDARD LVCMOS33 [get_ports {seg_sel[*]}]

set_property PACKAGE_PIN F19 [get_ports {led[0]}]
set_property PACKAGE_PIN E21 [get_ports {led[1]}]
set_property PACKAGE_PIN D20 [get_ports {led[2]}]
set_property PACKAGE_PIN C20 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports rx]
set_property PACKAGE_PIN G15 [get_ports rx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]
set_property PACKAGE_PIN G16 [get_ports tx]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

set_property -dict {PACKAGE_PIN R4 IOSTANDARD DIFF_SSTL15} [get_ports clk200_p]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD DIFF_SSTL15} [get_ports clk200_n]
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports auxch_in]
set_property -dict {PACKAGE_PIN AB16 IOSTANDARD LVCMOS33} [get_ports auxch_out]
set_property -dict {PACKAGE_PIN AB17 IOSTANDARD LVCMOS33} [get_ports auxch_tri]
set_property -dict {PACKAGE_PIN Y14 IOSTANDARD LVCMOS33} [get_ports dp_tx_hp_detect]

set_property -dict {PACKAGE_PIN J21 IOSTANDARD LVCMOS33} [get_ports resetn]

set_property -dict {PACKAGE_PIN F6} [get_ports dp_refclk_p]
set_property -dict {PACKAGE_PIN E6} [get_ports dp_refclk_n]
set_property -dict {PACKAGE_PIN F10} [get_ports mgtrefclk1_p]
set_property -dict {PACKAGE_PIN E10} [get_ports mgtrefclk1_n]

set_property -dict {PACKAGE_PIN D5} [get_ports {dp_tx_lane_p[0]}]
set_property -dict {PACKAGE_PIN C5} [get_ports {dp_tx_lane_n[0]}]

set_property -dict {PACKAGE_PIN B4} [get_ports {dp_tx_lane_p[1]}]
set_property -dict {PACKAGE_PIN A4} [get_ports {dp_tx_lane_n[1]}]

set_property -dict {PACKAGE_PIN B6} [get_ports {dp_tx_lane_p[2]}]
set_property -dict {PACKAGE_PIN A6} [get_ports {dp_tx_lane_n[2]}]

set_property -dict {PACKAGE_PIN D7} [get_ports {dp_tx_lane_p[3]}]
set_property -dict {PACKAGE_PIN C7} [get_ports {dp_tx_lane_n[3]}]

set_property -dict {PACKAGE_PIN B13 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS33} [get_ports {LED[3]}]
##Clock Signal

set_property CFGBVS VCCO [current_design]

##Display Port
#set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVDS_25} [get_ports dp_tx_auxch_tx_p]
#set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVDS_25} [get_ports dp_tx_auxch_tx_n]

#set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVDS_25} [get_ports dp_tx_auxch_rx_p]
#set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVDS_25} [get_ports dp_tx_auxch_rx_n]



## The below match AC7100
















#create_clock -period 7.407 -name i_tx0/I -waveform {0.000 3.704} [get_pins i_tx0/gtpe2_i/TXOUTCLK]
#create_clock -period 7.407 -name i_tx0/ref_clk -waveform {0.000 3.704} [get_pins i_tx0/gtpe2_i/TXOUTCLKFABRIC]



create_clock -period 5.000 -name sys_clk_pin -waveform {0.000 2.500} -add [get_ports clk200_p]

create_clock -period 7.407 -name dp_refclk -waveform {0.000 3.704} -add [get_ports dp_refclk_p]
create_clock -period 7.407 -name dp_refclk2 -waveform {0.000 3.704} -add [get_ports mgtrefclk1_p]



#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets clk100_BUFG]




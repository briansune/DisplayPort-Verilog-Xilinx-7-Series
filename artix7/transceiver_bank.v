///////////////////////////////////////////////////////////////////////////////
// ./src/artix7/transceiver_bank.v : 
//
// Author: Mike Field <hamster@snap.net.nz>
//
// Part of the DisplayPort_Verlog project - an open implementation of the 
// DisplayPort protocol for FPGA boards. 
//
// See https://github.com/hamsternz/DisplayPort_Verilog for latest versions.
//
///////////////////////////////////////////////////////////////////////////////
// Version |  Notes
// ----------------------------------------------------------------------------
//   1.0   | Initial Release
//
///////////////////////////////////////////////////////////////////////////////
//
// MIT License
// 
// Copyright (c) 2019 Mike Field
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
///////////////////////////////////////////////////////////////////////////////
//
// Want to say thanks?
//
// This design has taken many hours - 3 months of work for the initial VHDL
// design, and another month or so to convert it to Verilog for this release.
//
// I'm more than happy to share it if you can make use of it. It is released
// under the MIT license, so you are not under any onus to say thanks, but....
//
// If you what to say thanks for this design either drop me an email, or how about
// trying PayPal to my email (hamster@snap.net.nz)?
//
//  Educational use - Enough for a beer
//  Hobbyist use    - Enough for a pizza
//  Research use    - Enough to take the family out to dinner
//  Commercial use  - A weeks pay for an engineer (I wish!)
//
///////////////////////////////////////////////////////////////////////////////
module transceiver_bank#(
	parameter integer lane_act = 2
)(

	input  wire                         mgmt_clk,

	input  wire    [1:0]                powerup_channel,

	input  wire                         preemp_0p0,
	input  wire                         preemp_3p5,
	input  wire                         preemp_6p0,

	input  wire                         swing_0p4,
	input  wire                         swing_0p6,
	input  wire                         swing_0p8,

	output wire    [3:0]                tx_running,

	input  wire                         refclk0,
	input  wire                         refclk1,

	output wire                         tx_symbol_clk,
	input  wire    [20*lane_act-1:0]    tx_symbols,

	output wire    [lane_act-1:0]       gtptx_p,
	output wire    [lane_act-1:0]       gtptx_n
);

    wire       pll0lock;
    reg  [4:0] preemp_level;
    reg  [3:0] swing_level;

    localparam PLL0_FBDIV_IN      = 4;
    localparam PLL1_FBDIV_IN      = 1;
	
    localparam PLL0_FBDIV_45_IN   = 5;
    localparam PLL1_FBDIV_45_IN   = 4;
	
    localparam PLL0_REFCLK_DIV_IN = 1;
    localparam PLL1_REFCLK_DIV_IN = 1;
    
    wire       pll0clk;
    wire       pll0refclk;
	
    wire       pll1clk;
    wire       pll1refclk;

	wire [lane_act-1:0] pll_locken;
    wire [lane_act-1:0] tx_out_clk;
	
    wire [lane_act-1:0] pll_pd;
    wire [lane_act-1:0] pll_reset;
    
    wire       tx_symbol_clk_i;

    assign tx_symbol_clk = tx_symbol_clk_i;

    wire  [7:0] ignore_dmonitorout;
    wire [15:0] ignore_drpdo;
    wire        ignore_drprdy;
    wire        ignore_pll0fbclklost;
    wire        ignore_pll0refclklost;
    wire        ignore_pll1fbclklost;
    wire        ignore_pll1lock;
    wire        ignore_pll1refclklost;
    wire        ignore_refclkoutmonitor0;
    wire        ignore_refclkoutmonitor1;
    wire [15:0] ignore_pmarsvdout;

	BUFG i_bufg(
		.I (tx_out_clk[0]),
		.O (tx_symbol_clk_i)
	);

	always @(*) begin    
		if(preemp_6p0  == 1'b1) begin
			preemp_level = 5'b10100;   // 6.02 dB
		end else if(preemp_3p5 == 1'b1) begin
			preemp_level = 5'b01110;   // 3.74 dB
		end else if(preemp_0p0 == 1'b1) begin
			preemp_level = 5'b00000;   // 0.0 dB
		end else begin
			preemp_level = 5'b00001;   // 0.22 dB
		end
		
		if(swing_0p8 == 1'b1) begin
			swing_level  = 4'b1000;      // 0.807 V
		end else if(swing_0p6 == 1'b1) begin
			swing_level  = 4'b0101;      // 0.609 V
		end else if(swing_0p4 == 1'b1) begin
			swing_level  = 4'b0010;      // 0.407 V
		end else begin
			swing_level  = 4'b0000;      // 0.269 V
		end
	end

	GTPE2_COMMON #(
        .PLL0_FBDIV           (PLL0_FBDIV_IN),	
        .PLL0_FBDIV_45        (PLL0_FBDIV_45_IN),	
        .PLL0_REFCLK_DIV      (PLL0_REFCLK_DIV_IN),	
        .PLL1_FBDIV           (PLL1_FBDIV_IN),
        .PLL1_FBDIV_45        (PLL1_FBDIV_45_IN),	
        .PLL1_REFCLK_DIV      (PLL1_REFCLK_DIV_IN),	            


       //----------------COMMON BLOCK Attributes---------------
        .BIAS_CFG                                (64'h0000000000050001),
        .COMMON_CFG                              (32'h00000000),

       //--------------------------PLL Attributes----------------------------
        .PLL0_CFG                                (28'h01F03DC),
        .PLL0_DMON_CFG                           (1'b0),
        .PLL0_INIT_CFG                           (24'h00001E),
        .PLL0_LOCK_CFG                           (12'h1E8),
        .PLL1_CFG                                (28'h01F03DC),
        .PLL1_DMON_CFG                           (1'b0),
        .PLL1_INIT_CFG                           (24'h00001E),
        .PLL1_LOCK_CFG                           (12'h1E8),
        .PLL_CLKOUT_CFG                          (8'h00),

        //---------------------------Reserved Attributes----------------------------
        .RSVD_ATTR0                              (16'h0000),
        .RSVD_ATTR1                              (16'h0000))
    i_gtpe2_common
    (
        .DMONITOROUT                     (ignore_dmonitorout),	
        //----------- Common Block  - Dynamic Reconfiguration Port (DRP) -----------
        .DRPADDR                         (8'b00000000),
        .DRPCLK                          (1'b0),
        .DRPDI                           (16'h0000),
        .DRPDO                           (ignore_drpdo),
        .DRPEN                           (1'b0),
        .DRPRDY                          (ignore_drprdy),
        .DRPWE                           (1'b0),
        //--------------- Common Block - GTPE2_COMMON Clocking Ports ---------------
        .GTEASTREFCLK0                   (1'b0),
        .GTEASTREFCLK1                   (1'b0),
        .GTGREFCLK1                      (1'b0),
        .GTREFCLK0                       (refclk0),
        .GTREFCLK1                       (refclk1),
        .GTWESTREFCLK0                   (1'b0),
        .GTWESTREFCLK1                   (1'b0),
        .PLL0OUTCLK                      (pll0clk),
        .PLL0OUTREFCLK                   (pll0refclk),
        .PLL1OUTCLK                      (pll1clk),
        .PLL1OUTREFCLK                   (pll1refclk),
        //------------------------ Common Block - PLL Ports ------------------------
        .PLL0FBCLKLOST                   (ignore_pll0fbclklost),
        .PLL0LOCK                        (pll0lock),
        .PLL0LOCKDETCLK                  (mgmt_clk),
        .PLL0LOCKEN                      (1'b1),
        .PLL0PD                          (pll_pd[0]),
        .PLL0REFCLKLOST                  (ignore_pll0refclklost),
        .PLL0REFCLKSEL                   (3'b001),  // ref clock 0
        .PLL0RESET                       (pll_reset[0]),
        .PLL1FBCLKLOST                   (ignore_pll1fbclklost),
        .PLL1LOCK                        (ignore_pll1lock),
        .PLL1LOCKDETCLK                  (1'b0),
        .PLL1LOCKEN                      (1'b1),
        .PLL1PD                          (1'b1),
        .PLL1REFCLKLOST                  (ignore_pll1refclklost),
        .PLL1REFCLKSEL                   (3'b001),
        .PLL1RESET                       (1'b0),
        //-------------------------- Common Block - Ports --------------------------
        .BGRCALOVRDENB                   (1'b1),
        .GTGREFCLK0                      (1'b0),
        .PLLRSVD1                        (16'b0000000000000000),
        .PLLRSVD2                        (5'b00000),
        .REFCLKOUTMONITOR0               (ignore_refclkoutmonitor0),
        .REFCLKOUTMONITOR1               (ignore_refclkoutmonitor1),
         //---------------------- Common Block - RX AFE Ports -----------------------
        .PMARSVDOUT                      (ignore_pmarsvdout),
         //------------------------------- QPLL Ports -------------------------------
        .BGBYPASSB                       (1'b1),
        .BGMONITORENB                    (1'b1),
        .BGPDB                           (1'b1),
        .BGRCALOVRD                      (5'b11111),
        .PMARSVD                         (8'b00000000),
        .RCALENB                         (1'b1)
    );

	reg	[3:0]	pwr_gtx;

	always@(*)begin
		case(powerup_channel)
			2'd0: pwr_gtx = 4'b0000;
			2'd1: pwr_gtx = 4'b0001;
			2'd2: pwr_gtx = 4'b0011;
			2'd3: pwr_gtx = 4'b1111;
		endcase
	end

	genvar i;

	generate
		for(i=0;i<4;i=i+1)begin
			if(i < lane_act)begin : lane_active
				transceiver tx(
					.mgmt_clk        (mgmt_clk),
					.powerup_channel (pwr_gtx[i]),

					.preemp_level    (preemp_level),
					.swing_level     (swing_level),

					.tx_running      (tx_running[i]),

					.pll0clk         (pll0clk),
					.pll0refclk      (pll0refclk),
					.pll1clk         (pll1clk),
					.pll1refclk      (pll1refclk),

					.pll_pd          (pll_pd[i]),
					.pll_reset       (pll_reset[i]),
					.pll_locken      (pll_locken[i]),
					.pll_lock        (pll0lock),

					.tx_out_clk      (tx_out_clk[i]),

					.tx_symbol_clk   (tx_symbol_clk_i),
					.tx_symbol       (tx_symbols[i*20+:20]),

					.gtptx_p         (gtptx_p[i]),
					.gtptx_n         (gtptx_n[i])
				);
			end else begin : lane_disable
				assign tx_running[i] = 1'b0;
			end
		end
	endgenerate

endmodule

// =======================================================================
//                     CODE LICENSE (Header Required)                
// =======================================================================
// Copyright (c) [2026] BrianSune. All rights reserved.              
//                                                                  
// Redistribution and use in source and binary forms, with or        
// without modification, are permitted provided that the following   
// conditions are met:                                               
//                                                                  
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions, and the following disclaimer.
//                                                                  
// 2. Redistributions in binary form must reproduce the above       
//    copyright notice, this list of conditions, and the disclaimer  
//    below in the documentation and/or other materials provided    
//    with the distribution.                                         
//                                                                  
// 3. All copies must include this license document in its entirety,
//    unmodified, alongside the original copyright header.          
//                                                                  
// DISCLAIMER:                                                      
// THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED      
// WARRANTIES, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR   
// PURPOSE, OR NON-INFRINGEMENT, ARE DISCLAIMED. IN NO EVENT SHALL  
// BRIANSUNE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,        
// SPECIAL, OR CONSEQUENTIAL DAMAGES.                      
// =======================================================================
//  ____         _                ____                      
// | __ )  _ __ (_)  __ _  _ __  / ___|  _   _  _ __    ___ 
// |  _ \ | '__|| | / _` || '_ \ \___ \ | | | || '_ \  / _ \
// | |_) || |   | || (_| || | | | ___) || |_| || | | ||  __/
// |____/ |_|   |_| \__,_||_| |_||____/  \__,_||_| |_| \___|
//                                                          
// =======================================================================
// Revision: 0.9.1
// Date: 2026/03/22
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Initial Release
// Reference: Mike Field <hamster@snap.net.nz> DP Verilog Project
// =======================================================================
// HDL File: skew_channels.v
// =======================================================================
// Programed By: BrianSune
// Contact: briansune@gmail.com
// =======================================================================

`timescale 1ns / 1ps

module top_level_ac7100#(
	parameter integer dp_lane = 4
)(

	input  wire                     clk200_p,
	input  wire                     clk200_n,

	input  wire                     resetn,

	output wire    [dp_lane-1:0]    dp_tx_lane_p,
	output wire    [dp_lane-1:0]    dp_tx_lane_n,

	input  wire                     dp_refclk_p,
	input  wire                     dp_refclk_n,

	input  wire                     mgtrefclk1_p,
	input  wire                     mgtrefclk1_n,

	input  wire                     dp_tx_hp_detect,

	input  wire                     auxch_in,
	output wire                     auxch_tri,
	output wire                     auxch_out,

	output wire    [3:0]            LED
);


wire      refclk0, odiv2_0;
wire      refclk1, odiv2_1;

wire [1:0] tx_powerup_channel;

wire       preemp_0p0;
wire       preemp_3p5;
wire       preemp_6p0;

wire       swing_0p4;
wire       swing_0p6;
wire       swing_0p8;

wire  [3:0] tx_running;

wire        tx_symbol_clk;
wire [79:0] tx_symbols;

wire        tx_align_train;       
wire        tx_clock_train;       
wire        tx_link_established;

wire  [2:0] stream_channel_count;

wire [72:0] msa_merged_data;
wire        test_signal_ready;


wire	clk200_se;
wire	clk100;
wire	MMCM_FB;
wire	mmc_lock;

IBUFDS #(
      .DIFF_TERM("FALSE"),       // Differential Termination
      .IBUF_LOW_PWR("FALSE"),     // Low power="TRUE", Highest performance="FALSE" 
      .IOSTANDARD("DEFAULT")     // Specify the input I/O standard
   ) IBUFDS_inst (
      .O(clk200_se),  // Buffer output
      .I(clk200_p),  // Diff_p buffer input (connect directly to top-level port)
      .IB(clk200_n) // Diff_n buffer input (connect directly to top-level port)
   );

MMCME2_BASE #(
      .BANDWIDTH("OPTIMIZED"),   // Jitter programming (OPTIMIZED, HIGH, LOW)
      .CLKFBOUT_MULT_F(4.0),     // Multiply value for all CLKOUT (2.000-64.000).
      .CLKFBOUT_PHASE(0.0),      // Phase offset in degrees of CLKFB (-360.000-360.000).
      .CLKIN1_PERIOD(5.0),       // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
      .CLKOUT1_DIVIDE(1),
      .CLKOUT2_DIVIDE(1),
      .CLKOUT3_DIVIDE(1),
      .CLKOUT4_DIVIDE(1),
      .CLKOUT5_DIVIDE(1),
      .CLKOUT6_DIVIDE(1),
      .CLKOUT0_DIVIDE_F(8.0),    // Divide amount for CLKOUT0 (1.000-128.000).
      // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT3_DUTY_CYCLE(0.5),
      .CLKOUT4_DUTY_CYCLE(0.5),
      .CLKOUT5_DUTY_CYCLE(0.5),
      .CLKOUT6_DUTY_CYCLE(0.5),
      // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      .CLKOUT0_PHASE(0.0),
      .CLKOUT1_PHASE(0.0),
      .CLKOUT2_PHASE(0.0),
      .CLKOUT3_PHASE(0.0),
      .CLKOUT4_PHASE(0.0),
      .CLKOUT5_PHASE(0.0),
      .CLKOUT6_PHASE(0.0),
      .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
      .DIVCLK_DIVIDE(1),         // Master division value (1-106)
      .REF_JITTER1(0.0),         // Reference input jitter in UI (0.000-0.999).
      .STARTUP_WAIT("FALSE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
   )
   MMCME2_BASE_inst (
      // Clock Outputs: 1-bit (each) output: User configurable clock outputs
      .CLKOUT0(clk100),     // 1-bit output: CLKOUT0
      .CLKOUT0B(),   // 1-bit output: Inverted CLKOUT0
      .CLKOUT1(),     // 1-bit output: CLKOUT1
      .CLKOUT1B(),   // 1-bit output: Inverted CLKOUT1
      .CLKOUT2(),     // 1-bit output: CLKOUT2
      .CLKOUT2B(),   // 1-bit output: Inverted CLKOUT2
      .CLKOUT3(),     // 1-bit output: CLKOUT3
      .CLKOUT3B(),   // 1-bit output: Inverted CLKOUT3
      .CLKOUT4(),     // 1-bit output: CLKOUT4
      .CLKOUT5(),     // 1-bit output: CLKOUT5
      .CLKOUT6(),     // 1-bit output: CLKOUT6
      // Feedback Clocks: 1-bit (each) output: Clock feedback ports
      .CLKFBOUT(MMCM_FB),   // 1-bit output: Feedback clock
      .CLKFBOUTB(), // 1-bit output: Inverted CLKFBOUT
      // Status Ports: 1-bit (each) output: MMCM status ports
      .LOCKED(mmc_lock),       // 1-bit output: LOCK
      // Clock Inputs: 1-bit (each) input: Clock input
      .CLKIN1(clk200_se),       // 1-bit input: Clock
      // Control Ports: 1-bit (each) input: MMCM control ports
      .PWRDWN(1'b0),       // 1-bit input: Power-down
      .RST(~resetn),             // 1-bit input: Reset
      // Feedback Clocks: 1-bit (each) input: Clock feedback ports
      .CLKFBIN(MMCM_FB)      // 1-bit input: Feedback clock
);

	///////////////////////////////////////////////////
	// Refclock buffers
	///////////////////////////////////////////////////
	IBUFDS_GTE2  ibufds_gte2_0 ( 
		.O               (refclk0),
		.ODIV2           (odiv2_0),
		.CEB             (1'b0),
		.I               (dp_refclk_p),
		.IB              (dp_refclk_n)
	);

	IBUFDS_GTE2  ibufds_gte2_1 ( 
		.O               (refclk1),
		.ODIV2           (odiv2_1),
		.CEB             (1'b0),
		.I               (mgtrefclk1_p),
		.IB              (mgtrefclk1_n)
	);

	///////////////////////////////////////////////////
	// Video pipeline
	///////////////////////////////////////////////////
	test_source i_test_source(
		.clk                  (tx_symbol_clk),
		.stream_channel_count (stream_channel_count),
		.ready                (test_signal_ready),
		.data                 (msa_merged_data)
	);
	main_stream_processing i_main_stream_processing(
		.symbol_clk          (tx_symbol_clk),
		.stream_channel_count (stream_channel_count),
		.tx_link_established (tx_link_established),
		.source_ready        (test_signal_ready),
		.tx_clock_train      (tx_clock_train),
		.tx_align_train      (tx_align_train),
		.in_data             (msa_merged_data),
		.tx_symbols          (tx_symbols)
	);

	////////////////////////////////////////////////
	// Transceivers 
	///////////////////////////////////////////////
	transceiver_bank#(
		.lane_act	(dp_lane)
	)i_transciever_bank(
		.mgmt_clk        (clk100),

		///////////////////////////////
		// Master control
		///////////////////////////////
		.powerup_channel (tx_powerup_channel),
	 
		///////////////////////////////
		// Output signal control
		///////////////////////////////
		.preemp_0p0      (preemp_0p0),
		.preemp_3p5      (preemp_3p5),
		.preemp_6p0      (preemp_6p0),

		.swing_0p4       (swing_0p4),
		.swing_0p6       (swing_0p6),
		.swing_0p8       (swing_0p8),

		///////////////////////////////
		// Status feedback
		///////////////////////////////
		.tx_running      (tx_running),

		///////////////////////////////
		// Reference clocks
		///////////////////////////////
		.refclk0       (refclk0),
		.refclk1       (refclk1),

		///////////////////////////////
		// Symbols to transmit
		///////////////////////////////
		.tx_symbol_clk   (tx_symbol_clk),
		.tx_symbols      (tx_symbols[0+:(20*dp_lane)]),

		.gtptx_p         (dp_tx_lane_p),
		.gtptx_n         (dp_tx_lane_n)
	);

	channel_management i_channel_management(

        .clk100               (clk100),
		
        .hpd                  (dp_tx_hp_detect),
        .auxch_in             (auxch_in & (~auxch_tri)),
        .auxch_out            (auxch_out),
        .auxch_tri            (auxch_tri),
        .stream_channel_count (stream_channel_count),
        .source_channel_count (dp_lane[2:0]),
        .tx_clock_train       (tx_clock_train),
        .tx_align_train       (tx_align_train),
        .tx_powerup_channel   (tx_powerup_channel),
        .tx_preemp_0p0        (preemp_0p0),
        .tx_preemp_3p5        (preemp_3p5),
        .tx_preemp_6p0        (preemp_6p0),
        .tx_swing_0p4         (swing_0p4),
        .tx_swing_0p6         (swing_0p6),
        .tx_swing_0p8         (swing_0p8),
        
        .tx_link_established  (tx_link_established)
    );
    
	reg [1:0] tx_lanes_run;
	
	always@(*)begin
		case(tx_running)
			4'b0001: tx_lanes_run = 2'b01;
			4'b0011: tx_lanes_run = 2'b10;
			4'b1111: tx_lanes_run = 2'b11;
			default: tx_lanes_run = 2'b00;
		endcase
	end
	
    assign LED = ~( {tx_lanes_run, tx_powerup_channel} & {4{mmc_lock}} );

endmodule

// =======================================================================
// End of File
// =======================================================================

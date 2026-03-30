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
// Revision: 0.9.0
// Date: 2019
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Initial Release
// Reference: Mike Field <hamster@snap.net.nz> DP Verilog Project
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Revision: 0.9.1
// Date: 2026/03/30
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Introduce parametric FPGA brand
// This parameter passed to sub-module and initialize the CCD MACROs
// =======================================================================
// HDL File: main_stream_processing.v
// =======================================================================
// Programed By: BrianSune
// Contact: briansune@gmail.com
// =======================================================================

`timescale 1ns / 1ps

module  main_stream_processing#(
	parameter fpga_family = ""
)(
	input  wire              symbol_clk,

	input  wire              tx_link_established,

	input  wire    [2:0]     stream_channel_count,

	input  wire              source_ready,

	input  wire              tx_clock_train,
	input  wire              tx_align_train,

	input  wire    [72:0]    in_data,
	output wire    [79:0]    tx_symbols
);

	wire [71:0] signal_data;
	wire [71:0] sr_inserted_data;
	wire [71:0] scrambled_data;
	wire [79:0] before_skew;
	wire [79:0] final_data;

	/////////////////////////////////////////////////////////
	// Flick between the idle pattern and a valid data stream
	// at the time when the in_data's high bit is set
	/////////////////////////////////////////////////////////
	idle_pattern_inserter#(
		.fpga_family	(fpga_family),
		.lane_num		(4)
	)i_idle_pattern_inserter( 
		.clk              (symbol_clk),
		.stream_channel_count    (stream_channel_count),
		.channel_ready    (tx_link_established),
		.source_ready     (source_ready),
		
		.in_data          (in_data),
		.out_data         (signal_data)
	);

	/////////////////////////////////////////////////////////
	// Change the 512th Blank Start (BS) symbol into a 
	// Scrambler Reset (SR) symbol
	/////////////////////////////////////////////////////////
	scrambler_reset_inserter i_scrambler_reset_inserter( 
		.clk       (symbol_clk),
		.in_data   (signal_data),
		.out_data  (sr_inserted_data)
	);

	/////////////////////////////////////////////////////////
	// Now scramble the data stream - only scrambles the data
	// symbols, the K symbols go through unscrambled.
	/////////////////////////////////////////////////////////
	scrambler_all_channels i_scrambler( 
		.clk        (symbol_clk),
		.bypass0    (1'b0),
		.bypass1    (1'b0),
		.in_data    (sr_inserted_data),
		.out_data   (scrambled_data)
	);

	/////////////////////////////////////////////////////////
	// This allows the controller to send the two training 
	// patterns, allowing the link drive levels to be set up
	/////////////////////////////////////////////////////////
	insert_training_pattern#(
		.fpga_family	(fpga_family)
	)i_insert_training_pattern(
		.clk               (symbol_clk),
		.clock_train       (tx_clock_train),
		.align_train       (tx_align_train), 
		///////////////////////////////////////////////////////
		// Adds one bit per symbol - the force_neg parity flag
		// This takes the 72-bit wide data word to 80 bits.
		///////////////////////////////////////////////////////
		.in_data           (scrambled_data),
		.out_data          (before_skew)
	);

	/////////////////////////////////////////////////////////
	// The last step is to skew the data channels (zero cycles
	// cycles for channel zero, two cycle for channel one, 
	// four for channel two and six for channel three.
	/////////////////////////////////////////////////////////
	skew_channels i_skew_channels(
		.clk               (symbol_clk),
		.in_data           (before_skew),
		.out_data          (tx_symbols)
	);

endmodule

// =======================================================================
// End of File
// =======================================================================

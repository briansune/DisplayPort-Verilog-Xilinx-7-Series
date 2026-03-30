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
// Date: 2026/03/21
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//	0.9.1	| introduce FPGA family CCD
// =======================================================================
// HDL File: insert_training_pattern.v
// =======================================================================
// Programed By: BrianSune
// Contact: briansune@gmail.com
// =======================================================================

`timescale 1ns / 1ps

module  insert_training_pattern#(
	parameter fpga_family = ""
)(
	input  wire              clk,

	input  wire              clock_train,
	input  wire              align_train,

	input  wire    [71:0]    in_data,
	output wire    [79:0]    out_data
);

	////////////////////////////////////////////////////////
	//
	// This is designed so the change over from test patterns
	// to data stream happens seamlessly - e.g. the value for 
	// presented on data_in when clock_train and align_train
	// are both become zero is guaranteed to be sent
	//
	// +----+--------------------+--------------------+
	// |Word| Training pattern 1 | Training pattern 2 |
	// |    | Code  MSB    LSB   | Code   MSB     LSB |
	// +----+--------------------+-------------------+
	// |  0 | D10.2 1010101010   | K28.5- 0101111100  |
	// |  1 | D10.2 1010101010   | D11.6  0110001011  |
	// |  2 | D10.2 1010101010   | K28.5+ 1010000011  |
	// |  3 | D10.2 1010101010   | D11.6  0110001011  |
	// |  4 | D10.2 1010101010   | D10.2  1010101010  |
	// |  5 | D10.2 1010101010   | D10.2  1010101010  |
	// |  6 | D10.2 1010101010   | D10.2  1010101010  |
	// |  7 | D10.2 1010101010   | D10.2  1010101010  |
	// |  8 | D10.2 1010101010   | D10.2  1010101010  |
	// |  9 | D10.2 1010101010   | D10.2  1010101010  |
	// +----+--------------------+--------------------+
	// Patterns are transmitted LSB first.
	////////////////////////////////////////////////////////

	wire clock_train_w;
	wire align_train_w;

    reg	[2:0] state;
    reg	[9:0] hold_at_state_one = 10'b1111111111;
    reg	[79:0] delay_line [5:0];
    
	// bit 9 1 = K, 0 = D
    localparam [8:0] CODE_K28_5 = 9'b1_1011_1100; // 0xBC
    localparam [8:0] CODE_D11_6 = 9'b0_1100_1011; // 0xCB
    localparam [8:0] CODE_D10_2 = 9'b0_0100_1010; // 0x4A

    localparam [19:0] p0 = {1'b0, CODE_D11_6, 1'b1, CODE_K28_5};
    localparam [19:0] p1 = {1'b0, CODE_D11_6, 1'b0, CODE_K28_5};
    localparam [19:0] p2 = {1'b0, CODE_D10_2, 1'b0, CODE_D10_2};
    localparam [19:0] p3 = {1'b0, CODE_D10_2, 1'b0, CODE_D10_2};
    localparam [19:0] p4 = {1'b0, CODE_D10_2, 1'b0, CODE_D10_2};

    assign out_data = delay_line[5];
	
	generate
		if(fpga_family == "")begin : vlsi_init
			
			reg         clock_train_meta, clock_train_i;
			reg         align_train_meta, align_train_i;
			
			assign clock_train_w = clock_train_i;
			assign align_train_w = align_train_i;
			
			initial begin
				clock_train_meta  = 1'b0;
				clock_train_i     = 1'b0;
				align_train_meta  = 1'b0;
				align_train_i     = 1'b0;
			end
			
			// CCD
			always @(posedge clk) begin
				clock_train_meta <= clock_train;
				clock_train_i    <= clock_train_meta;
				align_train_meta <= align_train;
				align_train_i    <= align_train_meta;
			end
		end
	endgenerate
	
	generate
		if(fpga_family == "ALTERA_C5")begin : cyclone_v_fpga
			altera_std_synchronizer#(
				.depth		(3)
			)ccd_100to135_u0(
				.clk		(clk),
				.reset_n	(1'b1),
				.din		(clock_train),
				.dout		(clock_train_w)
			);
			
			altera_std_synchronizer#(
				.depth		(3)
			)ccd_100to135_u1(
				.clk		(clk),
				.reset_n	(1'b1),
				.din		(align_train),
				.dout		(align_train_w)
			);
		end
	endgenerate
	
	initial begin
		delay_line[0]     = 80'b0;
		delay_line[1]     = 80'b0;
		delay_line[2]     = 80'b0;
		delay_line[3]     = 80'b0;
		delay_line[4]     = 80'b0;
		delay_line[5]     = 80'b0;
	end

	always @(posedge clk) begin
	  // Move the delay line along 
		delay_line[5] <= delay_line[4];
		delay_line[4] <= delay_line[3];
		delay_line[3] <= delay_line[2];
		delay_line[2] <= delay_line[1];
		delay_line[1] <= delay_line[0];
		delay_line[0] <= { 1'b0, in_data[71:63], 1'b0, in_data[62:54],
						   1'b0, in_data[53:45], 1'b0, in_data[44:36],
						   1'b0, in_data[35:27], 1'b0, in_data[26:18],
						   1'b0, in_data[17:9],  1'b0, in_data[8:0]};

		// Do we need to hold at state 1 until valid data has filtered down the delay line?
		if(align_train_w == 1'b1 ||  clock_train_w == 1'b1) begin
		   hold_at_state_one <= 10'b1111111111;
		end else begin
		   hold_at_state_one <= {1'b0, hold_at_state_one[9:1] };
		end

		// Do we need to overwrite the data in slot 5 with the sync patterns?
		case(state)
			3'b101: begin
				state <= 3'b100; 
				delay_line[5] <= {4{p0}};
			end

			3'b100: begin
				state <= 3'b011;
				delay_line[5] <= {4{p1}};
			end

			3'b011: begin 
				state <= 3'b010;
				delay_line[5] <= {4{p2}};
			end

			3'b010: begin
				state <= 3'b001;
				delay_line[5] <= {4{p3}};
			end

			3'b001: begin
				state <= 3'b000; 
				delay_line[5] <= {4{p4}};
				
				if(align_train_w == 1'b1) begin
					state <= 3'b101;
				end else if(hold_at_state_one[0] == 1'b1) begin
					state <= 3'b001;
				end
			end

			default: begin
						state <= 3'b000;
						if(align_train_w == 1'b1) begin
							state <= 3'b101;
						end else if(hold_at_state_one[0] == 1'b1) begin
							state <= 3'b001;
						end
					end
		endcase
end

endmodule

// =======================================================================
// End of File
// =======================================================================

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
// =======================================================================
// VESA DisplayPort (DP) Standard 2.0
// E HBRx/RBR Scrambler C Code
// Reference (Informative)
// =======================================================================
// HDL File: scrambler_all_channels.v
// =======================================================================
// Programed By: BrianSune
// Contact: briansune@gmail.com
// =======================================================================

`timescale 1ns / 1ps

module scrambler_all_channels#(
	parameter integer DP_eDP = 0
)(

	input  wire               clk,

	input  wire               bypass0,
	input  wire               bypass1,

	input  wire    [71:0]     in_data,
	output reg     [71:0]     out_data
);

    //--------------------------------------------------------------------------------
	// Explained by Brian Sune
    //--------------------------------------------------------------------------------
	// G(X) = X16 + X5 + X4 + X3 + 1 
	// Need to be very careful on the expression of G(x)
	// LFSR have two types: Fibonacci / Galois
	// G = Galois
	// D16 = loop back to D
	// 3 = flop out 3 where all index start from 1,2,3...
    //--------------------------------------------------------------------------------
    // Here are the first 32 output words when data values of "00" are scrambled: 
    //
    //    | 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    // ---+------------------------------------------------
    // 00 | FF 17 C0 14 B2 E7 02 82 72 6E 28 A6 BE 6D BF 8D
    // 10 | BE 40 A7 E6 2C D3 E2 B2 07 02 77 2A CD 34 BE E0
    //
    //--------------------------------------------------------------------------------
	
    localparam [15:0] lfsr_reset_state = (DP_eDP == 0) ? 16'hff_ff : 16'hff_fe;
    reg [15:0] lfsr_state;
	
	// K28.0 is used to signal a reset for the scrambler
	// K28.0 = 0x1C
	// MSb = 1, K code
    localparam [8:0] SR  = 9'b100011100;
	
    wire [15:0]  s0;
    wire [15:0]  s1;
    wire [17:0]  flipping;

	assign s0 = lfsr_state;

    // generate intermediate scrambler state
    assign s1[0]  = (in_data[8:0] == SR) ? lfsr_reset_state[0]  : s0[8];
    assign s1[1]  = (in_data[8:0] == SR) ? lfsr_reset_state[1]  : s0[9];
    assign s1[2]  = (in_data[8:0] == SR) ? lfsr_reset_state[2]  : s0[10];
    assign s1[3]  = (in_data[8:0] == SR) ? lfsr_reset_state[3]  : s0[11]                   ^ s0[8];
    assign s1[4]  = (in_data[8:0] == SR) ? lfsr_reset_state[4]  : s0[12]          ^ s0[8]  ^ s0[9];
    assign s1[5]  = (in_data[8:0] == SR) ? lfsr_reset_state[5]  : s0[13] ^ s0[8]  ^ s0[9]  ^ s0[10];
    assign s1[6]  = (in_data[8:0] == SR) ? lfsr_reset_state[6]  : s0[14] ^ s0[9]  ^ s0[10] ^ s0[11];
    assign s1[7]  = (in_data[8:0] == SR) ? lfsr_reset_state[7]  : s0[15] ^ s0[10] ^ s0[11] ^ s0[12];
    assign s1[8]  = (in_data[8:0] == SR) ? lfsr_reset_state[8]  : s0[0]  ^ s0[11] ^ s0[12] ^ s0[13];
    assign s1[9]  = (in_data[8:0] == SR) ? lfsr_reset_state[9]  : s0[1]  ^ s0[12] ^ s0[13] ^ s0[14];
    assign s1[10] = (in_data[8:0] == SR) ? lfsr_reset_state[10] : s0[2]  ^ s0[13] ^ s0[14] ^ s0[15];
    assign s1[11] = (in_data[8:0] == SR) ? lfsr_reset_state[11] : s0[3]  ^ s0[14] ^ s0[15];
    assign s1[12] = (in_data[8:0] == SR) ? lfsr_reset_state[12] : s0[4]  ^ s0[15];
    assign s1[13] = (in_data[8:0] == SR) ? lfsr_reset_state[13] : s0[5];
    assign s1[14] = (in_data[8:0] == SR) ? lfsr_reset_state[14] : s0[6];
    assign s1[15] = (in_data[8:0] == SR) ? lfsr_reset_state[15] : s0[7];                

    assign flipping[8:0]  = (in_data[8]  == 1'b0 && bypass0 == 1'b0) ? {1'b0, s0[8], s0[9], s0[10], s0[11], s0[12], s0[13], s0[14], s0[15]} : 9'b000000000;
    assign flipping[17:9] = (in_data[17] == 1'b0 && bypass1 == 1'b0) ? {1'b0, s1[8], s1[9], s1[10], s1[11], s1[12], s1[13], s1[14], s1[15]} : 9'b000000000;

initial begin
    out_data <= 72'b0;
    lfsr_state = lfsr_reset_state;
end


always @(posedge clk) begin    
    //------------------------------------------
    // Apply vector to channel 0
    //------------------------------------------        
    out_data <= in_data ^ {flipping, flipping, flipping, flipping};

    lfsr_state[0]  = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[8];
    lfsr_state[1]  = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[9];
    lfsr_state[2]  = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[10];
    lfsr_state[3]  = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[11]                   ^ s1[8];
    lfsr_state[4]  = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[12]          ^ s1[8]  ^ s1[9];
    lfsr_state[5]  = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[13] ^ s1[8]  ^ s1[9]  ^ s1[10];
    lfsr_state[6]  = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[14] ^ s1[9]  ^ s1[10] ^ s1[11];
    lfsr_state[7]  = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[15] ^ s1[10] ^ s1[11] ^ s1[12];
	
    lfsr_state[8]  = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[0]  ^ s1[11] ^ s1[12] ^ s1[13];
    lfsr_state[9]  = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[1]  ^ s1[12] ^ s1[13] ^ s1[14];
    lfsr_state[10] = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[2]  ^ s1[13] ^ s1[14] ^ s1[15];
    lfsr_state[11] = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[3]  ^ s1[14] ^ s1[15];
    lfsr_state[12] = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[4]  ^ s1[15];
    lfsr_state[13] = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[5];
    lfsr_state[14] = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[6];
    lfsr_state[15] = (in_data[15:8] == SR) ? lfsr_reset_state[0]  : s1[7];                
end
endmodule

// =======================================================================
// End of File
// =======================================================================

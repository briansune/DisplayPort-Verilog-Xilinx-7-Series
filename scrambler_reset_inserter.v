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
// Date: 2026/03/22
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Cleanup
// =======================================================================
// Documentation
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// VESA DisplayPort (DP) Standard 2.0
// 3.5.1.1 Scrambling
// The Source Device must replace every 512th BS symbol with a SR symbol.
// The SR symbol is used to reset the LFSR to FFFFh
// =======================================================================
// HDL File: scrambler_reset_inserter.v
// =======================================================================
// Programed By: BrianSune
// Contact: briansune@gmail.com
// =======================================================================

`timescale 1ns / 1ps

/////////////////////////////////////////////////////////////////////
// TODO - Needs to also work for BS in the high half of the in_data
/////////////////////////////////////////////////////////////////////
// Note - this assumes that all the BS sysbols will be aligned (which
// they should). This means we only need one counter and one flag
/////////////////////////////////////////////////////////////////////
module  scrambler_reset_inserter(
	
	input         clk,
	input  [71:0] in_data,
	output reg [71:0] out_data
);

reg [8:0] bs_count;
reg       substitue_next;

localparam [8:0] BS = 9'b110111100;  // K28.5 0x1BC
localparam [8:0] SR = 9'b100011100;  // K28.0 0x11C

initial begin
    bs_count       = 9'b0;
    substitue_next = 1'b0;
    out_data       = 72'b0;
end

always @(posedge clk) begin
    //----------------------------------------------
    // Subsitute every 512nd Blank start (BS) symbol
    // with a Scrambler Reset (SR) symbol. 
    //----------------------------------------------
    out_data  <= in_data;

    if(substitue_next == 1'b1) begin
        if(in_data[8:0]   == BS) begin
            out_data[8:0]   <= SR;
        end

        if(in_data[26:18] == BS) begin
            out_data[26:18] <= SR;
        end

        if(in_data[44:36] == BS) begin
            out_data[44:36] <= SR;
        end

        if(in_data[62:54] == BS) begin
            out_data[62:54] <= SR;
        end
    end

    if(in_data[8:0] == BS) begin
    	if(bs_count == 9'b0) begin
            substitue_next <= 1'b1;
    	end else begin
            substitue_next <= 1'b0;
    	end
    	bs_count <= bs_count + 1'b1;
    end
end

endmodule

// =======================================================================
// End of File
// =======================================================================

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
//	1.0.1	| Fix indentations
//	1.0.1	| Add standard documentations
//	1.0.1	| Add parametric lanes
// =======================================================================
// VESA DisplayPort (DP) Standard 2.0
// DisplayPort only allows 1,2,4
// 2.2.1.6 Inter-lane Skewing
// =======================================================================
// HDL File: skew_channels.v
// =======================================================================
// Programed By: BrianSune
// Contact: briansune@gmail.com
// =======================================================================

`timescale 1ns / 1ps
 
module skew_channels#(
	parameter integer lanes = 4
)(
	input  wire                      clk,
	input  wire    [20*lanes-1:0]    in_data,
	output wire    [20*lanes-1:0]    out_data
);

	assign out_data[19:0]	= in_data[19:0];

	generate
		if(lanes >= 2)begin : dp_two_lanes
			reg [59:0] delay0;
			
			always @(posedge clk) begin
				delay0 <= in_data[79:20];
			end
			
			assign out_data[39:20]	= delay0[19:0];
			
			if(lanes == 4)begin : dp_four_lanes
				
				reg [39:0] delay1;
				reg [19:0] delay2;
				
				always @(posedge clk) begin
					delay2 <= delay1[39:20];
					delay1 <= delay0[59:20];
				end
				
				assign out_data[79:60]	= delay2[19:0];
				assign out_data[59:40]	= delay1[19:0];
				
			end
		end
	endgenerate

endmodule

// =======================================================================
// End of File
// =======================================================================

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
// original design from M.F. is absolutely make no sense
// fix color bar print and simplify LUT
// parametric line width
// =======================================================================
// HDL File: merge_colourbars.v
// =======================================================================
// Programed By: BrianSune
// Contact: briansune@gmail.com
// =======================================================================

`timescale 1ns / 1ps

module merge_colourbars#(
	parameter integer dp_lanes = 2,
	parameter integer line_width = 1920
)(
	input  wire              clk,
	input  wire    [72:0]    data_in,
	output reg     [72:0]    data_out
);

    localparam [8:0] PIX   = 9'b011001100;
    localparam [8:0] BE    = 9'b111111011;  // K27.7 Blank End
    localparam [8:0] BS    = 9'b110111100;  // K28.5 Blank Start 
	localparam [8:0] FS    = 9'b111111110;  // K30.7 Fill Start
   
    reg [11:0] pixel_count;
	
    reg [23:0] pixel_lut;
    reg [23:0] pixel_lut_next;

	
    reg [1:0] r_g_b;

initial begin
    pixel_count          = 12'b0;
    r_g_b                = 2'b00;
end

localparam integer pixel_edge = line_width / 8;

always@(*)begin
	if     (pixel_count < pixel_edge*1)   begin pixel_lut = 24'hFFFFFF; end
    else if(pixel_count < pixel_edge*2)   begin pixel_lut = 24'h00FFFF; end
    else if(pixel_count < pixel_edge*3)   begin pixel_lut = 24'hFFFF00; end
    else if(pixel_count < pixel_edge*4)   begin pixel_lut = 24'hFF00FF; end
    else if(pixel_count < pixel_edge*5)   begin pixel_lut = 24'h000000; end
    else if(pixel_count < pixel_edge*6)   begin pixel_lut = 24'hFF0000; end
    else if(pixel_count < pixel_edge*7)   begin pixel_lut = 24'h00FF00; end
    else                                  begin pixel_lut = 24'h0000FF; end
	
	if     (pixel_count < pixel_edge*1-dp_lanes)   begin pixel_lut_next = 24'hFFFFFF; end
    else if(pixel_count < pixel_edge*2-dp_lanes)   begin pixel_lut_next = 24'h00FFFF; end
    else if(pixel_count < pixel_edge*3-dp_lanes)   begin pixel_lut_next = 24'hFFFF00; end
    else if(pixel_count < pixel_edge*4-dp_lanes)   begin pixel_lut_next = 24'hFF00FF; end
    else if(pixel_count < pixel_edge*5-dp_lanes)   begin pixel_lut_next = 24'h000000; end
    else if(pixel_count < pixel_edge*6-dp_lanes)   begin pixel_lut_next = 24'hFF0000; end
    else if(pixel_count < pixel_edge*7-dp_lanes)   begin pixel_lut_next = 24'h00FF00; end
    else                                           begin pixel_lut_next = 24'h0000FF; end
end

always @(posedge clk) begin
 
///////////////////////////////////////////////
// Scheduling the data out to the pipeline
///////////////////////////////////////////////

    data_out <= data_in;
    ///////////////////////////////////////////////
    // Replace the sentinel values with pixel data  
    ///////////////////////////////////////////////
    if(data_in[17:9] == PIX && data_in[8:0] == PIX) begin
	
       case(r_g_b) 
         2'b00:   begin
                    r_g_b <= 2'b10;
                    data_out[7:0]   <=  pixel_lut[7:0]; 
                    data_out[16:9]  <=  pixel_lut[15:8];
                    data_out[25:18] <=  pixel_lut[7:0];
                    data_out[34:27] <=  pixel_lut[15:8];
					
					data_out[7+36:0+36]   <=  pixel_lut[7:0]; 
                    data_out[16+36:9+36]  <=  pixel_lut[15:8];
                    data_out[25+36:18+36] <=  pixel_lut[7:0];
                    data_out[34+36:27+36] <=  pixel_lut[15:8];
                  end
         2'b01:   begin
                    r_g_b <= 2'b00;
                    pixel_count <= pixel_count + dp_lanes[2:0];
					
                    data_out[7:0]   <=  pixel_lut[15:8];
                    data_out[16:9]  <=  pixel_lut[23:16];
					
                    data_out[25:18] <=  pixel_lut[15:8];
                    data_out[34:27] <=  pixel_lut[23:16];
					
					data_out[7+36:0+36]   <=  pixel_lut[15:8];
                    data_out[16+36:9+36]  <=  pixel_lut[23:16];
					
                    data_out[25+36:18+36] <=  pixel_lut[15:8];
                    data_out[34+36:27+36] <=  pixel_lut[23:16];

                  end
         default: begin
                    r_g_b <= 2'b01;
                    pixel_count <= pixel_count + dp_lanes[2:0];
					
                    data_out[7:0]   <=  pixel_lut[23:16];
                    data_out[16:9]  <=  pixel_lut_next[7:0];
					
                    data_out[25:18] <=  pixel_lut[23:16];
                    data_out[34:27] <=  pixel_lut_next[7:0];
					
					data_out[7+36:0+36]   <=  pixel_lut[23:16];
                    data_out[16+36:9+36]  <=  pixel_lut_next[7:0];
					
                    data_out[25+36:18+36] <=  pixel_lut[23:16];
                    data_out[34+36:27+36] <=  pixel_lut_next[7:0];
                  end
       endcase

    end else if(data_in[17:9] == FS && data_in[8:0] == PIX) begin
       case(r_g_b) 
         2'b00:   begin
                    r_g_b <= 2'b01;
					
                    data_out[7:0]   <=  pixel_lut[7:0];
                    data_out[25:18] <=  pixel_lut[7:0];
					
					data_out[7+36:0+36]   <=  pixel_lut[7:0];
                    data_out[25+36:18+36] <=  pixel_lut[7:0];
                  end
         2'b01:   begin
                    r_g_b <= 2'b10;
                    data_out[7:0]   <=  pixel_lut[15:8];
                    data_out[25:18] <=  pixel_lut[15:8];
					
					data_out[7+36:0+36]   <=  pixel_lut[15:8];
                    data_out[25+36:18+36] <=  pixel_lut[15:8];
                  end
         default: begin
                    r_g_b <= 2'b00;
                    
					pixel_count <= pixel_count + dp_lanes[2:0];
					
                    data_out[7:0]   <=  pixel_lut[23:16];
                    data_out[25:18] <=  pixel_lut[23:16];
					data_out[7+36:0+36]   <=  pixel_lut[23:16];
                    data_out[25+36:18+36] <=  pixel_lut[23:16];
                  end
       endcase
    end
	
    if(data_in[17:9] == BS || data_in[8:0] == BS) begin
       pixel_count <= 12'b0;
    end
end

endmodule

// =======================================================================
// End of File
// =======================================================================

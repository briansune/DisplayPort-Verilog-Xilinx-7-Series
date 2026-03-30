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
// Date: 2026/03/22
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Initial Release
// Reference: Mike Field <hamster@snap.net.nz> DP Verilog Project
// =======================================================================
// HDL File: test_source_1080p_RGB_colourbar_ch4.v
// =======================================================================
// Programed By: BrianSune
// Contact: briansune@gmail.com
// =======================================================================

`timescale 1ns / 1ps

module test_source_1080p_RGB_colourbar_ch4(
        output reg [23:0] M_value,
        output reg [23:0] N_value,
        output reg [11:0] H_visible,
        output reg [11:0] V_visible,
        output reg [11:0] H_total,
        output reg [11:0] V_total,
        output reg [11:0] H_sync_width,
        output reg [11:0] V_sync_width,
        output reg [11:0] H_start,
        output reg [11:0] V_start,
        output reg        H_vsync_active_high,
        output reg        V_vsync_active_high,
        output reg        flag_sync_clock,
        output reg        flag_YCCnRGB,
        output reg        flag_422n444,
        output reg        flag_YCC_colour_709,
        output reg        flag_range_reduced,
        output reg        flag_interlaced_even,
        output reg  [1:0] flags_3d_Indicators,
        output reg  [4:0] bits_per_colour,
        output reg  [2:0] stream_channel_count,

        input             clk,
        output reg        ready,
        output     [72:0] data
    );

/////////////////////////////////////////////////////
// 
//  Transfer Units (TUs) are 0 to 19 pairs of symbols
//  Making them 40 symbols long. Each normal TU transfers
//  11 pixels, making the pixel clock 11/40ths of the 
//  symbol rate. The symbol rate is 270M Symbols/s.
//
//  So pixel clock is 11/40*270 = 74.25M pixels/sec
/////////////////////////////////////////////////////
    
    localparam [8:0] DUMMY = 9'b000000000;  // 0x03
    localparam [8:0] SPARE = 9'b011111111;  // 0xFF
    localparam [8:0] ZERO  = 9'b000000000;  // 0x00
    localparam [8:0] PIX   = 9'b011001100;  // Colour level 0xCC

    localparam [8:0] BE    = 9'b111111011;  // K27.7 Blank End
    localparam [8:0] BS    = 9'b110111100;  // K28.5 Blank Start 
    localparam [8:0] FS    = 9'b111111110;  // K30.7 Fill Start
    localparam [8:0] FE    = 9'b111110111;  // K23.7 Fill End
   

    localparam [8:0] VB_VS  = 9'b000000001;  // 0x00  VB-ID with Vertical blank asserted 
    localparam [8:0] VB_NVS = 9'b000000000;  // 0x00  VB-ID without Vertical blank asserted
    localparam [8:0] MVID   = {1'b0, 8'd11};  // 0x46 - low 8 bits of Mvid counter
    // localparam [8:0] MVID   = {1'b0, 8'h78};  // 0x46 - low 8 bits of Mvid counter
    localparam [8:0] MAUD   = 9'b000000000;  // 0x00    

	// pclk * bpp / 2
	// 148.5 * 48 / 2 = 3564 / 8 = 445.5  M symbol/lane
	// CANNOT RUN on 2 lane
	// 74.25 * 48 / 2 = 1782 / 8 = 222.75 M symbol/lane
	// PASS
	// 148.5 * 48 / 4 = 1782 / 8 = 222.75 M symbol/lane
	// PASS
    localparam [7:0] TUs_per_line    = 8'd80;  //  2200 / 2 channels / 27.5 clocks per TU
	
	// 445.5 / 540M * 50 = 41.25
    localparam [7:0] TU_length       = 7'd50;
    localparam [7:0] last_active_TU  = 7'd69;

    reg  [7:0] index = 0;
    reg  [8:0] d0 = 0;
    reg  [8:0] d1 = 0;
    reg [10:0] line_count = 0;
    reg  [7:0] block_count = 0;
    reg        switch_point  = 0;

    reg [47:0] pixels_next;
    reg        new_next;
    wire [72:0] raw_data;

initial begin
    // Pixel clock ratio is 2200/4000 of the link speed.
    // (i.e. it takes 4000 cycles of the 270MHz clock to
    // transfer a horizontal scan line that is 2200 counts
    // of the pixel clock.
    // Because of this exact ratio, the Mvid value in the 
    // Stream is static.
    // M_value              = 24'h004678; // 18040
    // N_value              = 24'h008000; // 32768
	
	M_value              = 24'd11;
    N_value              = 24'd20;
	
    H_visible            = 12'd1920;
    H_total              = 12'd2200;
    H_start              = 12'd192;  
    H_sync_width         = 12'd44;

    V_visible            = 12'd1080;
    V_total              = 12'd1125;
    V_start              = 12'd41;
    V_sync_width         = 12'd5;

    H_vsync_active_high  = 1'b0;
    V_vsync_active_high  = 1'b0;
    flag_sync_clock      = 1'b1;
    flag_YCCnRGB         = 1'b0;
    flag_422n444         = 1'b0;
    flag_range_reduced   = 1'b0;
    flag_interlaced_even = 1'b0;
    flag_YCC_colour_709  = 1'b0;
    flags_3d_Indicators  = 2'b00;
	
	// 2.2.1.3.5 24 bpp RGB / YCbCr 4:4:4 (8 Bits per Component)
    bits_per_colour      = 5'b01000;

    stream_channel_count = 3'b100; 
    ready                = 1'b1;

end

    assign raw_data[72]             = switch_point;
    
	assign raw_data[71:63]          = d1;
	assign raw_data[62:54]          = d0;
	assign raw_data[53:45]          = d1;
	assign raw_data[44:36]          = d0;
	
    assign raw_data[35:27]          = d1;
    assign raw_data[26:18]          = d0; 
    assign raw_data[17:9]           = d1;
    assign raw_data[8:0]            = d0; 

merge_colourbars#(
	.dp_lanes	(4)
)i_merge_colorbars(
  .clk      (clk),
  .data_in  (raw_data),
  .data_out (data)
);

// the blow LUT is a bit messy
// to understand this just need to see the TU symbol / lane size

always @(posedge clk) begin
    // Load the next byte of the sequence into d0 and d1
    case(index)  
        8'h00: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h01: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h02: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h03: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h04: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h05: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h06: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h07: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h08: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h09: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h0A: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h0B: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h0C: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h0D: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h0E: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h0F: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h10: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h11: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h12: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h13: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h14: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h15: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h16: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h17: begin d0 <= DUMMY;  d1 <= DUMMY; end
        8'h18: begin d0 <= DUMMY;  d1 <= DUMMY; end
    
        // Block 1 - 17 white pixels and padding
		// 12 + (5*2/6) 16bpp RGB pixels
        8'h20: begin d0 <= PIX;    d1 <= PIX;    end
        8'h21: begin d0 <= PIX;    d1 <= PIX;    end
        8'h22: begin d0 <= PIX;    d1 <= PIX;    end
        8'h23: begin d0 <= PIX;    d1 <= PIX;    end
        8'h24: begin d0 <= PIX;    d1 <= PIX;    end
        8'h25: begin d0 <= PIX;    d1 <= PIX;    end
        8'h26: begin d0 <= PIX;    d1 <= PIX;    end
        8'h27: begin d0 <= PIX;    d1 <= PIX;    end
        8'h28: begin d0 <= PIX;    d1 <= PIX;    end
        8'h29: begin d0 <= PIX;    d1 <= PIX;    end
        8'h2A: begin d0 <= PIX;    d1 <= FS;     end
        8'h2B: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h2C: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h2D: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h2E: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h2F: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h30: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h31: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h32: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h33: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h34: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h35: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h36: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h37: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h38: begin d0 <= DUMMY;  d1 <= FE;     end // FE (Fill End)
    
        // Block 2 - 3 white pixels and padding; d1 <= VB-ID (-vblank); d1 <= Mvid; d1 <= MAud and junk
		// 28 16bpp RGB pixels
        8'h40: begin d0 <= PIX;    d1 <= PIX;    end
        8'h41: begin d0 <= PIX;    d1 <= PIX;    end
        8'h42: begin d0 <= PIX;    d1 <= PIX;    end
        8'h43: begin d0 <= PIX;    d1 <= PIX;    end
        8'h44: begin d0 <= PIX;    d1 <= PIX;    end
        8'h45: begin d0 <= PIX;    d1 <= PIX;    end
        8'h46: begin d0 <= PIX;    d1 <= PIX;    end
        8'h47: begin d0 <= PIX;    d1 <= PIX;    end
        8'h48: begin d0 <= PIX;    d1 <= PIX;    end
        8'h49: begin d0 <= PIX;    d1 <= PIX;    end
        8'h4A: begin d0 <= PIX;    d1 <= FS;     end
        8'h4B: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h4C: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h4D: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h4E: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h4F: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h50: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h51: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h52: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h53: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h54: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h55: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h56: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h57: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h58: begin d0 <= DUMMY;  d1 <= FE;     end
    
        // Block 3 - 3 white pixels and padding; d1 <= VB-ID (-vblank); d1 <= Mvid; d1 <= MAud and junk
		// 24 16bpp RGB pixels
        8'h60: begin d0 <= PIX;    d1 <= PIX;    end
        8'h61: begin d0 <= PIX;    d1 <= PIX;    end
        8'h62: begin d0 <= PIX;    d1 <= PIX;    end
        8'h63: begin d0 <= PIX;    d1 <= PIX;    end
        8'h64: begin d0 <= PIX;    d1 <= PIX;    end
        8'h65: begin d0 <= PIX;    d1 <= PIX;    end
        8'h66: begin d0 <= BS;     d1 <= VB_NVS; end
        8'h67: begin d0 <= MVID;   d1 <= MAUD;   end
        8'h68: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h69: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h6A: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h6B: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h6C: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h6D: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h6E: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h6F: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h70: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h71: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h72: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h73: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h74: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h75: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h76: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h77: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h78: begin d0 <= DUMMY;  d1 <= DUMMY;  end
    
        // Block 4 - 4 white pixels and padding; d1 <= VB-ID (+vblank); d1 <= Mvid; d1 <= MAud and junk
		// 24 16bpp RGB pixels
        8'h80: begin d0 <= PIX;    d1 <= PIX;    end
        8'h81: begin d0 <= PIX;    d1 <= PIX;    end
        8'h82: begin d0 <= PIX;    d1 <= PIX;    end
        8'h83: begin d0 <= PIX;    d1 <= PIX;    end
        8'h84: begin d0 <= PIX;    d1 <= PIX;    end
        8'h85: begin d0 <= PIX;    d1 <= PIX;    end
        8'h86: begin d0 <= BS;     d1 <= VB_VS;  end
        8'h87: begin d0 <= MVID;   d1 <= MAUD;   end
        8'h88: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h89: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h8A: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h8B: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h8C: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h8D: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h8E: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h8F: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h90: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h91: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h92: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h93: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h94: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h95: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h96: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h97: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'h98: begin d0 <= DUMMY;  d1 <= DUMMY;  end
    
        // Block 5 - DUMMY;Blank Start; d1 <= VB-ID (+vblank); d1 <= Mvid; d1 <= MAud and junk
        8'hA0: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hA1: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hA2: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hA3: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hA4: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hA5: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hA6: begin d0 <= BS;     d1 <= VB_VS;  end
        8'hA7: begin d0 <= MVID;   d1 <= MAUD;   end
        8'hA8: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hA9: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hAA: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hAB: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hAC: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hAD: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hAE: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hAF: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hB0: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hB1: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hB2: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hB3: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hB4: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hB5: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hB6: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hB7: begin d0 <= DUMMY;  d1 <= DUMMY;  end
        8'hB8: begin d0 <= DUMMY;  d1 <= DUMMY;  end
    
        // Block 6 - just blank end
        8'hC0: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hC1: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hC2: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hC3: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hC4: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hC5: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hC6: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hC7: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hC8: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hC9: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hCA: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hCB: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hCC: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hCD: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hCE: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hCF: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hD0: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hD1: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hD2: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hD3: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hD4: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hD5: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hD6: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hD7: begin d0 <= DUMMY; d1 <= DUMMY; end
        8'hD8: begin d0 <= DUMMY; d1 <= BE;    end // BE (Blanking End)

        default: begin d0 <= SPARE; d1 <= SPARE; end
    endcase

	// TU Length / 2 - 1 = 19
    if(index[4:0] == 5'h18) begin
        index[4:0] <= 5'd0;
        if(block_count ==  TUs_per_line-1) begin   
            block_count <= 8'b0;
            if(line_count == V_total-1) begin
                line_count <= 11'b0;
            end else begin
                line_count <= line_count + 1'b1;
            end
        end else begin
            block_count <= block_count + 1'b1;
        end

        // Block 0 - empty 
        // Block 1 - 11 pixels FS padding FE
        // Block 2 - 3 pixels, BS, VB-ID (-vsync), Mvid, Maud, VB-ID (-vsync), Mvid, Maud, empty
        // Block 2 - 3 pixels, BS, VB-ID (+vsync), Mvid, Maud, VB-ID (+vsync), Mvid, Maud, empty
        // Block 4 - empty space for 3 pixels ,BS, VB-ID (+vsync), Mvid, MAud. VB-ID (+vsync), Mvid, MAud, empty
        // Block 5 - last symbol is blank end

        index[7:5]   <= 3'b000;  // Dummy symbols for the default block
        switch_point <= 1'b0;

		// lines of active video (except last)
        if(line_count <= V_visible-1) begin
			
			// first block BE
			// Example
			// Table 2-32: Transfer Unit of 30 bpp RGB Video Over a 2.7 Gbps Per Lane Main Link
			// when start LUT(0x00) -> LUT(0xC0)
			// this form a 50 symbol / lane
            if(block_count < 1) begin
                index[7:5] <= 3'b110;

			// block 1,2,...
            end else if(block_count < last_active_TU) begin 
				// 4, 8, 12, 16, 20, 24
				// 28 56 excluded
                // if(
					// (block_count[1:0] == 2'b00 && block_count[4:2] != 3'b111) ||
					// block_count >= 8'd66
				// ) begin
					// Pixels plus fill
					// 14 RGB pixels
					// index[7:5] <= 3'b010;

				// Pixels plus fill
				// 1, 2, 3
				// LUT(0x20) -> LUT(0x20) -> LUT(0x20) -> LUT(0x20)
				// pixels count = 12*3 + 10/6*3 = 41
                // end else begin
					index[7:5] <= 3'b001;
                // end
            end else if(block_count == last_active_TU) begin
				if(line_count == V_visible-1)
					index[7:5] <= 3'b100;  // Pixels BS and VS-ID block (with VBLANK flag)
				else
					index[7:5] <= 3'b011;  // Pixels BS and VS-ID block (no VBLANK flag)
            end
        end else begin
            //---------------------------------------------------------------
            // Allow switching to/from the idle pattern during the vertical blank
            //---------------------------------------------------------------                        
            if(block_count < last_active_TU) begin
                switch_point <= 1'b1;
            end else if(block_count == last_active_TU) begin
                index[7:5] <= 3'b101;  // Dummy symbols, BS and VS-ID block (with VBLANK flag)                        
            end
        end            
    end else begin
        index <= index + 1'b1;
    end
end

endmodule

// =======================================================================
// End of File
// =======================================================================

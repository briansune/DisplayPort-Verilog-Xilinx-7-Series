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
// remove all untested and nonsense example module / files
// fully tested 4 channels on 1080p and 1440p
// fully tested 2 channels on 1080p
// =======================================================================
// HDL File: test_source.v
// =======================================================================
// Programed By: BrianSune
// Contact: briansune@gmail.com
// =======================================================================

`timescale 1ns / 1ps

module test_source(
	input  wire              clk,
	output wire    [2:0]     stream_channel_count,
	output wire              ready,
	output reg     [72:0]    data
);

    wire [23:0] M_value;
    wire [23:0] N_value;
    wire [11:0] H_visible;
    wire [11:0] V_visible;
    wire [11:0] H_total;
    wire [11:0] V_total;
    wire [11:0] H_sync_width;
    wire [11:0] V_sync_width;
    wire [11:0] H_start;
    wire [11:0] V_start;
    wire        H_vsync_active_high;
    wire        V_vsync_active_high;
    wire        flag_sync_clock;
	
    wire        flag_YCCnRGB;
    wire        flag_422n444;
    wire        flag_YCC_colour_709;
    wire        flag_range_reduced;
    wire        flag_interlaced_even;
    wire  [1:0] flags_3d_Indicators;
    wire  [4:0] bits_per_colour;

    wire [72:0] raw_data;
    wire [72:0] data_ch_1;
    wire [72:0] data_ch_2;
    wire [72:0] data_ch_4;

always @(*) begin
    case(stream_channel_count)
        3'b100:  data <= data_ch_4;
        3'b010:  data <= data_ch_2;
        default: data <= data_ch_1;
    endcase
end

// test_source_1080p_RGB_444_colourbar i_test_source(
// test_source_1080p_RGB_colourbar_ch4 i_test_source(
test_source_1440p_RGB_444_colourbar i_test_source(
            .M_value              (M_value),
            .N_value              (N_value),
            
            .H_visible            (H_visible),
            .H_total              (H_total),
            .H_sync_width         (H_sync_width),
            .H_start              (H_start),    
            
            .V_visible            (V_visible),
            .V_total              (V_total),
            .V_sync_width         (V_sync_width),
            .V_start              (V_start),
            .H_vsync_active_high  (H_vsync_active_high),
            .V_vsync_active_high  (V_vsync_active_high),
            .flag_sync_clock      (flag_sync_clock),
            .flag_YCCnRGB         (flag_YCCnRGB),
            .flag_422n444         (flag_422n444),
            .flag_range_reduced   (flag_range_reduced),
            .flag_interlaced_even (flag_interlaced_even),
            .flag_YCC_colour_709  (flag_YCC_colour_709),
            .flags_3d_Indicators  (flags_3d_Indicators),
            .bits_per_colour      (bits_per_colour), 
            .stream_channel_count (stream_channel_count),

            .clk          (clk),
            .ready        (ready),
            .data         (raw_data)
        );

insert_main_stream_attrbutes_one_channel i_insert_main_stream_attrbutes_one_channel(
            .clk                  (clk),
            .active                  (1'b1),
            //////////////////////////////////////////////////////
            // The MSA values (some are range reduced and could 
            // be 16 bits ins size)
            //////////////////////////////////////////////////////     
            .M_value              (M_value),
            .N_value              (N_value),

            .H_visible            (H_visible),
            .H_total              (H_total),
            .H_sync_width         (H_sync_width),
            .H_start              (H_start),    
     
            .V_visible            (V_visible),
            .V_total              (V_total),
            .V_sync_width         (V_sync_width),
            .V_start              (V_start),
            .H_vsync_active_high  (H_vsync_active_high),
            .V_vsync_active_high  (V_vsync_active_high),
            .flag_sync_clock      (flag_sync_clock),
            .flag_YCCnRGB         (flag_YCCnRGB),
            .flag_422n444         (flag_422n444),
            .flag_range_reduced   (flag_range_reduced),
            .flag_interlaced_even (flag_interlaced_even),
            .flag_YCC_colour_709  (flag_YCC_colour_709),
            .flags_3d_Indicators  (flags_3d_Indicators),
            .bits_per_colour      (bits_per_colour), 
            //////////////////////////////////////////////////////
            // The stream of pixel data coming in
            //////////////////////////////////////////////////////
            .in_data              (raw_data),
            //////////////////////////////////////////////////////
            // The stream of pixel data going out
            //////////////////////////////////////////////////////
            .out_data             (data_ch_1)
        );

insert_main_stream_attrbutes_two_channels i_insert_main_stream_attrbutes_two_channels(
            .clk                  (clk),
            .active               (1'b1),
            //////////////////////////////////////////////////////
            // The MSA values (some are range reduced and could 
            // be 16 bits ins size)
            //////////////////////////////////////////////////////     
            .M_value              (M_value),
            .N_value              (N_value),

            .H_visible            (H_visible),
            .H_total              (H_total),
            .H_sync_width         (H_sync_width),
            .H_start              (H_start),    
     
            .V_visible            (V_visible),
            .V_total              (V_total),
            .V_sync_width         (V_sync_width),
            .V_start              (V_start),
            .H_vsync_active_high  (H_vsync_active_high),
            .V_vsync_active_high  (V_vsync_active_high),
            .flag_sync_clock      (flag_sync_clock),
            .flag_YCCnRGB         (flag_YCCnRGB),
            .flag_422n444         (flag_422n444),
            .flag_range_reduced   (flag_range_reduced),
            .flag_interlaced_even (flag_interlaced_even),
            .flag_YCC_colour_709  (flag_YCC_colour_709),
            .flags_3d_Indicators  (flags_3d_Indicators),
            .bits_per_colour      (bits_per_colour), 
            //////////////////////////////////////////////////////
            // The stream of pixel data coming in
            //////////////////////////////////////////////////////
            .in_data              (raw_data),
            //////////////////////////////////////////////////////
            // The stream of pixel data going out
            //////////////////////////////////////////////////////
            .out_data             (data_ch_2)
        );

insert_main_stream_attrbutes_four_channels i_insert_main_stream_attrbutes_four_channels(
            .clk                  (clk),
            .active               (1'b1),
            //////////////////////////////////////////////////////
            // The MSA values (some are range reduced and could 
            // be 16 bits ins size)
            //////////////////////////////////////////////////////     
            .M_value              (M_value),
            .N_value              (N_value),

            .H_visible            (H_visible),
            .H_total              (H_total),
            .H_sync_width         (H_sync_width),
            .H_start              (H_start),    
     
            .V_visible            (V_visible),
            .V_total              (V_total),
            .V_sync_width         (V_sync_width),
            .V_start              (V_start),
            .H_vsync_active_high  (H_vsync_active_high),
            .V_vsync_active_high  (V_vsync_active_high),
            .flag_sync_clock      (flag_sync_clock),
            .flag_YCCnRGB         (flag_YCCnRGB),
            .flag_422n444         (flag_422n444),
            .flag_range_reduced   (flag_range_reduced),
            .flag_interlaced_even (flag_interlaced_even),
            .flag_YCC_colour_709  (flag_YCC_colour_709),
            .flags_3d_Indicators  (flags_3d_Indicators),
            .bits_per_colour      (bits_per_colour), 
            //////////////////////////////////////////////////////
            // The stream of pixel data coming in
            //////////////////////////////////////////////////////
            .in_data              (raw_data),
            //////////////////////////////////////////////////////
            // The stream of pixel data going out
            //////////////////////////////////////////////////////
            .out_data             (data_ch_4)
        );

endmodule

// =======================================================================
// End of File
// =======================================================================

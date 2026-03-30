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
// Date: 2026/03/21
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Initial Release
// Reference: Mike Field <hamster@snap.net.nz> DP Verilog Project
// fix 4/2 lanes reply messages
// fix handshaking absent
// add timeout test case
// =======================================================================
// HDL File: tb_dummy_sink.v
// =======================================================================
// Programed By: BrianSune
// Contact: briansune@gmail.com
// =======================================================================

`timescale 1ns / 1ps

module tb_dummy_sink#(
	parameter integer lane_no = 2
)(
    input			clk100,
    input			go_next,
    output			auxch_data,
    output reg		hotplug_detect
);

wire       sender_aux_tri;
 
reg        sender_wr_en;
reg [7:0]  sender_wr_data;
wire       sender_wr_full;
//----------------------------
reg        sender_rd_en;
wire [7:0] sender_rd_data;
wire       sender_rd_empty;
wire       sender_busy;
wire       sender_timeout;
reg        sender_abort;

aux_interface sender(
   .clk         (clk100),
   //----------------------------
   .aux_in      (1'b1),
   .aux_out     (auxch_data),
   .aux_tri     (sender_aux_tri),
   //----------------------------
   .tx_wr_en    (sender_wr_en),
   .tx_data     (sender_wr_data),
   .tx_full     (sender_wr_full),
   //----------------------------
   .rx_rd_en    (sender_rd_en),
   .rx_data     (sender_rd_data),
   .rx_empty    (sender_rd_empty),
   //----------------------------
   .busy        (sender_busy),
   .abort       (sender_abort),
   .timeout     (sender_timeout)
);

initial begin
    hotplug_detect  = 1'b0;
    sender_wr_en    = 1'b0;
    sender_wr_data  = 8'h00;
    sender_rd_en    = 1'b0;
    sender_abort    = 1'b0;
    sender_rd_en = 1'b0;
    sender_wr_en = 1'b0;
    sender_abort = 1'b0;
    
    #1000
    hotplug_detect = 1'b1;
    
	////////////////////////////////////////////////////
	// test timeout and retry
	////////////////////////////////////////////////////
	
    @(posedge go_next)
	#10
	
	#410000 hotplug_detect = 1'b1;
	
	@(posedge go_next)
	#10
    
    /////////////////////////////////////////////////////
    //  Reply to the read command
    //////////////////////////////////////////////////////
    sender_wr_data   = 8'h00;
    sender_wr_en  = 1'b1;
    #10
    sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    //  EDID Bloack 0
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10
    sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hFF; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hFF; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hFF; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hFF; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hFF; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hFF; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h5A; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h63; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h2F; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hCE; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h01; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h01; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h01; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h01; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    //  EDID Bloack 1
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10
    sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h29; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h18; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h01; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h04; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hB5; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h3E; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h22; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h78; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h3A; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h08; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hA5; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hA2; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h57; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h4F; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hA2; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h28; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    //  EDID Bloack 2
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10
    sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h0F; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h50; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h54; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hA5; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h4B; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h71; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h4F; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h81; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h81; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h80; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hA9; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h40; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hB3; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    //  EDID Bloack 3
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10
    sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hD1; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hC0; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hD1; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h01; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h01; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hA3; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h66; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hA0; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hF0; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h70; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h1f; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h80; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h30; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h20; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    //  EDID Bloack 4
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10
    sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h35; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h6D; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h55; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h21; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h1A; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hFF; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h55; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h32; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h4E; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;


    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    //  EDID Bloack 5
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10
    sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h31; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h34; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h34; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h31; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h30; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h30; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h30; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h38; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h38; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h0A; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hFC; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h56; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;


    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    //  EDID Bloack 6
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10
    sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h58; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h32; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h38; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h38; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h30; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h4D; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h4C; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h0A; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h20; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h20; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h20; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h20; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hFD; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;


    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    //  EDID Bloack 7
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10
    sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h18; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h55; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h1F; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h72; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h1E; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h0A; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h20; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h20; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h20; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h20; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h20; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h20; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h01; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h42; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    //  REPLY to READ SINK COUNT 90 02 00 00 00 01  
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h01; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10


    /////////////////////////////////////////////////////
    //  REPLY to READ CONFIG registers 
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h11; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h0A; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'hA4; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h01; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h01; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h01; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h81; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    // Reply to SET 8b/10b CODING
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    // Reply to SET LINK BANDWIDTH 
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    // Reply to SET DOWNSPREAD
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    // Reply to SET LANE COUNT
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    // Reply to SET TRAINING PATTERN
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    // Reply to SET VOLTAGE  ( request retry)!
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h20; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    // Reply to SET VOLTAGE 
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    // Reply to READ LINK STATUS (7 registers)
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = {lane_no{4'h1}}; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h80; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    // Reply to READ LINK ADJUST REQUST (2 regs)
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    // Reply to SET TRAINING PATTERN
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort  = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    // Reply to SET VOLTAGE 
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    // Reply to READ LINK STATUS (7 registers)
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = {lane_no{4'h7}}; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h81; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    // Reply to READ LINK ADJUST REQUST (2 regs)
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    @(posedge go_next)
	#10

    /////////////////////////////////////////////////////
    // Reply to SET TRAINING PATTERN OFF
    //////////////////////////////////////////////////////
    sender_abort = 1'b1;
    #10 sender_abort  = 1'b0;
    #10 sender_wr_data   = 8'h00; sender_wr_en  = 1'b1;
    #10 sender_wr_en  = 1'b0;

    #200000

    /////////////////////////////////////////////////////
    //  All done!
    ///////////////////////////////////////////////////
    sender_wr_en  = 1'b0;

    #200000000
    sender_wr_en  = 1'b0;

end     

endmodule

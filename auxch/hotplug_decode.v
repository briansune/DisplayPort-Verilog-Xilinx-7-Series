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
// fix parametric clock and timeout counters
// =======================================================================
// VESA DisplayPort (DP) Standard 2.0
// 5.1.4 Source Device Behavior upon HPD Pulse Detection
// IRQ: Sink Device wants to notify the Source Device that 
// sink’s status has changed so it toggles HPD
// line, forcing the Source Device to read its Link /
// Sink Status Receiver DPCD field via the AUX-CH 
// =======================================================================
// HDL File: hotplug_decode.v
// =======================================================================
// Programed By: BrianSune
// Contact: briansune@gmail.com
// =======================================================================

`timescale 1ns / 1ps

module hotplug_decode#(
	parameter clk_mhz = 100
)(
	input  wire        clk,

	input  wire        hpd,

	output reg         irq,
	output reg         present
);

   reg hpd_meta1;   // TODO Should also set ASYNC_REG
   reg hpd_meta2;   // TODO Should also set ASYNC_REG
   reg hpd_synced;
   reg hpd_last;

   reg [18:0] pulse_count;


initial begin
    hpd_meta1    = 1'b0;
    hpd_meta2    = 1'b0;
    hpd_synced   = 1'b0;
    hpd_last     = 1'b1;
    pulse_count  = 19'd0;
    present      = 1'b0;
    irq          = 1'b0;
end 
	
	// 100MHz = 1us/100 = 10ns
	// 1us = 100MHz * 100
	// 1ms = 1us * 1000
	// assume clock freq. range 10 to 150M
	
	// 2100 req. 11 bit -> max 2047
	// 10 to 200MH form 1us req 8 bit -> max 255
	// 19 bit is more than enough
	// $clog2 can be used but considered old Verilog
	
	localparam integer pulse_timeout_exit = (clk_mhz * 2200) - 1;
	localparam integer pulse_timeout_2ms  = (clk_mhz * 2000) - 1;
	localparam integer pulse_timeout_1ms  = (clk_mhz * 1000) - 1;

always @(posedge clk) begin
    irq <= 1'b0;
    if(hpd_last == 1'b0) begin
        if(hpd_synced == 1'b0) begin
            if(pulse_count >= pulse_timeout_2ms[18:0]) begin
                //--------------------------------
                // Sink has gone away for over 2ms
				// Case 2 (Hot Unplug Event)
                // No longer present
                //--------------------------------
                present <= 1'b0;
            end else begin
                pulse_count <= pulse_count + 1'b1;
            end
        end else begin
            //----------------------------------------
            // Timing the pulse to see if it is an IRQ
            //----------------------------------------
            if(pulse_count >= pulse_timeout_1ms[18:0]) begin
                //-----------------------------------
                // Case 1 (HPD IRQ Event)
                //-----------------------------------
                if(present == 1'b1) begin
                  irq <= present;
                end
            end
            pulse_count = 19'd0;
        end
    end else begin
        if(hpd_synced == 1'b0) begin
            pulse_count = 19'd0;            // Flip to other state
        end else begin
			//-----------------------------------
			// Case 3 (Hot Plug/Replug Event)
			//-----------------------------------
            if(pulse_count >= pulse_timeout_exit[18:0]) begin
                present <= 1'b1;                // Pulse seen long enough to be valid
            end else begin
                pulse_count <= pulse_count + 1'b1; // Time till the signal is valid for > 2ms
            end
        end
    end
	
    hpd_last   <= hpd_synced;
    
	// CCD w/o SRC latch
	hpd_synced <= hpd_meta1;
    hpd_meta1  <= hpd_meta2;
    hpd_meta2  <= hpd;
end

endmodule

// =======================================================================
// End of File
// =======================================================================

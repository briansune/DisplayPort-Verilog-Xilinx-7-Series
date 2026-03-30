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
// improved old testbench
// fix non-handshaking simulation
// readable mailbox reporting
// =======================================================================
// HDL File: tb_channel_management.sv
// =======================================================================
// Programed By: BrianSune
// Contact: briansune@gmail.com
// =======================================================================

`timescale 1ns / 1ps

import aux_pkg::*;

module tb_channel_management;
	
	logic	go_next = 0;
	
	logic	clk100 = 0;
	always	#5 clk100++;
	
	wire       hpd;
	wire       auxch_in;
	wire       auxch_out;
	wire       auxch_tri;

	// Datapath control
	wire       tx_clock_train;
	wire       tx_align_train;

	// Transceiver management
	wire [1:0] tx_powerup_channel;

	wire       tx_preemp_0p0;
	wire       tx_preemp_3p5;
	wire       tx_preemp_6p0;

	wire       tx_swing_0p4;
	wire       tx_swing_0p6;
	wire       tx_swing_0p8;

	wire       tx_link_established;
	
	dut_if aux_if_m(clk100);
	assign aux_if_m.sig = auxch_out;
	
	dut_if aux_if_s(clk100);
	assign aux_if_s.sig = auxch_in;
	
	mailbox #(aux_packet)		aux_bus = new();
	mailbox #(aux_packet_sink)	aux_bus_s = new();
	aux_if #(aux_packet)		aux_if_ck;
	aux_if #(aux_packet_sink)	aux_if_ck_s;
	
    initial begin
        aux_if_ck = new(aux_if_m, aux_bus); // The class now "sees" auxch_out through the cable
        aux_if_ck_s = new(aux_if_s, aux_bus_s); // The class now "sees" auxch_out through the cable
		
		#10;
		
		fork
			// Thread 1: The Monitor
			aux_if_ck.check_pulse_width(505.0);
			aux_if_ck_s.check_pulse_width(505.0);
			
			// Thread 2: The Receiver (Missing part!)
            forever begin
                aux_packet request_pkt;
				
                aux_bus.get(request_pkt); // Wait for a packet to arrive
                $display("[%t] TESTBENCH: Received Packet with %0d bits", $realtime, request_pkt.data_bits.size());
				request_pkt.display_payload();
				
				#1500 go_next = 0;
				#1500 go_next = 1;
				#1500 go_next = 0;
            end
			
			forever begin
				aux_packet_sink reply_pkt;
				
				aux_bus_s.get(reply_pkt); // Wait for a packet to arrive
                $display("[%t] TESTBENCH: Transmitted Packet with %0d bits", $realtime, reply_pkt.data_bits.size());
				reply_pkt.display_payload();
			end
		join_none
    end
	
	channel_management DUT(
		
		.clk100               (clk100),

		.hpd                  (hpd),
		.auxch_in             (auxch_in),
		.auxch_out            (auxch_out),
		.auxch_tri            (auxch_tri),

		// Datapath requirements
		.stream_channel_count (3'b001),
		.source_channel_count (3'b001),

		// Datapath control
		.tx_clock_train       (tx_clock_train),
		.tx_align_train       (tx_align_train),

		// Transceiver management
		.tx_powerup_channel   (tx_powerup_channel),

		.tx_preemp_0p0        (tx_preemp_0p0),
		.tx_preemp_3p5        (tx_preemp_3p5),
		.tx_preemp_6p0        (tx_preemp_6p0),
		
		.tx_swing_0p4         (tx_swing_0p4),
		.tx_swing_0p6         (tx_swing_0p6),
		.tx_swing_0p8         (tx_swing_0p8),

		.tx_link_established  (tx_link_established)
	);
	
	tb_dummy_sink DUT2(
		.clk100           (clk100),
		.go_next          (go_next),
		.auxch_data       (auxch_in),
		.hotplug_detect   (hpd)
	);
	
endmodule

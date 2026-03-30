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
// aux channel package: simulation use
// =======================================================================
// HDL File: aux_pkg.sv
// =======================================================================
// Programed By: BrianSune
// Contact: briansune@gmail.com
// =======================================================================

`timescale 1ns / 1ps

package aux_pkg;

class aux_packet;
    // Fields
    logic [3:0]  command;
    logic [19:0] address;
    logic [7:0]  data_bytes[$]; // Byte queue for payload
    logic        data_bits[$];  // Raw bit queue from monitor
    realtime     capture_time;

    // This function converts raw bits into DP fields
    function void parse_bits();
        logic [7:0] temp_byte;
        
        if (data_bits.size() < 24) return; // Not enough bits for Cmd + Addr

        // 1. Extract Command (First 4 bits)
        for(int i=0; i<4; i++) command[3-i] = data_bits.pop_front();

        // 2. Extract Address (Next 20 bits)
        for(int i=0; i<20; i++) address[19-i] = data_bits.pop_front();

        // 3. Extract Data Bytes (Remaining bits in groups of 8)
        while (data_bits.size() >= 8) begin
            for(int i=0; i<8; i++) temp_byte[7-i] = data_bits.pop_front();
            data_bytes.push_back(temp_byte);
        end
    endfunction

    function void display_payload();
        parse_bits(); // Process the bits before printing
        $display("\n--- AUX FRAME CAPTURED [%t] ---", capture_time);
        $display("COMMAND : %h (%s)", command, get_cmd_name(command));
        $display("ADDRESS : 0x%h", address);
        $write("DATA    : ");
        if (data_bytes.size() == 0) $write("None");
        else foreach(data_bytes[i]) $write("%h ", data_bytes[i]);
        $display("\n-------------------------------\n");
    endfunction

    // Helper to make the log readable
    function string get_cmd_name(logic [3:0] cmd);
        case(cmd)
			4'b0000: return "I2C_WRITE";
			4'b0001: return "I2C_READ";
			4'b1000: return "NATIVE_WRITE";
			4'b1001: return "NATIVE_READ";
			4'b0100: return "I2C_WRITE WITH MOT";
			4'b0101: return "I2C_READ WITH MOT";
			default: return "UNKNOWN";
        endcase
    endfunction
endclass

class aux_packet_sink;
    // Fields for Slave Response
    logic [3:0]  reply_code;      // 4-bit Reply (ACK, NACK, AUX_DEFER)
    logic [7:0]  data_bytes[$];   // Payload returned by Slave
    logic        data_bits[$];    // Raw bits from monitor
    realtime     capture_time;

    // Parses raw bits into Slave-specific fields
    function void parse_bits();
        logic [7:0] temp_byte;
		logic [3:0] reserved; // To capture the 4 zeros
        
        // Slave replies must have at least 4 bits (the reply code)
        if (data_bits.size() < 8) return; 

        // 1. Extract Reply Code (First 4 bits)
        for(int i=0; i<4; i++) reply_code[3-i] = data_bits.pop_front();
		
		// 2. Clear the 4 Reserved bits (The "4 zero" bug fix)
		for(int i=0; i<4; i++) reserved[3-i] = data_bits.pop_front();
		
		if (reserved != 4'b0000) begin
			$display("[%t] WARNING: AUX Slave Reserved bits not zero! (Got: %b)", $realtime, reserved);
		end

        // 3. Extract Data Bytes (Remaining bits in groups of 8)
        // Note: For some replies like NACK or DEFER, data_bits.size() will be 0
        while (data_bits.size() >= 8) begin
            temp_byte = 0;
            for(int i=0; i<8; i++) temp_byte[7-i] = data_bits.pop_front();
            data_bytes.push_back(temp_byte);
        end
    endfunction

    function void display_payload();
        parse_bits(); 
        $display("\n<<< AUX SLAVE REPLY [%t] >>>", capture_time);
        $display("REPLY CODE : %b (%s)", reply_code, get_reply_name(reply_code));
        
        $write("DATA       : ");
        if (data_bytes.size() == 0) $write("None (Control only)");
        else foreach(data_bytes[i]) $write("%h ", data_bytes[i]);
        
        $display("\n-------------------------------\n");
    endfunction

    // Helper to identify the Reply Type per DP Spec
    function string get_reply_name(logic [3:0] r_code);
        case(r_code)
            4'b0000: return "AUX_ACK / I2C ACK";
            4'b0001: return "AUX_NACK";
            4'b0010: return "AUX_DEFER";
            4'b0100: return "I2C_NACK";
            4'b1000: return "I2C_DEFER";
            default: return "INVALID/RESERVED";
        endcase
    endfunction
endclass

class aux_if #(type T = aux_packet);

	typedef enum logic [3:0] {
        I2C_WRITE    = 4'b0000,
        I2C_READ     = 4'b0001,
        NATIVE_WRITE = 4'b1000,
        NATIVE_READ  = 4'b1001
    } cmd_t;

	virtual dut_if vif;
	mailbox #(T) out_mbox; // The "Exit" for your data
	
	function new(virtual dut_if v, mailbox #(T) m);
        this.vif = v;
        this.out_mbox = m;
    endfunction

	task check_pulse_width(real max_duration_ns);
		
		T pkt;
		
		logic edge_type;
		logic sync_done;
		integer edge_count;
		integer package_bits;
		time start_time;
		logic mark_sync_end;
		logic packet_finished;
		
		forever begin
			
			sync_done = 0;
			edge_count = 0;
			package_bits = 0;
			packet_finished = 0;
			
			pkt = new(); 
            pkt.capture_time = $realtime;
			
			while (!packet_finished) begin
			
				@(vif.sig); // 1. Wait for the first rising edge
				edge_type = vif.sig;
				if(!sync_done)begin
					
					// this use for trace the upcoming bits
					if(edge_count == 0)
						start_time = $time;
					
					edge_count++;
					// $display("[%t] SYNC %d %d", $realtime, edge_count, edge_type);
				end else begin
					
					if(($time - start_time) % 1000 == 0)begin
						pkt.data_bits.push_back(~edge_type);
						// $display("[%t] Payload %d bit is %b", $realtime, package_bits, ~edge_type);
						package_bits++;
					end
				end

				fork : timeout_block
					begin
						// Thread A: Wait for the next rising edge
						@(vif.sig);
						edge_type = vif.sig;
						if(!sync_done)begin
							// $display("[%t] SYNC %d %d", $realtime, edge_count, edge_type);
						end else begin
							
							if(($time - start_time) % 1000 == 0)begin
								pkt.data_bits.push_back(~edge_type);
								// $display("[%t] Payload %d bit is %b", $realtime, package_bits, ~edge_type);
								package_bits++;
							end
						end
						
						if(!edge_type & mark_sync_end)begin
							// $display("[%t] SYNC END %d %d", $realtime, edge_count, edge_type);
							mark_sync_end = 0;
							
							if(sync_done)begin
								packet_finished = 1;
							end
							
							if(edge_count >= 25 && !sync_done)begin
								sync_done = 1'b1;
							end
						end
					end

					begin
						// Thread B: The watchdog timer
						// after edge trigger the Manchester II for DP AUX is 1MHz aka 1000ns window
						// 
						#(max_duration_ns * 3);
						
						// $display("[%t] SYNC END %d %d", $realtime, edge_count, edge_type);
						
						// positive edge
						if(edge_type)begin
							mark_sync_end = 1;
						end

						#(max_duration_ns * 2);

						// $error("[%t] TIMEOUT: Not Valid AUX protocol discovered!", $realtime);
					end
				join_any

				// Kill the thread that "lost" the race so it doesn't stay active
				disable timeout_block;
			end
			
			// 3. Send the completed packet out
			out_mbox.put(pkt);
			$display("[%t] AUX Packet Sent to Mailbox", $realtime);
			
			// Reset for next message
			packet_finished = 0;
		end
	endtask
endclass

endpackage

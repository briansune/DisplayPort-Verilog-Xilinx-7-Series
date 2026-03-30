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
//	0.9.1	| fix LUT wrong contents
//	0.9.1	| fix symbols repetition requirements
//			| 2.2.1.1 Control Symbols for Framing: Default Framing Mode
// =======================================================================
// HDL File: idle_pattern_inserter.v
// =======================================================================
// Programed By: BrianSune
// Contact: briansune@gmail.com
// =======================================================================

`timescale 1ns / 1ps

module idle_pattern_inserter#(
	parameter fpga_family = "",
	parameter integer lane_num = 2
)( 

	input  wire              clk,

	input  wire    [2:0]     stream_channel_count,

	input  wire              channel_ready,
	input  wire              source_ready,

	input  wire    [72:0]    in_data,
	output reg     [71:0]    out_data
);


    reg [16:0] count_to_switch;
    reg        source_ready_last;
    reg        idle_switch_point;
    
    reg [12:0] idle_count;    

    localparam [8:0] DUMMY  = 9'b000000000;   // dummy data symbol D0.0
    localparam [8:0] BS     = 9'b110111100;   // K28.5
    localparam [8:0] VB_ID  = 9'b000001001;   // 0x09  VB-ID with no video asserted 
    localparam [8:0] Mvid   = 9'b000000000;   // 0x00
    localparam [8:0] Maud   = 9'b000000000;   // 0x00    

    reg [17:0] idle_data;
    wire       channel_ready_w;

	generate
		if(fpga_family == "")begin : vlsi_init
			
			reg        channel_ready_i;
			reg        channel_ready_meta;
			
			assign channel_ready_w = channel_ready_i;
			
			initial begin
				channel_ready_i    = 1'b0;
				channel_ready_meta = 1'b0;
			end
			
			// CCD
			always @(posedge clk) begin
				channel_ready_i     <= channel_ready_meta; 
				channel_ready_meta  <= channel_ready;
			end
		end
	endgenerate
	
	initial begin
		out_data           = 72'b0;
		idle_data          = 18'b0;
		count_to_switch    = 17'b0;
		idle_count         = 13'b0;
	end
	
	generate
		if(fpga_family == "ALTERA_C5")begin : cyclone_v_fpga
			altera_std_synchronizer#(
				.depth		(3)
			)ccd_100to135_u(
				.clk		(clk),
				.reset_n	(1'b1),
				.din		(channel_ready),
				.dout		(channel_ready_w)
			);
		end
	endgenerate
	
always @(posedge clk) begin
    if(count_to_switch[16] == 1'b1) begin
        out_data  <= in_data[71:0];
    end else begin
        // send idle pattern
        out_data <= {4{idle_data}};
    end
    
    if(count_to_switch[16] == 1'b0) begin
        //------------------------------------------------------
        // The last tick over requires the source to be ready
        // and to be asserting that it is in the switch point.
        //------------------------------------------------------
        if(count_to_switch[15:0] == 16'hFFFF) begin
            //-------------------------------------
            // Bit 72 is the switch point indicator
            //-------------------------------------
            if(source_ready == 1'b1 && in_data[72] == 1'b1 && idle_switch_point == 1'b1) begin
               count_to_switch <= count_to_switch + 1'b1;
            end
        end else begin
            //------------------------------------------------------
            // Wait while we send out at least 64k of idle patterns
            //------------------------------------------------------
            count_to_switch <= count_to_switch + 1'b1;
        end
    end

    //-----------------------------------------------------------------------
    // If either the source drops or the channel is not ready, then reset
    // to emitting the idle pattern. 
    //-----------------------------------------------------------------------
    if(channel_ready_w == 1'b0 || (source_ready == 1'b0 && source_ready_last == 1'b1)) begin
        count_to_switch <= 17'b0;
    end
    source_ready_last  <= source_ready;

    //------------------------------------------------------
    // We can either be odd or even aligned, depending on
    //  where the last BS symbol was seen. We need to send
    //  the next one 8192 symbols later (4096 cycles)
    //------------------------------------------------------
    idle_switch_point <= 1'b0;
	
	if(stream_channel_count == 3'd4)begin
		case(idle_count)
			// For the even alignment
			0:	idle_data <= {DUMMY, DUMMY};
			2:	idle_data <= {VB_ID, BS   };
			4:	idle_data <= {Maud,  Mvid };
			// For the odd alignment
			1:	idle_data <= {BS,    DUMMY};
			3:	idle_data <= {Mvid,  VB_ID};             
			5:	idle_data <= {DUMMY, Maud };
			default: begin
				idle_data <= {DUMMY, DUMMY}; // can switch to the actual video at any other time
				idle_switch_point <= 1'b1;   // other than when the BS, VB-ID, Mvid, Maud sequence
			end
		endcase
	end else if(stream_channel_count == 3'd2)begin
		case(idle_count)
			// For the even alignment
			0:	idle_data <= {DUMMY, DUMMY};
			2:	idle_data <= {VB_ID, BS   };
			4:	idle_data <= {Maud,  Mvid };
			6:	idle_data <= {Mvid,  VB_ID};
			8:	idle_data <= {DUMMY, Maud };
			// For the odd alignment
			1:	idle_data <= {BS,    DUMMY};
			3:	idle_data <= {Mvid,  VB_ID};             
			5:	idle_data <= {VB_ID, Maud };
			7:	idle_data <= {Maud,  Mvid };
			default: begin
				idle_data <= {DUMMY, DUMMY}; // can switch to the actual video at any other time
				idle_switch_point <= 1'b1;   // other than when the BS, VB-ID, Mvid, Maud sequence
			end
		endcase
	end else begin
		case(idle_count)
			// For the even alignment
			0:	idle_data <= {DUMMY, DUMMY};
			2:	idle_data <= {VB_ID, BS   };
			4:	idle_data <= {Maud,  Mvid };
			6:	idle_data <= {Mvid,  VB_ID};
			8:	idle_data <= {VB_ID, Maud };
			10:	idle_data <= {Maud,  Mvid };
			12:	idle_data <= {Mvid,  VB_ID};
			14:	idle_data <= {DUMMY, Maud };
			// For the odd alignment
			1:	idle_data <= {BS,    DUMMY};
			3:	idle_data <= {Mvid,  VB_ID};             
			5:	idle_data <= {VB_ID, Maud };
			7:	idle_data <= {Maud,  Mvid };
			9:	idle_data <= {Mvid,  VB_ID};
			11:	idle_data <= {VB_ID, Maud };
			13:	idle_data <= {Maud,  Mvid };
			15:	idle_data <= {DUMMY, DUMMY};
			default: begin
				idle_data <= {DUMMY, DUMMY}; // can switch to the actual video at any other time
				idle_switch_point <= 1'b1;   // other than when the BS, VB-ID, Mvid, Maud sequence
			end
		endcase
	end

    //------------------------------------------------------ 
	// 2.2.1.1 Control Symbols for Framing: Default Framing Mode
    //------------------------------------------------------ 
    // Sync with the BS stream of the input signal but only 
    // if we are switched over to it (indicated by the high
    // bit of count_to_switch being set)
    //------------------------------------------------------ 
    if(count_to_switch[16] == 1'b1) begin
        if(in_data[8:0] == BS) begin
            idle_count <= 13'd2;
        end else if(in_data[17:9] == BS) begin
            idle_count <= 13'd1;
        end 
    end

	idle_count <= idle_count + 2'd2;
end

endmodule

// =======================================================================
// End of File
// =======================================================================

`timescale 1ns / 1ps
`default_nettype none	//To avoid bugs involving implicit nets

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Acknowledgements: Prof. Kyle Gilsdorf (Arizona State)
//								- http://www.public.asu.edu/~kyle135/
//								- Kyle.Gilsdorf@asu.edu 
//
//
// Author:	 Rushang Vinod Vandana Karia 
//					- Masters in Computer Science @ Arizona State
//					- Rushang.Karia@asu.edu
//					- 4806283130
//					- github.com/RushangKaria
//
//
// Module: Input_Sync.v
//
//
// Description : Synchronizer for the MSEL with the TFT Clock
//						
// Copyright : Copyright (C) 2014 Rushang Vinod Vandana Karia
//
//					This program is free software; you can redistribute it and/or
//					modify it under the terms of the GNU General Public License
//					as published by the Free Software Foundation; either version 2
//					of the License, or (at your option) any later version.
//
//					This program is distributed in the hope that it will be useful,
//					but WITHOUT ANY WARRANTY; without even the implied warranty of
//					MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//					GNU General Public License for more details.
//
//					You should have received a copy of the GNU General Public License
//					along with this program; if not, write to the Free Software
//					Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

module InputSyncV #(parameter WIDTH=4)
(
input 	wire					CLK_I,
input		wire	[3:0]			D_I,
output	wire	[3:0]			D_O
);

///////////////////////////////////////////////////////////////////////////////////////
// SYNTHESIS SPECIFIC INSTRUCTIONS
///////////////////////////////////////////////////////////////////////////////////////

//synthesis attribute TIG of D_I is "TRUE"
//synthesis attribute IOB of D_I is "FALSE"
//synthesis attribute ASYNC_REG of sreg is "TRUE"
//synthesis attribute SHIFT_EXTRACT of sreg is "NO"
//synthesis attribute HBLKMN of sreg is "sync_reg"

//////////////////////////////////
// SYNC PROCESS
//////////////////////////////////

genvar i;

		generate							
				for(i=3;i>=0;i=i-1)
				begin
					InputSync input_sync_inst
								(
								.CLK_I		(CLK_I),
								.D_I			(D_I[i]),
								.D_O			(D_O[i])
								);
				end
		endgenerate
		
endmodule

module InputSync
(
input		wire		D_I,
input		wire		CLK_I,
output	reg		D_O
);

///////////////////////////////////////////////////////////////////////////////////////
// SIGNALS LOCAL TO MODULE
///////////////////////////////////////////////////////////////////////////////////////

reg 	[1:0]		sreg;

///////////////////////////////////////////////////////////////////////////////////////
// SYNTHESIS SPECIFIC INSTRUCTIONS
///////////////////////////////////////////////////////////////////////////////////////

//synthesis attribute TIG of D_I is "TRUE"
//synthesis attribute IOB of D_I is "FALSE"
//synthesis attribute ASYNC_REG of sreg is "TRUE"
//synthesis attribute SHIFT_EXTRACT of sreg is "NO"
//synthesis attribute HBLKMN of sreg is "sync_reg"


//////////////////////////////////
// SYNC PROCESS
//////////////////////////////////

	always@(posedge CLK_I)
		begin
			D_O	<=	sreg[1];
			sreg	<=	{sreg[0],D_I};
		end
			
endmodule


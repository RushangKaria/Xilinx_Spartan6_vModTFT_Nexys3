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
// Module: Local_Reset.v
//
//
// Description : 	Local reset for the Timing Controller
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

module Local_Reset #(
							parameter
							RESET_PERIOD	=	4
							)
(
input		wire		CLK_I,
input		wire		RST_I,
output	wire		SRST_O
);

///////////////////////////////////////////////////////////////////////////////////////
// SIGNALS LOCAL TO MODULE
///////////////////////////////////////////////////////////////////////////////////////

reg 	[RESET_PERIOD:0]	RstQ;

///////////////////////////////////////////////////////////////////////////////////////
// SYNTHESIS SPECIFIC INSTRUCTIONS
///////////////////////////////////////////////////////////////////////////////////////

	initial
		begin
			RstQ[RESET_PERIOD:1]={RESET_PERIOD{1'b1}};
			RstQ[0]=1'b0;
		end

///////////////////////////////////////////////////////////////////////////////////////
// RESET PROCESS	::	This process generates a reset signal that is high
//						:: for PERIOD-1 clocks. It does this by loading the registers 
//						:: as 1111....0 and then left shifting by 0 per clock
///////////////////////////////////////////////////////////////////////////////////////

always
RstQ[0] = 1'b0;


genvar i;

		generate
			for(i=1;i<RESET_PERIOD+1;i=i+1)
				always@(posedge CLK_I)
					if(RST_I)
					RstQ[i]	<=	1;
					else
					RstQ[i]	<=	RstQ[i-1];
		endgenerate

	assign SRST_O	=	RstQ[RESET_PERIOD];


endmodule

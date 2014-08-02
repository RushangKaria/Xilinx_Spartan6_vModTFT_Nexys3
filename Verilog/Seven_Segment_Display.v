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
// Module: Seven_Segment_Display.v
//
//
// Description : 	Seven segment display used to display x,y or pressure values
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

module Seven_Segment_Display #(
										parameter	
										CLOCKFREQ	= 100,	//MHz
										DIGITS		= 4
										)
														
(
input		wire								CLK_I,
input		wire		[DIGITS*4-1:0]		DATA_I,
input		wire		[DIGITS-1:0]		DOTS_I,
output	reg		[DIGITS-1:0]		AN_O,
output	wire		[7:0]					CA_O
);

///////////////////////////////////////////////////////////////////////
// MODULE SPECIFIC PARAMETER DECLARATIONS
///////////////////////////////////////////////////////////////////////

	parameter 	integer		DISP_FREQ			=	20*DIGITS;
	parameter	integer		DISP_FREQ_CYCLES	=	(CLOCKFREQ*1000/DISP_FREQ);	//Check this
	
	parameter					ZERO					=	7'b1000000;	//Codes for the cathode ray tubes
	parameter					ONE					=	7'b1111001;	
	parameter					TWO					=	7'b0100100;
	parameter					THREE					=	7'b0110000;
	parameter					FOUR					=	7'b0011001;
	parameter					FIVE					=	7'b0010010;
	parameter					SIX					=	7'b0000010;
	parameter					SEVEN					=	7'b1111000;		
	parameter					EIGHT					=	7'b0000000;
	parameter					NINE					=	7'b0010000;
	parameter					A						=	7'b0001000;	//"A"
	parameter					B						=	7'b0000011;
	parameter					C						=	7'b1000110;
	parameter					D						=	7'b0100001;
	parameter					E						=	7'b0000110;
	parameter					F						=	7'b0001110;
	parameter					DEFAULT				=	7'b0001001;	//"H" is the default. Not required here since we cover all cases
	
///////////////////////////////////////////////////////////////////////
// PORTS ORIGINATING IN MODULE
///////////////////////////////////////////////////////////////////////

	reg		[$clog2(DISP_FREQ_CYCLES)-1:0]		refreshCnt;
	reg		[$clog2(DIGITS)-1:0]						DigitNo;
	reg		[3:0]											Digit;
	reg		[6:0]											HexDigit;
	wire														Dot;
	wire														DisplayCLK;

///////////////////////////////////////////////////////////////////////////////////////
// SYNTHESIS SPECIFIC INSTRUCTIONS
///////////////////////////////////////////////////////////////////////////////////////

	initial
		begin
			refreshCnt	=	'b0;
			DigitNo		=	'b0;
		end
	
///////////////////////////////////////////////////////////////////////
// DISPLAY PROCESS
///////////////////////////////////////////////////////////////////////	

	always@(Digit)
		case(Digit)
			0	:	HexDigit	=	ZERO;
			1	:	HexDigit	=	ONE;
			2	:	HexDigit	=	TWO;
			3	:	HexDigit	=	THREE;
			4	:	HexDigit	=	FOUR;
			5	:	HexDigit	=	FIVE;
			6	:	HexDigit	=	SIX;
			7	:	HexDigit	=	SEVEN;
			8	:	HexDigit	=	EIGHT;
			9	:	HexDigit	=	NINE;
			10	:	HexDigit	=	A;
			11	:	HexDigit	=	B;	
			12	:	HexDigit	=	C;
			13	:	HexDigit	=	D;	
			14	:	HexDigit	=	E;
			15	:	HexDigit	=	F;
			
			default:	HexDigit	=	DEFAULT;
		endcase
		
	always@(DATA_I,DigitNo)
		case(DigitNo)
        0   :  Digit = DATA_I[3:0];
        1  	:	Digit = DATA_I[7:4];
        2   :  Digit = DATA_I[11:8];
        3   :  Digit = DATA_I[15:12];
		  
			default: Digit = DEFAULT;
		endcase
	
	assign	Dot	=	~DOTS_I[DigitNo];
	assign	CA_O	=	{Dot,HexDigit};
	
		always@(posedge CLK_I)
			if(refreshCnt	==	DISP_FREQ_CYCLES-1)
			refreshCnt	<=	'b0;
			else
			refreshCnt	<=	refreshCnt + 1'b1;
			
		always@(posedge CLK_I)
			if(refreshCnt	==	DISP_FREQ_CYCLES-1)
				if((DigitNo+1) ==	DIGITS)
				DigitNo	<=	'b0;
				else
				DigitNo	<=	DigitNo + 1'b1;
				
		always@(DigitNo)
			begin
				AN_O				<=	4'hF;
				AN_O[DigitNo]	<=	1'b0;
			end
		
	
endmodule

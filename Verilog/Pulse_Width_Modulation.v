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
// Module: Pulse_Width_Modulation.v
//
//
// Description : 	Modulate the backlight so that we can the pixels are cleary
//						visible
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

module Pulse_Width_Modulation 	#(
												parameter
												C_CLK_I_FREQUENCY		=	50,		//MHz
												C_PWM_FREQUENCY		=	20000,	//KHz
												C_PWM_RESOLUTION		=	8
											)
(
input		wire											CLK_I,
input		wire											RST_I,
input		wire		[C_PWM_RESOLUTION-1:0]		DUTY_FACTOR_I,
output	wire											PWM_O
);

///////////////////////////////////////////////////////////////////////
// MODULE SPECIFIC PARAMETER DECLARATIONS
///////////////////////////////////////////////////////////////////////

	parameter	integer		C_CLOCK_DIVIDER	=	C_CLK_I_FREQUENCY*1000000/C_PWM_FREQUENCY/2/2**C_PWM_RESOLUTION;
	
///////////////////////////////////////////////////////////////////////
// PORTS ORIGINATING IN MODULE
///////////////////////////////////////////////////////////////////////

	reg 		[C_PWM_RESOLUTION-1:0]				PWMCnt;
	reg													PWMCntEn;
	reg													int_PWM;
	reg		[$clog2(C_CLOCK_DIVIDER):0]		PSCnt;
	reg													PWMCntUp;
///////////////////////////////////////////////////////////////////////////////////////
// SYNTHESIS SPECIFIC INSTRUCTIONS
///////////////////////////////////////////////////////////////////////////////////////

		initial
			begin
				PWMCnt	=	'b0;
				PSCnt		=	'b0;
				PWMCntUp	=	1'b0;
			end
			
///////////////////////////////////////////////////////////////////////
// PRE-SCALER
///////////////////////////////////////////////////////////////////////

	always@(posedge CLK_I)
		if(PSCnt	==	C_CLOCK_DIVIDER)
			begin
				PSCnt			<=	'b0;
				PWMCntEn		<=	1'b1;
			end
		else
			begin
				PSCnt			<=	PSCnt + 1;
				PWMCntEn		<=	1'b0;
			end
			
///////////////////////////////////////////////////////////////////////
// Up/Down counter for mid-aligned PWM pulse
//	In designs with multiple PWM chanels mid-alignment eliminates
//	simultaneously
//	
//	switching PWM outputs, resulting in less stress on power rails
///////////////////////////////////////////////////////////////////////
	
		always@(posedge CLK_I)					//This implementation is weird....variables used in the VHDL code
			begin
			//{
				if(RST_I)
				PWMCnt	<=	'b0;	
				else if(PWMCntEn)
							if(PWMCntUp)
							PWMCnt	<=	PWMCnt + 1;
							else
							PWMCnt	<=	PWMCnt - 1;
							
				if(PWMCnt==0)
				PWMCntUp	<=	1'b1;
				else if(PWMCnt	==	2**C_PWM_RESOLUTION-1)
				PWMCntUp	<=	1'b0;
			//}
			end
			
///////////////////////////////////////////////////////////////////////
// PWM OUTPUT
///////////////////////////////////////////////////////////////////////

	always@(posedge CLK_I)
		if(PWMCnt < DUTY_FACTOR_I)
		int_PWM	<=	1'b1;
		else
		int_PWM	<=	1'b0;
		
	assign PWM_O	=	(RST_I)?'bz:int_PWM;

endmodule

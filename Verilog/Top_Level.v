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
// Module: Top_Level.v
//
//
// Description : 	A Verilog port for the vModTFT SimplePaint Example for the 
//						Xilinx Nexys3 SPARTAN 6 FPGA board.
//	
//	Links 		: https://www.digilentinc.com
//					: https://digilentinc.com/Products/Detail.cfm?NavPath=2,648,979&Prod=VMOD-TFT
//					: https://digilentinc.com/Data/Documents/Demonstration%20Project/VmodTFT%20Simple%20Paint%20DEMO.zip
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

///////////////////////////////////////////////////////////////////////
// DESIGN PORT-PIN CONNECTIONS TO NEXYS3
///////////////////////////////////////////////////////////////////////

/*
* Top level module is required to connect the 
* various physical signals on the board. Refer
* to the .ucf files to see the pins
*/

module Top_Level
(
input		wire					CLK_I,					//The clock signal of the board. We sample it to get a new clock
input		wire					BTNM_I,					//The reset signal for the design
input		wire		[7:0]		SW_I,						//Buttons to indicate modes
input		wire					TP_BUSY_I,				//Deprecated but included for the sake of completeness
input		wire					TP_PENIRQ_I,			//Deprecated but included for the sake of completeness
input		wire					TP_DOUT_I,				//Serial input line
output	wire		[7:0]		TFT_R_O,    			//RED component of the TFT pixel bus
output	wire		[7:0]		TFT_G_O,					//GREEN component of the TFT pixel bus
output	wire		[7:0]		TFT_B_O, 				//BLUE componenet of the TFT pixel bus
output	wire					TFT_CLK_O,				//TFT Clock @ 9 MHz
output	wire					TFT_DE_O,				//Please refer to the spec for details
output	wire					TFT_BKLT_O,				// ---------------- " -----------------
output	wire					TFT_VDDEN_O,			// ---------------- " -----------------
output	wire					TFT_DISP_O,				// ---------------- " -----------------
output	wire					TP_CS_O,					// ---------------- " -----------------
output	wire					TP_DIN_O,				// ---------------- " -----------------
output	wire					TP_DCLK_O,				// ---------------- " -----------------
output	wire		[3:0]		AN_O,						//Anodes of the seven segment display
output	wire		[7:0]		SEG_O						//Cathodes of the seven segment display
);

///////////////////////////////////////////////////////////////////////
// DESIGN SPECIFIC PARAMETER DECLARATIONS
///////////////////////////////////////////////////////////////////////

`include"resolutions.v"												//Some constants specific to the TFT
`include"video_rom.v"												//are imported from here
`include"touch_panel.v"	

parameter 	integer 		Z_high					= 1500;		//The highest pressure that the screen can be touched and a response elicited
parameter 	integer 		Z_low						= 200;		//The lowest pressure that must be applied to the screen to elicite a response
parameter 	integer 		SCALING_FACTOR			= 12;
parameter 	integer 		SCALING_FACTOR_2		= 2**SCALING_FACTOR;
parameter 	integer	 	X_SCALING				= (H_480_272p_AV*SCALING_FACTOR_2)/(TopRight_X-TopLeft_X);		//Constants to scale the values to 
parameter 	integer		Y_SCALING				= (V_480_272p_AV*SCALING_FACTOR_2)/(BottomLeft_Y-TopLeft_Y);	//our resolution. Make sure to change this
																																				//if you want a different resolution
///////////////////////////////////////////////////////////////////////////////////////
// INTERNAL SIGNALS
///////////////////////////////////////////////////////////////////////////////////////

wire	[11:0]										TouchXNorm1;		//These signals are used to
wire	[11:0]										TouchYNorm1;		//scale the X,Y co-ordinates
reg	[11+SCALING_FACTOR:0]					TouchXNorm2;		//so that absolute X,Y can
reg	[11+SCALING_FACTOR:0]					TouchYNorm2;		//be still displayed correctly
wire	[$clog2(H_480_272p_AV):0]				TouchXNorm;			//independent of the resolution
wire	[$clog2(V_480_272p_AV):0]				TouchYNorm;
reg													TouchEn;

wire													TFTClk;
wire													TFTClk180;			//Out of phase clock
wire													SysRst;				//Global Reset
wire													SysClk;				//System Clock @ 100 MHz
wire	[3:0]											TFTMsel;				//Mode select

wire	[11:0]										TouchX;				//Absolute co-ordinates
wire	[11:0]										TouchY;
wire	[11:0]										TouchZ;				//Pressure applied

reg	[15:0]										DispData;

///////////////////////////////////////////////////////////////////////////////////////
// SYNTHESIS SPECIFIC INSTRUCTIONS : Options for the synthesis tool. NON_PORTABLE
///////////////////////////////////////////////////////////////////////////////////////

//synthesis attribute KEEP of TouchXNorm is "TRUE"
//synthesis attribute KEEP of TouchYNorm is "TRUE"

///////////////////////////////////////////////////////////////////////////////////////
// MODULE INSTANTIATIONS
///////////////////////////////////////////////////////////////////////////////////////

/*
* This module provides the stable clocks,
* global reset and intensity modes.
* It contains a PLL so that the clocks
* are stable
*/

System_Control_Unit 			scu
									(
										.CLK_I					(CLK_I),			//The hardware clock on the board
										.RSTN_I					(BTNM_I),	
										.SW_I						(SW_I),		
										.CLK_O					(SysClk),		//System clock that is used by the design
										.TFT_CLK_O				(TFTClk),		//TFT Clock
										.TFT_CLK_180_O			(TFTClk180),
										.MSEL_O					(TFTMsel),		//Mode Select
										.ASYNC_RST				(SysRst)			//Global Reset
									);
									
/*
* This module is the TFT Controller which 
* controls the displaying of the data.
* It is responsible for initializing the 
* TFT and implementing the display 
* protocols. Refer to the spec for 
* protocol details
*/									
									
TftCtl							tft_controller
									(
										.CLK_I					(TFTClk),				//TFT clock
										.CLK_180_I				(TFTClk180),
										.RST_I					(SysRst),
										.X_I						(TouchXNorm),			//Scaled X co-ordinate
										.Y_I						(TouchYNorm),			//Scaled Y co-ordinate
										.Z_I						(TouchZ),				//Pressure value
										.WE_I						(TouchEn),				//Write enable if pressure is within bounds
										.WR_CLK					(SysClk),				//System clock
										.R_O						(TFT_R_O),
										.G_O						(TFT_G_O),
										.B_O						(TFT_B_O),
										.DE_O						(TFT_DE_O),
										.CLK_O					(TFT_CLK_O),
										.DISP_O					(TFT_DISP_O),
										.BKLT_O					(TFT_BKLT_O),
										.VDDEN_O					(TFT_VDDEN_O),
										.MSEL_I					(TFTMsel)
									);

/*
* This module represents the touch controller
* which detects touch and generates the 
* X,Y and pressure values. These values are
* absolute.
*/

Touch_Controller 				#(
										.CLOCKFREQ				(100)
									) 
							touch_controller 
									(
										.CLK_I					(SysClk),
										.RST_I					(SysRst),
										.X_O						(TouchX),				//Absolute X (Normalized)
										.Y_O						(TouchY),				//Absolute Y (Normalized)
										.Z_O						(TouchZ),				//Absolute Z
										.PENIRQ_I				(TP_PENIRQ_I),			
										.CS_O						(TP_CS_O),
										.DIN_O					(TP_DIN_O),
										.DOUT_I					(TP_DOUT_I),
										.DCLK_O					(TP_DCLK_O),
										.BUSY_I					(TP_BUSY_I)
									);
/*
* This module displays the 
* data on the seven segment
* display. Primarily used to 
* debug and observe values.
* 
* The values that can be shown
* are Absolute X,Y, pressure
*/
Seven_Segment_Display #(
								.CLOCKFREQ					(100),
								.DIGITS						(4)
								)
								ssd
								(
									.CLK_I					(SysClk),
									.DATA_I					(DispData),					//Data to display
									.DOTS_I					(4'h0),						//We disable dots
									.AN_O						(AN_O),
									.CA_O						(SEG_O)
								);
								
///////////////////////////////////////////////////////////////////////////////////////
// PROCESS TOUCH DATA 	:: This is the process that processes the touch co-ordinates 
//								:: and determines if they can be displayed on the screen
//
///////////////////////////////////////////////////////////////////////////////////////

	assign TouchXNorm1	=	TouchX-TopLeft_X[11:0];				//Please refer to how to normalize and scale
	assign TouchYNorm1	=	TouchY-TopLeft_Y[11:0];				//a display for more details of why this is done.
																				//[11:0] is done to prevent warnings. 

	always@(posedge SysClk)
		begin
			TouchXNorm2	<=	TouchXNorm1*X_SCALING;			//Scale X co-ordinate by resolution
			TouchYNorm2	<=	TouchYNorm1*Y_SCALING;			//Scale Y co-ordinate by resoulution
			
				if(TouchZ < Z_high && TouchZ > Z_low)		//If pressure applied is within range
				TouchEn	<=	1'b1;									//enable the writing of data
				else													//We constrain high pressure values to 
				TouchEn 	<= 1'b0;									//dissuade damage to the device
		end

	assign TouchXNorm	=	TouchXNorm2[11+SCALING_FACTOR:SCALING_FACTOR];		//We use the higher order bits to get the final
	assign TouchYNorm	=	TouchYNorm2[11+SCALING_FACTOR:SCALING_FACTOR];		//scaled values

		always@*
			case(SW_I[7:6])
				00			:	DispData	=	{4'h0,TouchX};		//Choose which co-ordinates to display on the 
				01			:	DispData	=	{4'h0,TouchY};		//seven segment display based on the buttons.
				default	:	DispData	=	{4'h0,TouchZ};		//Very useful for debugging!!
			endcase




endmodule

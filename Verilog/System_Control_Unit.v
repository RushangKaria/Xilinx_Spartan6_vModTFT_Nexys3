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
// Module: System_Control_Unit.v
//
// Description : 	This module uses a PLL to stabilize all the clocks
//						and also generates a global reset
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

module System_Control_Unit
(
input		wire				CLK_I,					//Input System Clock	
input		wire				RSTN_I,					//Input Reset
input		wire	[7:0]    SW_I,						
output	wire				CLK_O,					//Output Stable Clock
output	wire				TFT_CLK_O,				//Output Stable TFT Clock
output	wire				TFT_CLK_180_O,
output	wire	[3:0]		MSEL_O,
output	wire				ASYNC_RST				//Global Asynchronous Reset
);

///////////////////////////////////////////////////////////////////////
// MODULE SPECIFIC PARAMETER DECLARATIONS
///////////////////////////////////////////////////////////////////////

parameter	integer		RST_SYNC_NUM			= 100;
parameter	integer		RST_DBNC					= 10;
parameter	integer		RST_SYNC_NUM_LENGTH	= $clog2(RST_SYNC_NUM);

parameter					VDD						= 1'b1;
parameter 					GROUND 					= 1'b0;

genvar i;

///////////////////////////////////////////////////////////////////////////////////////
// SIGNALS LOCAL TO MODULE
///////////////////////////////////////////////////////////////////////////////////////


wire										Start_Up_Rst;
wire										DcmRst;
reg										DcmLckd;
wire										SysConCLK;

reg	[RST_DBNC-1:0]					RstDbncQ;
reg	[RST_DBNC-1:0]					RstDbncTemp;
wire										intRst;
	
reg										intfb;
reg										intpllout_xs;

reg	[7:0]								int_sw;

reg 	[RST_SYNC_NUM-1:0]			RstQ;
reg	[RST_SYNC_NUM_LENGTH:0]		RstD;
wire										RstDbnc;
wire										int_TFTClk;

///////////////////////////////////////////////////////////////////////////////////////
// SYNTHESIS SPECIFIC INSTRUCTIONS
///////////////////////////////////////////////////////////////////////////////////////

//synthesis attribute KEEP of async_rst is "TRUE"

initial				
	begin
		RstQ[RST_SYNC_NUM-1]				=	0;
		RstQ[RST_SYNC_NUM-2:0]			=	{RST_SYNC_NUM-1{1'b1}};
		
		RstD[RST_SYNC_NUM_LENGTH:0]	=	{1'b1,RST_SYNC_NUM[RST_SYNC_NUM_LENGTH-1:0]};
	end
	
///////////////////////////////////////////////////////////////////////////////////////
// COMPONENT INSTANTIATIONS 	:: These are required core files for the architecture
//										:: These are board specific implementations so may not
//										:: work for different architectures
///////////////////////////////////////////////////////////////////////////////////////

	IBUFG IBUGF_inst
			(
				.O					(SysConCLK),	//Stable clock
				.I					(CLK_I)			//Input unstable clock
			);
			
	assign CLK_O	=	SysConCLK;

	dcm_TFT9 DCM_inst			//Digital control manager. To generate clock for the TFT @ 9Mhz
				(
					.CLK_IN1 	(SysConCLK),		//Clock in
					.CLK9			(int_TFTClk),		//Clock out @ 9MHz
					.CLK9_180	(TFT_CLK_180_O),	//Clock out @ 9MHz out of phase with CLK9
					.RESET		(DcmRst),			//Status and Control
					.LOCKED		(DcmLckd)			//Status and Control
				);
	
	SRL16 #(
				.INIT				(16'h000F)
			 )
			SRL16_inst					
			(
					.CLK			(SysConCLK),		//Input Clock
					.Q				(Start_Up_Rst),	//Data output
					.A0			(VDD),				//Select this line
					.A1			(VDD),				//Select this line
					.A2			(GROUND),				//Do not select this line
					.A3			(GROUND),				//Do not select this line
					.D				(GROUND)					//SRL data input
			);

	assign TFT_CLK_O	=	int_TFTClk;					//Assign the TFT clock
	
//////////////////////////////////////////////////////////
// DEBOUNCE RESET
//////////////////////////////////////////////////////////	

	always@(RSTN_I)
	RstDbncQ[0]	=	~RSTN_I;

			generate
				for(i=1;i<RST_DBNC;i=i+1)		
					always@(posedge SysConCLK)
					RstDbncQ[i]	<=	RstDbncQ[i-1];
			endgenerate
			
	always@(RstDbncQ[0])
	RstDbncTemp[0]	=	RstDbncQ[0];
			
			generate
				for(i=1;i<RST_DBNC-1;i=i+1)	
					always@*
					RstDbncTemp[i]	<=	RstDbncTemp[i-1] & RstDbncQ[i];
			endgenerate
				
	assign RstDbnc = RstDbncTemp[RST_DBNC-2] & ~RstDbncQ[RST_DBNC-1];

//////////////////////////////////////////////////////////
// RESET WITH TAKE-OFF AND LANDING
//////////////////////////////////////////////////////////	

	always@(posedge SysConCLK)
		if(RstDbnc || RstQ[RST_SYNC_NUM-1])
		RstQ	<=	{RstQ[RST_SYNC_NUM-2:0],RstQ[RST_SYNC_NUM-1]};
		
	assign DcmRst = ~RstQ[RST_SYNC_NUM-2] || ~RstQ[RST_SYNC_NUM-3] || ~RstQ[RST_SYNC_NUM-4] || Start_Up_Rst;
	assign intRst = ~DcmLckd;
	
	always@(posedge SysConCLK)	
		if(intRst)
		RstD <= {1'b1,RST_SYNC_NUM[RST_SYNC_NUM_LENGTH-1:0]};	
		else	if(RstD[RST_SYNC_NUM_LENGTH])						
				RstD 	<=	RstD - 1;													
		
	assign ASYNC_RST = RstQ[RST_SYNC_NUM-1] || RstD[RST_SYNC_NUM_LENGTH];
	
//////////////////////////////////////////////////////////
// SYNCHRONIZE ASYNC SWITCH INPUTS WITH TFT CLOCK
//////////////////////////////////////////////////////////	

	InputSyncV #(
					.WIDTH			(4)
					) 
					sync_sw
					(
					.CLK_I			(int_TFTClk),
					.D_I				(SW_I[3:0]),
					.D_O				(MSEL_O)
					);
	
endmodule

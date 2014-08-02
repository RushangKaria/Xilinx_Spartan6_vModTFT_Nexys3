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
// Module: TftCtl.v
//
//
// Description : TFT display controller.
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

module TftCtl
(
input		wire						CLK_I,
input		wire						CLK_180_I,
input		wire						RST_I,
input		wire	[31:0]			X_I,
input		wire	[31:0]			Y_I,
input		wire	[11:0]			Z_I,
input		wire						WE_I,
input		wire						WR_CLK,
input		wire	[3:0]				MSEL_I,
output	wire	[7:0]				R_O,
output	wire	[7:0]				G_O,
output	wire	[7:0]				B_O,
output	wire						DE_O,
output	wire						CLK_O,
output	wire						DISP_O,
output	wire						BKLT_O,
output	wire						VDDEN_O
);

///////////////////////////////////////////////////////////////////////
// MODULE SPECIFIC PARAMETER DECLARATIONS
///////////////////////////////////////////////////////////////////////

`include"resolutions.v"	//Include the converted library files
//`include"video_rom.v"	//over here. You can make place them 
//`include"touch_panel.v"	//at the head but warnings occur

parameter	integer		CLOCKFREQ				=	9;		//MHz
parameter	integer		TPOWERUP					=	1;		//ms
parameter	integer		TPOWERDOWN				=	1;		//ms
parameter	integer		TLEDWARMUP				=	200;	//ms
parameter	integer		TLEDCOOLDOWN			=	200;	//ms
parameter	integer		TLEDWARMUP_CYCLES		=	CLOCKFREQ	*	TLEDWARMUP		*	1000;
parameter	integer		TLEDCOOLDOWN_CYCLES	=	CLOCKFREQ	*	TLEDCOOLDOWN	*	1000;
parameter 	integer		TPOWERUP_CYCLES		=	CLOCKFREQ	*	TPOWERUP			*	1000;
parameter	integer		TPOWERDOWN_CYCLES		=	CLOCKFREQ	*	TPOWERDOWN		*	1000;

parameter	integer		STATE_OFF				=	0;		//State machine for the 
parameter	integer		STATE_POWER_UP			=	1;		//initialization of the TFT
parameter 	integer		STATE_LED_WARM_UP		=	2;
parameter	integer		STATE_LED_COOL_DOWN	=	3;
parameter	integer		STATE_POWER_DOWN		=	4;
parameter	integer		STATE_ON					=	5;

parameter	integer		FB_COLOR_DEPTH			=	2;

parameter	integer		GROUND					=	0;
parameter	integer		VDD						=	1;

///////////////////////////////////////////////////////////////////////////////////////
// SIGNALS LOCAL TO MODULE
///////////////////////////////////////////////////////////////////////////////////////

reg		[$clog2(TLEDCOOLDOWN_CYCLES)-1:0]			waitCnt;
wire																waitCntEn;

reg		[$clog2(STATE_ON)-1:0]							state;
reg		[$clog2(STATE_ON)-1:0]							next_state;
	
reg		[$clog2(2**28)-1:0]								cntDyn;
wire		[31:0]												VtcHCnt;
wire		[31:0]												VtcVCnt;
wire																VtcRst;
wire																VtcVde;
wire																VtcHs;
wire																VtcVs;
	
wire																int_Bklt;
reg																int_De;
wire																clkStop;
	
wire	[7:0]														int_R;
wire	[7:0]														int_G;
wire	[7:0]														int_B;

reg	[FB_COLOR_DEPTH-1:0]									vram_data;
reg	[FB_COLOR_DEPTH-1:0]									reg_wrdata;
reg	[$clog2(H_480_272p_AV*V_480_272p_AV)-1:0]		vram_addr;
reg	[$clog2(H_480_272p_AV*V_480_272p_AV)-1:0]		vram_wraddr;

reg	[FB_COLOR_DEPTH-1:0]									vram			[H_480_272p_AV*V_480_272p_AV-1:0];
		
reg																vram_we;

//@Deprecated
reg																reg_X;
reg																reg_Y;
reg																reg_WE;

///////////////////////////////////////////////////////////////////////////////////////
// SYNTHESIS SPECIFIC INSTRUCTIONS
///////////////////////////////////////////////////////////////////////////////////////

integer i;

	//synthesis attribute RAM_STYLE of vram is "BLOCK"
	
	initial
		begin
			waitCnt	=	0;
			int_De	=	1'b0;
			state		=	STATE_POWER_DOWN;
		end
		
///////////////////////////////////////////////////////////////////////////////////////
// VIDEO TIMING CONTROLLER	::	MODULE INSTANTIAION
///////////////////////////////////////////////////////////////////////////////////////

/*
* This module provides the video
* timing controls for the TFT.
* This involves the display 
* protocol
*/


	VideoTimingCtl vtc
						(
						.PCLK_I			(CLK_I),
						.RSEL_I			(R480_272P),
						.RST_I			(VtcRst),
						.VDE_O			(VtcVde),
						.HS_O				(VtcHs),
						.VS_O				(VtcVs),
						.HCNT_O			(VtcHCnt),
						.VCNT_O			(VtcVCnt)
						);
	
						
						
	assign VtcRst	=	1'b0;
	
///////////////////////////////////////////////////////////////////////////////////////
// VRAM ADDRESS COUNTER
///////////////////////////////////////////////////////////////////////////////////////

	always@(posedge CLK_I)
		begin
			int_De	<=	VtcVde;
				
				if(VtcRst)
				vram_addr	<=	'b0;
				else if(VtcVde)
							if(vram_addr	==	H_480_272p_AV*V_480_272p_AV-1)
							vram_addr	<=	'b0;
							else
							vram_addr	<=	vram_addr+1;
		end
		
	always@(posedge CLK_I)
		begin
			if(X_I >= 0 && X_I < H_480_272p_AV && Y_I >= 0 && Y_I < V_480_272p_AV)
			vram_we	<=	WE_I;
			else
			vram_we	<=	1'b0;
			
			vram_wraddr	<=	(Y_I)*H_480_272p_AV+X_I;
			
				if(Z_I < 'h200)
				reg_wrdata	<=	2'b11;
				else if(Z_I < 'h300)
				reg_wrdata	<=	2'b10;
				else
				reg_wrdata	<=	2'b01;
		end
	
///////////////////////////////////////////////////////////////////////////////////////
// VRAM REGISTERED OUTPUT
///////////////////////////////////////////////////////////////////////////////////////	

	always@(posedge CLK_I)
	vram_data	<=	vram[vram_addr];
	
	always@(posedge CLK_I)
		if(vram_we)
		vram[vram_wraddr]	=	reg_wrdata;
	
///////////////////////////////////////////////////////////////////////////////////////
//	SCREEN DIVISION INTO RED, GREEN and BLACK THIRDS
///////////////////////////////////////////////////////////////////////////////////////	
	
	assign int_R	=	(VtcHCnt < H_480_272p_AV/3)											?	{vram_data,6'b000000}	:8'h00;
	assign int_G	=	(VtcHCnt >= H_480_272p_AV/3 && VtcHCnt < H_480_272p_AV*2/3)	?	{vram_data,6'b000000}	:8'h00;
	assign int_B	=	(VtcHCnt >= H_480_272p_AV*2/3)										?	{vram_data,6'b000000}	:8'h00;
	
///////////////////////////////////////////////////////////////////////////////////////
//	BACKLIGHT INTENSITY CONTROL :: MODULE INSTANTIATION
///////////////////////////////////////////////////////////////////////////////////////		

/*
* This module controls the intensity of the
* backlight so that the data is visible
* instead of a white screen
*/

	Pulse_Width_Modulation #(
									.C_CLK_I_FREQUENCY	(9),
									.C_PWM_FREQUENCY		(25000),
									.C_PWM_RESOLUTION		(3)
									)
									pwm
									(
									.CLK_I					(CLK_I),
									.RST_I					(1'b0),
									.DUTY_FACTOR_I			(MSEL_I[2:0]),
									.PWM_O					(int_Bklt)
									);
	
	
///////////////////////////////////////////////////////////////////////////////////////
//	LCD POWER SEQUENCE
///////////////////////////////////////////////////////////////////////////////////////	

	assign BKLT_O	=	(state == STATE_ON)											?	int_Bklt	:1'b0;
	assign VDDEN_O	=	(state == STATE_OFF || state == STATE_POWER_DOWN)	?	1'b0		:1'b1;
	
	assign DISP_O	=	(state == STATE_OFF || state == STATE_POWER_DOWN || state == STATE_POWER_UP)	?	1'b0	:1'b1;
	assign DE_O		=	(state == STATE_OFF || state == STATE_POWER_DOWN || state == STATE_POWER_UP)	?	'b0	:int_De;
	
	assign R_O		=	(state == STATE_OFF || state == STATE_POWER_DOWN || state == STATE_POWER_UP)	?	'b0	:int_R;
	assign G_O		=	(state == STATE_OFF || state == STATE_POWER_DOWN || state == STATE_POWER_UP)	?	'b0	:int_G;
	assign B_O		=	(state == STATE_OFF || state == STATE_POWER_DOWN || state == STATE_POWER_UP)	?	'b0	:int_B;
	
	assign clkStop	=	(state == STATE_OFF || state == STATE_POWER_DOWN || state == STATE_POWER_UP)	?	1'b1	:1'b0;
	
	
	assign waitCntEn = 	((state == STATE_POWER_UP || state == STATE_LED_WARM_UP || 
								 state == STATE_LED_COOL_DOWN || state == STATE_POWER_DOWN)&&(state==next_state))?	1'b1	:1'b0;
								 
		always@(posedge CLK_I)
		state	<=	next_state;
		
		always@*
			case(state)
				STATE_OFF				:	next_state	=	(MSEL_I[3] && ~RST_I)				? STATE_POWER_UP			:STATE_OFF;
				STATE_POWER_UP			:	next_state	=	(waitCnt == TPOWERUP_CYCLES)		? STATE_LED_WARM_UP		:STATE_POWER_UP;
				STATE_LED_WARM_UP		:	next_state	=	(waitCnt == TLEDWARMUP_CYCLES)	? STATE_ON					:STATE_LED_WARM_UP;
				STATE_ON					:	next_state	=	(~MSEL_I[3] && RST_I)				? STATE_LED_COOL_DOWN	:STATE_ON;
				STATE_LED_COOL_DOWN	:	next_state	=	(waitCnt == TLEDCOOLDOWN_CYCLES)	? STATE_POWER_DOWN		:STATE_LED_COOL_DOWN;
				STATE_POWER_DOWN		:	next_state	=	(waitCnt == TPOWERDOWN_CYCLES)	? STATE_OFF					:STATE_POWER_DOWN;
			
				default					:	next_state	=	STATE_OFF;
			endcase

///////////////////////////////////////////////////////////////////////////////////////
//	WAIT COUNTER
///////////////////////////////////////////////////////////////////////////////////////	

	always@(posedge CLK_I)
		if(waitCntEn==0)
		waitCnt	<=	0;
		else
		waitCnt	<=	waitCnt+1;
		
///////////////////////////////////////////////////////////////////////////////////////
//	CLOCK FORWARDING DONE RIGHT
///////////////////////////////////////////////////////////////////////////////////////			

	ODDR2		#(
					.DDR_ALIGNMENT			("NONE"),			//Set output alignment to "NONE", "C0", "C1"
					.INIT						(1'b0),				//Set initial Q to 0
					.SRTYPE					("SYNC")				//Synchronous reset
				)
				Inst_ODDR2_MCLK_FORWARD 
				(
					.Q							(CLK_O),				//Output data
					.C0						(CLK_I),				//Input clock
					.C1						(CLK_180_I),
					.CE						(1'b1),				//Clock enable
					.D0						(1'b1),				//Data associated with C0
					.D1						(1'b0),				//Data associated with C1
					.R							(clkStop),			//Clock reset
					.S							(1'b0)				//Set input
				);

endmodule

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
// Module: Touch_Controller.v
//
// Description : Touch Controller to calculate X,Y and Pressure values
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

module Touch_Controller #(parameter CLOCKFREQ	=	100)
(
input		wire							CLK_I,
input		wire							RST_I,
input		wire							PENIRQ_I,
input		wire							DOUT_I,
input		wire							BUSY_I,
output	wire		[11:0]			X_O,
output	wire		[11:0]			Y_O,
output	wire		[11:0]			Z_O,
output	wire							CS_O,
output	wire							DIN_O,
output	wire							DCLK_O
);

///////////////////////////////////////////////////////////////////////
// MODULE SPECIFIC PARAMETER DECLARATIONS
///////////////////////////////////////////////////////////////////////

	parameter	integer		TCH_CL						=	250;
	parameter	integer		TSETTLE						=	10000;
	parameter	integer		DCLK_CYCLES					=	(CLOCKFREQ*TCH_CL)/(1000);
	parameter	integer		SETTLE_CYCLES				=	(CLOCKFREQ*TSETTLE)/(1000);
	parameter	integer		BITS_PER_CONVERSION		=	12;
	parameter	integer		CLOCKS_PER_CONVERSION	=	15;
	parameter 	integer		ACQ_FROM_BIT				=	5;
	parameter	integer		AVERAGE_FACTOR				=	3;
	
	parameter					ADS_START					=	1'b1;
	parameter					ADS_AX						=	3'b101;
	parameter					ADS_AY						=	3'b001;
	parameter					ADS_AZ1						=	3'b011;
	parameter					ADS_12BIT					=	1'b0;
	parameter					ADS_DIF						=	1'b0;
	parameter					ADS_NOPD						=	2'b11;
	parameter					ADS_PD						=	2'b00;
	
	parameter	integer		STATE_IDLE					=	0;
	parameter	integer		STATE_CMD_LOAD				=	1;
	parameter	integer		STATE_CMD					=	2;
	parameter	integer		STATE_BUSY					=	3;
	parameter	integer		STATE_ACQ_DELAY			=	4;
	
	parameter	integer		STATE_SAMPLE				=	0;
	parameter	integer		STATE_WINDOWING			=	1;
	parameter	integer		STATE_X_DIV_Z1				=	2;
	parameter	integer		STATE_NEW_DATA				=	3;
	
	parameter	integer		X_POS							=	0;
	parameter	integer		Y_POS							=	1;
	parameter	integer		Z1_POS						=	2;
	
///////////////////////////////////////////////////////////////////////////////////////
// SIGNALS LOCAL TO MODULE
///////////////////////////////////////////////////////////////////////////////////////
	
	reg		[2:0]														controller_state;
	reg		[2:0]														controller_next_state;
		
	reg		[1:0]														sample_state;
	reg		[1:0]														sample_next_state;
	
	reg		[1:0]														measure_state;
	reg		[1:0]														previous_measure_state;
	
	reg		[2:0]														ads_A;
	wire		[7:0]														ads_cmd;
	
	reg		[BITS_PER_CONVERSION-1+AVERAGE_FACTOR+1:0]	avgAcc;
	wire		[BITS_PER_CONVERSION-1+AVERAGE_FACTOR+1:0]	wAvg1;
	wire		[BITS_PER_CONVERSION-1+AVERAGE_FACTOR+1:0]	wAvg;
	
	reg		[BITS_PER_CONVERSION-1:0]							sampleMin;
	reg		[BITS_PER_CONVERSION-1:0]							sampleMax;
	
	wire																	avgCntEn;
	reg																	avgCntRst;
	
	reg		[4:0]														sampleCnt;
	reg																	sampleCntEn;
	reg																	sampleCntRst;
	
	reg		[BITS_PER_CONVERSION-1:0]							int_X;
	reg		[BITS_PER_CONVERSION-1:0]							int_Y;
	reg		[BITS_PER_CONVERSION-1:0]							int_Z;
	
	reg		[BITS_PER_CONVERSION-1:0]							fX_Z1;
	reg		[BITS_PER_CONVERSION:0]								qX_Z1;	

	wire																	rfd;
	wire																	rdyX_Z1;
	reg																	ndX_Z1;
	
	wire		[BITS_PER_CONVERSION*2-1:0]						X_Z1_4096;
	reg		[BITS_PER_CONVERSION*2-1:0]						RTouch_4;
	reg		[BITS_PER_CONVERSION*2-1:0]						RTouch;
	
	wire		[((BITS_PER_CONVERSION*2+1)/8+1)*8-1:0]		m_axis_dout_tdata;
	
	reg		[$clog2(DCLK_CYCLES)-1:0]							clkCnt;
	reg																	clkCntEn;
	reg																	int_DCLK;
	reg																	int_CS;
	reg																	dclkREdge;
	reg																	dclkFEdge;
	
	reg	[$clog2(CLOCKS_PER_CONVERSION)-1:0]					bitCnt;
	wire																	bitCntEn;
	wire																	bitCntRst;
	
	reg	[$clog2(SETTLE_CYCLES)-1:0]							settleCnt;
	reg																	settleCntEn;
	reg																	settleCntRst;
	
	reg	[BITS_PER_CONVERSION-1:0]								srDataIn;
	reg	[7:0]															srDataOut;
	reg																	shiftOutLd;

///////////////////////////////////////////////////////////////////////////////////////
// SYNTHESIS SPECIFIC INSTRUCTIONS
///////////////////////////////////////////////////////////////////////////////////////

	initial
		begin
			controller_state			=	STATE_IDLE;
			measure_state				=	X_POS;
			previous_measure_state 	= X_POS;
			sample_state				=	STATE_SAMPLE;
			
			sampleMin					=	12'hFFF;
			sampleMax					=	12'h000;
			sampleCnt					=	2**AVERAGE_FACTOR+2-1;
			int_DCLK						=	1'b0;
			int_CS						=	1'b0;
			dclkREdge 					=	1'b0;
			dclkFEdge					=	1'b0;
			clkCntEn						=	1'b0;
		end
	
///////////////////////////////////////////////////////////////////////////////////////
// INPUT | OUTPUT SHIFT REGISTERS
///////////////////////////////////////////////////////////////////////////////////////

	always@(posedge CLK_I)
		begin
			if(dclkREdge)
			srDataIn	<=	{srDataIn[BITS_PER_CONVERSION-2:0],DOUT_I};
			
			if(shiftOutLd)
			srDataOut	<=	ads_cmd;
			else if(dclkFEdge)
					srDataOut	<=	{srDataOut[6:0],1'b0};
		end
	
	assign	DIN_O		=	srDataOut[7];
	assign	DCLK_O	=	int_DCLK;
	assign	CS_O		=	int_CS;
	assign	X_O		=	int_X;
	assign	Y_O		=	int_Y;
	assign	Z_O		=	int_Z;
	

			always@(measure_state)
				case(measure_state)
					X_POS		:	ads_A	=	ADS_AX;
					Y_POS		:	ads_A	=	ADS_AY;
					Z1_POS	:	ads_A	=	ADS_AZ1;
				endcase
				
	assign	ads_cmd	=	{ADS_START,ads_A,ADS_12BIT,ADS_DIF,ADS_NOPD};
	
///////////////////////////////////////////////////////////////////////////////////////
// CLOCK DIVIDER
///////////////////////////////////////////////////////////////////////////////////////	
	
	always@(posedge CLK_I)
		if(clkCntEn)
			if(clkCnt == 0)
				begin
					clkCnt	<=	DCLK_CYCLES - 1;
					int_DCLK	<=	~int_DCLK;
				end
			else
			clkCnt	<=	clkCnt - 1;
			
	always@*
		if(clkCnt)
			 begin
			 dclkREdge = 1'b0;
			 dclkFEdge = 1'b0;
			 end
		else
			begin
				dclkREdge = ~int_DCLK;
				dclkFEdge =  int_DCLK;
			end
	

	
///////////////////////////////////////////////////////////////////////////////////////
//	BIT COUNTER
///////////////////////////////////////////////////////////////////////////////////////	
	
	always@(posedge CLK_I)
		if(bitCntRst)
		bitCnt	<=	'b0;
		else if(dclkFEdge)
					if(bitCnt == CLOCKS_PER_CONVERSION-1)
					bitCnt	<=	'b0;
					else
					bitCnt	<=	bitCnt+1;
	
///////////////////////////////////////////////////////////////////////////////////////
//	SETTLE TIME COUNTER -- to delay acquistion and allow the voltage to stabilize
///////////////////////////////////////////////////////////////////////////////////////	
	
	always@(posedge CLK_I)
		if(settleCntRst)
		settleCnt	<=	SETTLE_CYCLES - 1;
		else if(settleCntEn && settleCnt != 'b0)
		settleCnt	<=	settleCnt - 1;

///////////////////////////////////////////////////////////////////////////////////////
//	SAMPLE COUNTER -- for filtering
///////////////////////////////////////////////////////////////////////////////////////	

	always@(posedge CLK_I)
		if(sampleCntRst)
		sampleCnt	<=	2**AVERAGE_FACTOR + 2 - 1;
		else if(sampleCntEn)
				sampleCnt	<=	sampleCnt - 1;

///////////////////////////////////////////////////////////////////////////////////////
//	MEASUREMENT TYPE
///////////////////////////////////////////////////////////////////////////////////////	

	always@(posedge CLK_I)
		if(dclkFEdge && bitCnt == 8)
			begin
				previous_measure_state	<=	measure_state;
				
					if(sampleCnt == 'b0)
						case(measure_state)
							X_POS		:	measure_state	<=	Y_POS;
							Y_POS		:	measure_state	<=	Z1_POS;
							Z1_POS	:	measure_state	<=	X_POS;
							default	:	measure_state	<=	X_POS;
						endcase
					
			end

///////////////////////////////////////////////////////////////////////////////////////
//	ACCUMULATOR	--	for averaging the converted co-ordinates
///////////////////////////////////////////////////////////////////////////////////////

	always@(posedge CLK_I)
		if(avgCntRst)
			begin
				avgAcc		<=	'b0;
				sampleMin	<=	'hFFF;
				sampleMax	<=	'h000;
			end
		else if(avgCntEn)
				begin
					avgAcc	<=	avgAcc + srDataIn;
					
						if(srDataIn < sampleMin)
						sampleMin	<=	srDataIn;
						
						if(srDataIn	> sampleMax)
						sampleMax	<=	srDataIn;
				end
														//Check this logic
	assign	avgCntEn	=	sampleCntEn;
	assign	wAvg1		=	avgAcc-{{(BITS_PER_CONVERSION+AVERAGE_FACTOR+1){1'b0}},sampleMin};
	assign 	wAvg		=	wAvg1-{{(BITS_PER_CONVERSION+AVERAGE_FACTOR+1){1'b0}},sampleMax};
			
			
///////////////////////////////////////////////////////////////////////////////////////
// X/Z1 DIVIDER	::	CORE INSTANTIATION
//						::	A high radix divider with a 12 bit fractional part. The result
//						::	is actually scaled to 4096 by concatenating the quotient
//						::	with the fractional.
///////////////////////////////////////////////////////////////////////////////////////		

	div Inst_X_div_Z1
						(
							.aclk									(CLK_I),
							.s_axis_divisor_tvalid			(ndX_Z1),
							.s_axis_divisor_tready			(),
							.s_axis_divisor_tdata			({4'b0000,wAvg[BITS_PER_CONVERSION-1+AVERAGE_FACTOR:AVERAGE_FACTOR]}),
							.s_axis_dividend_tvalid			(ndX_Z1),
							.s_axis_dividend_tready			(rfd),
							.s_axis_dividend_tdata			({4'b0000,int_X}),
							.m_axis_dout_tvalid				(rdyX_Z1),
							.m_axis_dout_tdata				(m_axis_dout_tdata)
						);
			
			
	assign	X_Z1_4096	=	m_axis_dout_tdata[BITS_PER_CONVERSION*2-1:0];

		always@(posedge CLK_I)
			RTouch_4	<=	X_Z1_4096 - int_X + int_Y[BITS_PER_CONVERSION-1:2] - 'd1024;
			
///////////////////////////////////////////////////////////////////////////////////////
//	CO-ORDINATE BUFFERS
///////////////////////////////////////////////////////////////////////////////////////			
			
	always@(posedge CLK_I)
		if(sample_state == STATE_NEW_DATA)
			begin
				case(previous_measure_state)
					X_POS		:	int_X	<=	wAvg[BITS_PER_CONVERSION-1+AVERAGE_FACTOR:AVERAGE_FACTOR];
					Y_POS		:	int_Y	<=	wAvg[BITS_PER_CONVERSION-1+AVERAGE_FACTOR:AVERAGE_FACTOR];
					
					Z1_POS	:	if(RTouch_4[BITS_PER_CONVERSION*2-1:BITS_PER_CONVERSION-1+3]!=0)
									int_Z	<=	{BITS_PER_CONVERSION{1'b1}};	
									else
									int_Z	<=	RTouch_4[BITS_PER_CONVERSION-1+2:2];
				endcase
			end
			
///////////////////////////////////////////////////////////////////////////////////////
//	ACQUIRE STATE MACHINE
///////////////////////////////////////////////////////////////////////////////////////	

//assign LED_O = (controller_state == STATE_ACQ_DELAY)?8'b11111111:0;

	always@(posedge CLK_I)
		if(RST_I)
		controller_state	<=	STATE_IDLE;
		else
		controller_state	<=	controller_next_state;
		
	always@*	
		begin																				
			clkCntEn			=	(controller_state == STATE_CMD ||controller_state == STATE_BUSY || controller_state == STATE_CMD_LOAD);
			
			settleCntEn		=	(controller_state	==	STATE_ACQ_DELAY);
			
			settleCntRst	=	(dclkFEdge && bitCnt == 8 && sampleCnt == 0);
			
			shiftOutLd		=	(controller_state == STATE_CMD_LOAD);
			
			int_CS			=	(controller_state == STATE_IDLE);
			
				if(dclkFEdge && bitCnt == ACQ_FROM_BIT)
					begin
						sampleCntEn	=	1'b1;
						
							if(sampleCnt == 0)
							sampleCntRst	=	1'b1;
							else
							sampleCntRst 	= 	1'b0;
					end
				else
					begin
						sampleCntEn 	=	1'b0;
						sampleCntRst 	=	1'b0;
					end
					
		end
		
	always@*
		case(controller_state)
			STATE_IDLE			:	controller_next_state	=	STATE_CMD_LOAD;
			STATE_CMD_LOAD		:	controller_next_state	=	STATE_CMD;
			
			STATE_CMD			:	if(dclkFEdge)
											if(bitCnt == ACQ_FROM_BIT && SETTLE_CYCLES > 0 && settleCnt != 0)
											controller_next_state	=	STATE_ACQ_DELAY;
											else if(bitCnt == 7)
											controller_next_state	=	STATE_BUSY;
											else if(bitCnt == CLOCKS_PER_CONVERSION-1)
											controller_next_state	=	STATE_CMD_LOAD;
										else
										controller_next_state	=	STATE_CMD;
										
			STATE_ACQ_DELAY	:	controller_next_state	=	(settleCnt == 0)	? STATE_CMD	:STATE_ACQ_DELAY;
			STATE_BUSY			:	controller_next_state	=	(dclkFEdge)			? STATE_CMD	:STATE_BUSY;
			
			default				:	controller_next_state	=	STATE_IDLE;
		endcase
	
///////////////////////////////////////////////////////////////////////////////////////
//	FILTERING AND TOUCH CALCULATION FSM
///////////////////////////////////////////////////////////////////////////////////////		
	
	always@(posedge CLK_I)
		if(RST_I)
		sample_state	<=	STATE_SAMPLE;
		else
		sample_state	<=	sample_next_state;
		
	
	always@*
		begin
			avgCntRst	=	(sample_state == STATE_NEW_DATA);
			
			ndX_Z1		=	(sample_state == STATE_WINDOWING);
		end
		
	always@*
		case(sample_state)
			STATE_SAMPLE		:	sample_next_state	=	(sampleCntRst == 1)						?	STATE_WINDOWING	:STATE_SAMPLE;
			STATE_WINDOWING	:	sample_next_state	=	(previous_measure_state == Z1_POS)	?	STATE_X_DIV_Z1		:STATE_NEW_DATA;
			STATE_X_DIV_Z1		:	sample_next_state	=	(rdyX_Z1)									?	STATE_NEW_DATA		:STATE_X_DIV_Z1;
			STATE_NEW_DATA		:	sample_next_state	=	STATE_SAMPLE;
		endcase
	
		
endmodule

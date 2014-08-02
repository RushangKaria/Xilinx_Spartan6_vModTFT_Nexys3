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
// Module: VideoTimingCtl.v
//
//
// Description : This module is used to provide timing signals based on the resolution
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

module VideoTimingCtl
(
input		wire										PCLK_I,
input		wire										RST_I,
input		wire		[RESOLUTION_WIDTH-1:0]	RSEL_I,
output	wire										VDE_O,
output	wire										HS_O,
output	wire										VS_O,
output	wire		[31:0]						HCNT_O,
output	wire		[31:0]						VCNT_O

);

///////////////////////////////////////////////////////////////////////
// MODULE SPECIFIC PARAMETER DECLARATIONS
///////////////////////////////////////////////////////////////////////

`include"resolutions.v"	

///////////////////////////////////////////////////////////////////////
// VGA TIMING SIGNALS
///////////////////////////////////////////////////////////////////////
	
	reg		[31:0]						HCnt;
	reg		[31:0]						VCnt;
	
	reg		[31:0]						H_AV;
	reg		[31:0]						V_AV;
	reg		[31:0]						H_AV_FP;
	reg		[31:0]						V_AV_FP;
	reg		[31:0]						H_AV_FP_S;
	reg		[31:0]						V_AV_FP_S;
	reg		[31:0]						H_AV_FP_S_BP;
	reg		[31:0]						V_AV_FP_S_BP;
	
	reg										hs;
	reg										vs;
	reg										vde;
	reg										H_POL;
	reg										V_POL;
	wire										SRst;
	
///////////////////////////////////////////////////////////////////////////////////////
// SYNTHESIS SPECIFIC INSTRUCTIONS
///////////////////////////////////////////////////////////////////////////////////////
		
		initial
			begin
				HCnt	=	'b0;
				VCnt	=	'b0;
			end
	
///////////////////////////////////////////////////////////////////////
// RESOLUTION SELECTOR 	:: Used to select parameters based on the 
//								:: selected resolution. This enables the 
//								:: resolution to be changed on the fly
///////////////////////////////////////////////////////////////////////

	always@(RSEL_I)
		case(RSEL_I)
			R640_480P	:	H_AV	=	H_640_480p_AV;
			R720_480P	:	H_AV	=	H_720_480p_AV;
			R480_272P	:	H_AV	=	H_480_272p_AV;
			R1280_720P	:	H_AV	=	H_1280_720p_AV;
			R1600_900P	:	H_AV	=	H_1600_900p_AV;
			R800_600P	:	H_AV	=	H_800_600p_AV;
		endcase
		
	always@(RSEL_I)
		case(RSEL_I)
			R640_480P	:	V_AV	=	V_640_480p_AV;
			R720_480P	:	V_AV	=	V_720_480p_AV;
			R480_272P	:	V_AV	=	V_480_272p_AV;
			R1280_720P	:	V_AV	=	V_1280_720p_AV;
			R1600_900P	:	V_AV	=	V_1600_900p_AV;
			R800_600P	:	V_AV	=	V_800_600p_AV;
		endcase
		
	always@(RSEL_I)
		case(RSEL_I)
			R640_480P	:	H_AV_FP	=	H_640_480p_AV_FP;
			R720_480P	:	H_AV_FP	=	H_720_480p_AV_FP;
			R480_272P	:	H_AV_FP	=	H_480_272p_AV_FP;
			R1280_720P	:	H_AV_FP	=	H_1280_720p_AV_FP;
			R1600_900P	:	H_AV_FP	=	H_1600_900p_AV_FP;
			R800_600P	:	H_AV_FP	=	H_800_600p_AV_FP;
		endcase

	always@(RSEL_I)
		case(RSEL_I)
			R640_480P	:	V_AV_FP	=	V_640_480p_AV_FP;
			R720_480P	:	V_AV_FP	=	V_720_480p_AV_FP;
			R480_272P	:	V_AV_FP	=	V_480_272p_AV_FP;
			R1280_720P	:	V_AV_FP	=	V_1280_720p_AV_FP;
			R1600_900P	:	V_AV_FP	=	V_1600_900p_AV_FP;
			R800_600P	:	V_AV_FP	=	V_800_600p_AV_FP;
		endcase
		
	always@(RSEL_I)
		case(RSEL_I)
			R640_480P	:	H_AV_FP_S	=	H_640_480p_AV_FP_S;
			R720_480P	:	H_AV_FP_S	=	H_720_480p_AV_FP_S;
			R480_272P	:	H_AV_FP_S	=	H_480_272p_AV_FP_S;
			R1280_720P	:	H_AV_FP_S	=	H_1280_720p_AV_FP_S;
			R1600_900P	:	H_AV_FP_S	=	H_1600_900p_AV_FP_S;
			R800_600P	:	H_AV_FP_S	=	H_800_600p_AV_FP_S;
		endcase
		
	always@(RSEL_I)
		case(RSEL_I)
			R640_480P	:	V_AV_FP_S	=	V_640_480p_AV_FP_S;
			R720_480P	:	V_AV_FP_S	=	V_720_480p_AV_FP_S;
			R480_272P	:	V_AV_FP_S	=	V_480_272p_AV_FP_S;
			R1280_720P	:	V_AV_FP_S	=	V_1280_720p_AV_FP_S;
			R1600_900P	:	V_AV_FP_S	=	V_1600_900p_AV_FP_S;
			R800_600P	:	V_AV_FP_S	=	V_800_600p_AV_FP_S;
		endcase
		
	always@(RSEL_I)
		case(RSEL_I)
			R640_480P	:	H_AV_FP_S_BP	=	H_640_480p_AV_FP_S_BP;
			R720_480P	:	H_AV_FP_S_BP	=	H_720_480p_AV_FP_S_BP;
			R480_272P	:	H_AV_FP_S_BP	=	H_480_272p_AV_FP_S_BP;
			R1280_720P	:	H_AV_FP_S_BP	=	H_1280_720p_AV_FP_S_BP;
			R1600_900P	:	H_AV_FP_S_BP	=	H_1600_900p_AV_FP_S_BP;
			R800_600P	:	H_AV_FP_S_BP	=	H_800_600p_AV_FP_S_BP;
		endcase
		
	always@(RSEL_I)
		case(RSEL_I)
			R640_480P	:	V_AV_FP_S_BP	=	V_640_480p_AV_FP_S_BP;
			R720_480P	:	V_AV_FP_S_BP	=	V_720_480p_AV_FP_S_BP;
			R480_272P	:	V_AV_FP_S_BP	=	V_480_272p_AV_FP_S_BP;
			R1280_720P	:	V_AV_FP_S_BP	=	V_1280_720p_AV_FP_S_BP;
			R1600_900P	:	V_AV_FP_S_BP	=	V_1600_900p_AV_FP_S_BP;
			R800_600P	:	V_AV_FP_S_BP	=	V_800_600p_AV_FP_S_BP;
		endcase
		
	always@(RSEL_I)
		case(RSEL_I)
			R640_480P	:	H_POL	=	H_640_480p_POL;
			R720_480P	:	H_POL	=	H_720_480p_POL;
			R480_272P	:	H_POL	=	H_480_272p_POL;
			R1280_720P	:	H_POL	=	H_1280_720p_POL;
			R1600_900P	:	H_POL	=	H_1600_900p_POL;
			R800_600P	:	H_POL	=	H_800_600p_POL;
		endcase
		
	always@(RSEL_I)
		case(RSEL_I)
			R640_480P	:	V_POL	=	V_640_480p_POL;
			R720_480P	:	V_POL	=	V_720_480p_POL;
			R480_272P	:	V_POL	=	V_480_272p_POL;
			R1280_720P	:	V_POL	=	V_1280_720p_POL;
			R1600_900P	:	V_POL	=	V_1600_900p_POL;
			R800_600P	:	V_POL	=	V_800_600p_POL;
		endcase
		
///////////////////////////////////////////////////////////////////////
// LOCAL RESET	
///////////////////////////////////////////////////////////////////////

/*
* This module is used to provide
* an initial reset when the TFT
* is reset
*/

	Local_Reset #(
					.RESET_PERIOD	(4)
					)
					local_reset
					(
					.CLK_I			(PCLK_I),
					.RST_I			(RST_I),
					.SRST_O			(SRst)
					);
		
///////////////////////////////////////////////////////////////////////
// VIDEO TIMING COUNTER :: To generate timings signals as per spec
///////////////////////////////////////////////////////////////////////

	always@(posedge PCLK_I)
	begin
	//{
		if(SRst)
		//{
			begin
				HCnt	<=	H_AV_FP_S_BP-1;
				VCnt	<=	V_AV_FP_S_BP-1;
				vde	<=	1'b0;
				hs		<=	1'b1;
				vs		<=	1'b1;
			end
		//}
		else
		//{
			begin
				if(HCnt	==	H_AV_FP_S_BP-1)
				//{
					begin
						HCnt	<=	'b0;
						
						if(VCnt	==	V_AV_FP_S_BP-1)
						VCnt	<=	'b0;
						else
						VCnt	<=	VCnt+1;
					end
				//}
				else
				HCnt	<=	HCnt+1;
		
				if(HCnt	>=	H_AV_FP-1 && HCnt	<	H_AV_FP_S-1)
				//{
					begin
						hs	<=	1'b0;
							if(VCnt	>=	V_AV_FP && VCnt	<	V_AV_FP_S)
							vs	<=	1'b0;
							else
							vs	<=	1'b1;
					end
				//}
				else
				hs	<=	1'b1;
		
				if
				(
					(HCnt	==	H_AV_FP_S_BP-1 && (VCnt == V_AV_FP_S_BP-1 || VCnt < V_AV-1))
													||
								(HCnt	<	H_AV-1 && VCnt	<	V_AV)
				)
				vde	<=	1'b1;
				else
				vde	<=	1'b0;
		//}
		end
	//}	
	end

assign	HCNT_O	=	HCnt;
assign	VCNT_O	=	VCnt;
assign	VDE_O		=	vde;

assign	HS_O		=	(H_POL) ?	~hs	:hs;
assign	VS_O		=	(V_POL) ?	~vs	:vs;

						
endmodule

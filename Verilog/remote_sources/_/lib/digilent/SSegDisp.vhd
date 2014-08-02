----------------------------------------------------------------------------------
-- Company: Digilent Ro
-- Engineer: Elod Gyorgy
-- 
-- Create Date:    14:55:31 04/22/2011 
-- Design Name: 
-- Module Name:    SSegDisp 
-- Project Name:	 7-segment Display Controller 
-- Target Devices: 
-- Tool versions: 
-- Description: This module is able to drive a common-cathode multi-digit
-- 7-segment display.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.math_real.all;

entity SSegDisp is
    generic (
		  CLOCKFREQ : natural := 100; -- in MHz
        DIGITS : natural := 4
        );
    port (
        CLK_I: in std_logic;
        DATA_I: in std_logic_vector(DIGITS*4-1 downto 0);
        DOTS_I: in std_logic_vector(DIGITS-1 downto 0);
        AN_O: out std_logic_vector(DIGITS-1 downto 0);
        CA_O: out std_logic_vector(7 downto 0)
        );
end SSegDisp;

architecture Behavioral of SSegDisp is
	constant DISP_FREQ : natural := 20 * DIGITS; --in kHz
	constant DISP_FREQ_CYCLES : natural := 
		natural(ceil(real(CLOCKFREQ*1_000/DISP_FREQ)));
		
	signal refreshCnt : natural range 0 to DISP_FREQ_CYCLES-1 := 0;
	
	signal DisplayCLK: std_logic;
	signal DigitNo: natural range 0 to DIGITS-1 := 0;
	signal Digit: std_logic_vector(3 downto 0);
	signal HexDigit: std_logic_vector(6 downto 0);
	signal Dot: std_logic;

begin

with Digit select
	HexDigit <= "1000000" when "0000",	 --0
					"1111001" when "0001",   --1
            	"0100100" when "0010",   --2
            	"0110000" when "0011",   --3
            	"0011001" when "0100",   --4
            	"0010010" when "0101",   --5
            	"0000010" when "0110",   --6
            	"1111000" when "0111",   --7
            	"0000000" when "1000",   --8
            	"0010000" when "1001",   --9
            	"0001000" when "1010",   --A
            	"0000011" when "1011",   --b
            	"1000110" when "1100",   --C
            	"0100001" when "1101",   --d
            	"0000110" when "1110",   --E
            	"0001110" when "1111",   --F
            	"0001001" when others;   --H ???

Digit <= DATA_I(DigitNo*4+3 downto DigitNo*4);
-- Let's use Dots as active high and not confuse the user
Dot <= not DOTS_I(DigitNo);
CA_O <= Dot & HexDigit;

DIV_CLK_EN: process(CLK_I)
begin
	if Rising_Edge(CLK_I) then
		if (refreshCnt = DISP_FREQ_CYCLES-1) then
			refreshCnt <= 0;
		else
			refreshCnt <= refreshCnt + 1;
		end if;
	end if;
end process;

CycleDIGITS: process(CLK_I)
begin
	if Rising_Edge(CLK_I) then
		if (refreshCnt = DISP_FREQ_CYCLES-1) then
			if (DigitNo+1 = DIGITS) then 
				DigitNo <= 0;
			else
				DigitNo <= DigitNo+1;
			end if;
		end if;
	end if;
end process CycleDIGITS;

SetAnodes: process(DigitNo)
begin
	AN_O <= (others => '1');
	AN_O(DigitNo) <= '0';
end process SetAnodes;

end Behavioral;

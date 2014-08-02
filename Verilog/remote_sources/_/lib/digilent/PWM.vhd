----------------------------------------------------------------------------------
-- Company: Digilent Ro
-- Engineer: Elod Gyorgy
-- 
-- Create Date:    19:44:54 04/12/2011 
-- Design Name: 
-- Module Name:    PWM - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Pulse-Width Modulator with center-aligned pulses, variable
-- PWM frequency and resolution.
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
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PWM is
	Generic (
		C_CLK_I_FREQUENCY : natural := 50; -- in MHZ
		C_PWM_FREQUENCY : natural := 20000; -- in Hz
		C_PWM_RESOLUTION : natural := 8
	);
   Port (
		CLK_I : in STD_LOGIC;
		RST_I : in STD_LOGIC;
      PWM_O : out STD_LOGIC;
      DUTY_FACTOR_I : in STD_LOGIC_VECTOR (C_PWM_RESOLUTION-1 downto 0)
	);
end PWM;

architecture Behavioral of PWM is
constant C_CLOCK_DIVIDER : natural := C_CLK_I_FREQUENCY*1_000_000/C_PWM_FREQUENCY/2/2**C_PWM_RESOLUTION;

signal PWMCnt : STD_LOGIC_VECTOR (C_PWM_RESOLUTION-1 downto 0) := (others => '0');
signal PWMCntEn, int_PWM : std_logic;
begin

----------------------------------------------------------------------------------
-- Pre-scaler
----------------------------------------------------------------------------------
process (CLK_I) 
variable PSCnt : natural range 0 to C_CLOCK_DIVIDER := 0;
begin
   if CLK_I='1' and CLK_I'event then
		if (PSCnt = C_CLOCK_DIVIDER) then
			PSCnt := 0;
			PWMCntEn <= '1'; --enable pulse for PWM counter
		else
			PSCnt := PSCnt + 1;
			PWMCntEn <= '0';
		end if;
   end if;
end process;
 
----------------------------------------------------------------------------------
-- Up/Down counter for mid-aligned PWM pulse
-- In designs with multiple PWM chanels mid-alignment eliminates simultaneously
-- switching PWM outputs, resulting in less stress on power rails.
----------------------------------------------------------------------------------
process (CLK_I)
variable PWMCntUp : boolean := true;
begin
   if CLK_I='1' and CLK_I'event then
      if (RST_I='1') then 
         PWMCnt <= (others => '0');
      elsif (PWMCntEn='1') then
         if (PWMCntUp) then   
            PWMCnt <= PWMCnt + 1;
         else
            PWMCnt <= PWMCnt - 1;
         end if;
      end if;
		
		if (PWMCnt = 0) then
			PWMCntUp := true;
		elsif (PWMCnt = 2**C_PWM_RESOLUTION-1) then
			PWMCntUp := false;
		end if;
   end if;
end process; 

----------------------------------------------------------------------------------
-- PWM output
----------------------------------------------------------------------------------
process (CLK_I, RST_I)
begin
	if Rising_Edge(CLK_I) then 
		if PWMCnt < DUTY_FACTOR_I then
			int_PWM <= '1';
		else
			int_PWM <= '0';
		end if;
	end if;
end process;

PWM_O <= 'Z' when RST_I = '1' else
			int_PWM;
			
end Behavioral;


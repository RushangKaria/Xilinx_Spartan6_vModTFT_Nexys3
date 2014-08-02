--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.all;

package TouchR is
	type Coordinate is
		record
			X : natural;
			Y : natural;
		end record;
  
	type PanelCharacteristics is
		record
        TopLeft, TopRight, BottomLeft, BottomRight : Coordinate;
        XPlateR, YPlateR : natural;
    end record;

-- Declare constants

	constant VmodTFT : PanelCharacteristics := (
		TopLeft => (X => 150, Y => 300),
		TopRight => (X => 3950, Y => 300),
		BottomLeft => (X => 150, Y => 3800),
		BottomRight => (X => 3950, Y => 3800),
		XPlateR => 900,
		YPlateR => 245
	);

end TouchR;


package body TouchR is
 
end TouchR;

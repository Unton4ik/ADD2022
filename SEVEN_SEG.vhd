library ieee;
use ieee.std_logic_1164.all;

entity SEVEN_SEG is
   port (
      i_Num : in  integer;
      o_Hex : out std_logic_vector(7 downto 0)
   );
end SEVEN_SEG;

architecture rtl of SEVEN_SEG is
begin
   with i_Num select o_Hex <=
      "11000000" when 0,
      "11111001" when 1,
      "10100100" when 2,
      "10110000" when 3,
      "10011001" when 4,
      "10010010" when 5,
      "10000010" when 6,
      "11111000" when 7,
      "10000000" when 8,
      "10010000" when 9,
      "01111111" when others;
end rtl;
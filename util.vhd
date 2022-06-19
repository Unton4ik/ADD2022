library ieee;
use ieee.std_logic_1164.all;

package util is
    function to_std_logic(L: boolean) return std_logic;
end package;

package body util is
    function to_std_logic(L: boolean) return std_logic is
    begin
        if L then 
            return '1';
        else
            return '0';
        end if;
    end function;
end package body;
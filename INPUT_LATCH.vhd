library ieee;
use ieee.std_logic_1164.all;

entity INPUT_LATCH is
    port (
        i_Clock  : in std_logic;
        i_Enable : in std_logic;

        I : in std_logic;
        Q : out std_logic
    );
end entity;

architecture rtl of INPUT_LATCH is
    signal reg : std_logic;
begin
    process is
    begin
        if i_Enable = '0' then
            reg <= '0';
        elsif I = '1' then
            reg <= '1';
        end if;
        wait until rising_edge(i_Clock);
    end process;

    Q <= reg;
end rtl;
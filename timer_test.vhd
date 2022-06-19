library ieee;
use ieee.std_logic_1164.all;

entity timer_test is
    port (
        clk : in std_logic;
        pb0 : in std_logic;
        pb1 : in std_logic;

        sw   : in  std_logic_vector(9 downto 0);
        led  : out std_logic_vector(9 downto 0);
        hex0 : out std_logic_vector(7 downto 0)
        -- hex1 : out std_logic_vector(7 downto 0)
    );
end timer_test;

architecture rtl of timer_test is
    signal timer_dn : std_logic := '0';
    signal num : integer := 0;

    -- signal timer1_dn : std_logic := '0';
    -- signal num1 : integer := 0;
begin
    TMR: entity work.TIMER
    generic map (
        g_CLK_FREQ => 50000000
    )
    port map (
        i_Clock  => clk,
        i_Enable => not pb0,
        i_Reset  => not pb1,
        i_Delay  => 1000,
        o_Tick   => timer_dn
    );

    -- TMR1: entity work.TIMER1
    -- generic map(50000000)
    -- port map(clk, not pb0, not pb1, 1000, timer1_dn);
    
    SS: entity work.SEVEN_SEG
    port map (
        i_Num => num,
        o_Hex => hex0
    );
    -- SS1: entity work.SEVEN_SEG
    -- port map(num1, hex1);

    LATCH0: entity work.INPUT_LATCH
    port map(clk, sw(0), not pb1, led(0));

    num <= (num + 1) mod 10 when rising_edge(timer_dn);
    -- num1 <= (num1 + 1) mod 10 when rising_edge(timer1_dn);

end rtl;
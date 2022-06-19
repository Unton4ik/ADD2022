library ieee;
use ieee.std_logic_1164.all;

entity TIMER is
    generic (
        g_CLK_FREQ : integer := 50000000 -- freq in MHz
    );
    port (
        i_Clock  : in std_logic;
        i_Enable : in std_logic;
        i_Reset  : in std_logic; 
        i_Delay  : in integer;

        o_Tick : out std_logic
    );
end TIMER;

architecture rtl of TIMER is
    -- all time values in nanoseconds
    -- 10^9 / Hz = ns
    constant c_TIME_STEP : integer := 1000000000/g_CLK_FREQ;
    signal ns_counter    : integer := 0;
    signal ms_counter    : integer := 0;

    signal timing   : std_logic;
    signal reg_tick : std_logic;
begin
    process is 
    begin
        if i_Enable = '1' or timing = '1' then
            if i_Enable = '1' then
                timing <= '1';
            end if;

            if i_Reset = '1' then
                ns_counter <= 0;
                ms_counter <= 0;
                o_Tick <= '0';
            else
                if ns_counter >= 1000000 then
                    ms_counter <= ms_counter + 1;
                    ns_counter <= 0;
                else
                    ns_counter <= ns_counter + c_TIME_STEP;
                end if;

                if ms_counter >= i_Delay then
                    ms_counter <= 0;
                    ns_counter <= 0;
                    o_Tick <= '1';
                    timing <= '0';
                else
                    o_Tick <= '0';
                end if;
            end if;
        else
            o_Tick <= '0';
        end if;

        wait until rising_edge(i_Clock);
    end process;
end rtl;

-- architecture rtl of TIMER1 is
--    -- all time values in nanoseconds
--    -- 10^9 / Hz = ns
--    constant c_TIME_STEP : integer := 1000000000/g_CLK_FREQ;
--    signal ns_counter    : integer := 0;
--    signal ms_counter    : integer := 0;

--    signal timing   : std_logic;
--    signal reg_tick : std_logic;
-- begin
--    process is 
--    begin
--       if i_Enable = '1' or timing = '1' then
--          if i_Enable = '1' then
--             timing <= '1';
--          end if;

--          if i_Reset = '1' then
--             ns_counter <= 0;
--             ms_counter <= 0;
--             o_Tick <= '0';
--          else
--             if ns_counter >= 1000000 then
--                ms_counter <= ms_counter + 1;
--                ns_counter <= 0;
--             else
--                ns_counter <= ns_counter + c_TIME_STEP;
--             end if;

--             if ms_counter >= i_Delay then
--                ms_counter <= 0;
--                ns_counter <= 0;
--                o_Tick <= '1';
--                timing <= '0';
--             else
--                o_Tick <= '0';
--             end if;
--          end if;
--       end if;

--       wait until rising_edge(i_Clock);
--    end process;

--    -- process is
--    -- begin
--    --    if i_Enable = '1' or timing = '1' then
--    --       if i_Enable = '1' then
--    --          timing <= '1';
--    --       end if;
--    --       time_counter <= time_counter + c_TIME_STEP;

--    --       if i_Reset = '1' then
--    --          time_counter <= 0;
--    --          o_Tick <= '0';
--    --       else
--    --          -- converts ns to ms
--    --          if time_counter/1000000 >= i_Delay then
--    --             time_counter <= 0;
--    --             o_Tick <= '1';
--    --             timing <= '0';
--    --          else
--    --             o_Tick <= '0';
--    --          end if;
--    --       end if;
--    --    end if;
--    -- wait until rising_edge(i_Clock);
--    -- end process;
-- end rtl;



-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;

-- entity TIMER1 is
--     generic (
--         g_CLK_FREQ : integer := 50000000
--     );
--     port (
--         i_Clock  : in std_logic;
--         i_Enable : in std_logic;
--         i_Reset  : in std_logic; 
--         i_Delay  : in integer;

--         o_Tick : out std_logic
--     );
-- end TIMER1;

-- architecture rtl of TIMER1 is
--     -- all time values in nanoseconds
--     -- 10^9 / Hz = ns
--     constant c_TIME_STEP : integer := 1000000000/g_CLK_FREQ;
--     signal counter  : unsigned(33 downto 0);
--     signal delay_ns : unsigned(33 downto 0);

--     signal timing   : std_logic;
-- begin
--     counter <= counter + 1 when rising_edge(i_Clock);
--     delay_ns <= to_unsigned(i_Delay) * 1000000;


-- end rtl;
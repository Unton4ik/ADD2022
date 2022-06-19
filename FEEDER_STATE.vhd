library ieee;
use ieee.std_logic_1164.all;

use work.all;
use work.typedefs.all;

entity FEEDER_STATE is
    port (
        i_Clock : in std_logic;
        i_Reset : in std_logic := '0';

        i_Feed_Cond  : in std_logic := '0';
        i_Wait_Cond  : in std_logic := '0';
        i_Reset_Cond : in std_logic := '0';
        i_Idle_Cond  : in std_logic := '0';

        o_State : out t_state_feeder
    );
end FEEDER_STATE;

architecture rtl of FEEDER_STATE is
    signal fstate     : t_state_feeder;
    signal reg_fstate : t_state_feeder;
begin
    process (i_Clock, reg_fstate)
    begin
        if (i_Clock = '1' and i_Clock'event) then 
            fstate <= reg_fstate;
        end if;
    end process;

    process (fstate, i_Reset, i_Feed_Cond, i_Wait_Cond,
             i_Reset_Cond, i_Idle_Cond)
    begin
        if (i_Reset = '1') then
            reg_fstate <= FDR_IDLE;
            o_State <= FDR_IDLE;
        else
            o_State <= FDR_IDLE;
            case fstate is
                when FDR_IDLE =>
                    if (i_Feed_Cond = '1') then
                        reg_fstate <= FDR_FEED;
                    else
                        reg_fstate <= FDR_IDLE;
                    end if;
                    o_State <= FDR_IDLE;

                when FDR_FEED =>
                    if (i_Idle_Cond = '1') then
                        reg_fstate <= FDR_IDLE;
                    else
                        reg_fstate <= FDR_FEED;
                    end if;
                    o_State <= FDR_FEED;
                
                -- when FDR_WAIT =>
                --     if (i_Reset_Cond = '1') then
                --         reg_fstate <= FDR_RESET;
                --     else
                --         reg_fstate <= FDR_WAIT;
                --     end if;
                --     o_State <= FDR_WAIT;

                -- when FDR_RESET =>
                --     if (i_Idle_Cond = '1') then
                --         reg_fstate <= FDR_IDLE;
                --     else
                --         reg_fstate <= FDR_RESET;
                --     end if;
                --     o_State <= FDR_RESET;

                when others =>
                    report "Undefined state";
            end case;
        end if;
    end process;
end rtl;
library ieee;
use ieee.std_logic_1164.all;

use work.all;
use work.typedefs.all;

entity SCREW_STATE is
    port (
        i_Clock : in std_logic;
        i_Reset : in std_logic;

        i_Spin_Cond : in std_logic := '0';
        i_Idle_Cond : in std_logic := '0';

        o_State : out t_state_screw
    );
end entity;

architecture rtl of SCREW_STATE is
    signal fstate     : t_state_screw;
    signal reg_fstate : t_state_screw;
begin
    process (i_Clock, reg_fstate)
    begin
        if (i_Clock = '1' and i_Clock'event) then
            fstate <= reg_fstate;
        end if;
    end process;

    process (fstate, i_Reset, i_Spin_Cond, i_Idle_Cond)
    begin
        if (i_Reset = '1') then 
            reg_fstate <= SCR_IDLE;
            o_State <= SCR_IDLE;
        else
            o_State <= SCR_IDLE;
            case fstate is
                when SCR_IDLE =>
                    if (i_Spin_Cond = '1') then
                        reg_fstate <= SCR_SPIN;
                    else
                        reg_fstate <= SCR_IDLE;
                    end if;
                    o_State <= SCR_IDLE;
                
                when SCR_SPIN =>
                    if (i_Idle_Cond = '1') then
                        reg_fstate <= SCR_IDLE;
                    else
                        reg_fstate <= SCR_SPIN;
                    end if;
                    o_State <= SCR_SPIN;

                when others =>
                    report "Undefined state";
            end case;
        end if;
    end process;
end rtl;